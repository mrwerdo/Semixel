//
//  SemanticArtwork.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import Geometry
import SemixelCore

final class SemanticArtwork: Identifiable, ObservableObject {
    let id: String

    @Published
    var root: SemanticIdentifier
    
    @Published
    var image: PixelImage<SemanticPixel>
    
    @Published
    var colorPalette: ColorPalette {
        didSet {
            anyCancellable?.cancel()
            anyCancellable = colorPalette.objectWillChange.sink { [weak self] (_) in
                self?.objectWillChange.send()
            }
        }
    }
    
    private var history: History = History()

    var bitmapImage: PixelImage<RGBA> {
        return PixelImage<RGBA>(size: image.size, buffer: image.buffer.map { colorPalette[rgba: $0.color] })
    }
    
    var anyCancellable: AnyCancellable? = nil
    
    init(id: String, title: String, image: PixelImage<SemanticPixel>, root: SemanticIdentifier, colorPalette: ColorPalette) {
        self.id = id
        self.root = root
        self.image = image
        self.colorPalette = colorPalette
        
        anyCancellable = colorPalette.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    init(createUsing metadata: ArtworkMetadata) {
        self.id = metadata.id
        self.root = SemanticIdentifier(id: -1, name: "Root")
        self.image = PixelImage(width: metadata.size.width,
                                height: metadata.size.height,
                                default: SemanticPixel(semantic: 0, color: 0))
        self.colorPalette = ColorPalette(colors: [0 : .white])
        root.children.append(SemanticIdentifier(id: 0, name: "Default"))
        
        anyCancellable = colorPalette.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        anyCancellable?.cancel()
    }
    
    func undo() {
        if let head = history.head {
            head.operation.undo(&image)
            history.head = head.previous ?? head
        }
    }
    
    func redo() {
        if let next = history.head?.next.last {
            next.operation.redo(&image)
            history.head = next
        }
    }
    
    func transform(selection: SelectedRegion,
                   horizontalFlip: Bool = false,
                   verticalFlip: Bool = false,
                   offset: Point2D = .zero,
                   background: SemanticPixel = .clear) {
        let points = selection.selectedPoints
        let overWrittenPoints = points.compactMap {
            image.isValid($0 + offset) ? image[$0 + offset] : nil
        }
        let op = Ops.Transformation(points: points,
                                    offset: offset,
                                    overWrittenPixels: overWrittenPoints,
                                    selectedPixels: points.map { image[$0] },
                                    backgroundColor: background,
                                    horizontalFlip: horizontalFlip,
                                    verticalFlip: verticalFlip,
                                    flipRect: selection.boundingRectangle)
        history.record(op)
        image = image.transform(selection: selection,
                                horizontalFlip: horizontalFlip,
                                verticalFlip: verticalFlip,
                                offset: offset,
                                background: background)
    }
    
    func assign(pixel: SemanticPixel, at points: [Point2D]) {
        let op = Ops.Assignment(points: points,
                                oldColors: points.map { image[$0] },
                                newColors: Array(repeating: pixel, count: points.count))
        history.record(op)
        points.forEach { image[$0] = pixel }
    }
    
    func drawLine(from a: Point2D, to b: Point2D, color: SemanticPixel) {
        assign(pixel: color, at: a.line(to: b))
    }
    
    func drawEllipse(from a: Point2D, to b: Point2D, color: SemanticPixel) {
        assign(pixel: color, at: a.ellipse(to: b))
    }
}

struct SemanticPixel: Equatable, Identifiable, HasDefaultColor, Codable {
    // 0 represents the default semantic, which always exists.
    var semantic: Int
    var color: ColorIdentifier
    
    var id: Int {
        return semantic * 100 + color
    }
    
    init(semantic: Int, color: Int) {
        self.semantic = semantic
        self.color = color
    }
    
    static let clear: SemanticPixel = SemanticPixel(semantic: 0, color: 0)
}

struct SemanticIdentifier: Codable {
    var id: Int
    var name: String
    var children: [SemanticIdentifier] = []
}

extension SemanticIdentifier {
    func contains(_ id: Int) -> Bool {
        if id == self.id {
            return true
        } else {
            for child in children {
                if child.contains(id) {
                    return true
                }
            }
            return false
        }
    }
    
    func find(matching id: Int) -> SemanticIdentifier? {
        if id == self.id {
            return self
        } else {
            for child in children {
                if let match = child.find(matching: id) {
                    return match
                }
            }
            return nil
        }
    }
    
    func enumerateChildren(_ callback: (SemanticIdentifier) -> ()) {
        callback(self)
        for child in children {
            child.enumerateChildren(callback)
        }
    }
}

extension SemanticIdentifier: Identifiable {
    var childrenOrNil: [SemanticIdentifier]? {
        if children.count == 0 {
            return nil
        } else {
            return children
        }
    }
}

extension SemanticIdentifier: Hashable {
    
}
