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

class SemanticArtwork: Identifiable, ObservableObject {
    var id: URL {
        return url
    }
    
    var title: String {
        let name = url.lastPathComponent
        if name.starts(with: ".") {
            return name
        } else {
            let index = name.index(name.startIndex,
                                   offsetBy: name.count - url.pathExtension.count - 1,
                                   limitedBy: name.endIndex) ?? name.endIndex
            return String(name[name.startIndex..<index])
        }
    }
    
    var type: String {
        if url.pathExtension == "json" {
            return "semantic"
        } else {
            return "bitmap"
        }
    }
    
    var url: URL
    
    @Published
    var root: SemanticIdentifier
    
    @Published
    var image: PixelImage<SemanticPixel<RGBA>>
    
    @Published
    var colorPalettes: [Int : ColorPalette]
    
    init(url: URL, image: PixelImage<SemanticPixel<RGBA>>, root: SemanticIdentifier) {
        self.url = url
        self.root = root
        self.image = image
        self.colorPalettes = [:]
        
        root.enumerateChildren { (semid) in
            let colors = semid.colorPalette.map { IdentifiableColor(color: $0, id: UUID()) }
            colorPalettes[semid.id] = ColorPalette(colors: colors)
        }
    }
    
    init(url: URL, image: PixelImage<SemanticPixel<RGBA>>) {
        self.url = url
        self.root = SemanticIdentifier(id: -1, name: "Root")
        self.image = image
        self.colorPalettes = [:]
        
        for pixel in image.buffer {
            if let palette = colorPalettes[pixel.id] {
                if !palette.colors.contains(where: { $0.color == pixel.color }) {
                    let color = IdentifiableColor(color: pixel.color, id: UUID())
                    palette.colors.append(color)
                }
            } else {
                let palette = ColorPalette(colors: [IdentifiableColor(color: pixel.color, id: UUID())])
                colorPalettes[pixel.id] = palette
            }
        }
        
        root.children.append(SemanticIdentifier(id: 0, name: "Default"))
    }
}

extension SemanticArtwork {
    var icon: Image {
        if let img = image.convertToCGImage() {
            return Image(decorative: img, scale: 1.0)
        } else {
            return Image(systemName: "questionmark")
        }
    }
}

struct SemanticPixel<Pixel: ColorTypeProtocol> {
    // 0 represents the default semantic, which always exists.
    var id: Int
    var color: Pixel
}

extension SemanticPixel: ColorTypeProtocol {
    static var clear: SemanticPixel<Pixel> {
        return SemanticPixel(id: 0, color: Pixel.clear)
    }
    
    static var cgColorSpace: CGColorSpace {
        return Pixel.cgColorSpace
    }
    
    func convertToCGColor() -> CGColor {
        return color.convertToCGColor()
    }
}

struct SemanticIdentifier: Codable {
    var id: Int
    var name: String
    var colorPalette: [RGBA] = [.white]
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
