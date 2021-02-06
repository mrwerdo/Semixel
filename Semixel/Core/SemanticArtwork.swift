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
        self.colorPalette = ColorPalette(colors: [0 : .clear])
        root.children.append(SemanticIdentifier(id: 0, name: "Default"))
        
        anyCancellable = colorPalette.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        anyCancellable?.cancel()
    }
}

extension SemanticArtwork {
    var icon: Image {
        if let img = bitmapImage.convertToCGImage() {
            return Image(decorative: img, scale: 1.0)
        } else {
            return Image(systemName: "questionmark")
        }
    }
}

struct SemanticPixel: Equatable, Identifiable {
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
