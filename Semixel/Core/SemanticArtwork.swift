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

final class SemanticArtwork: Identifiable, ObservableObject {
    let id: String

    @Published
    var root: SemanticIdentifier
    
    @Published
    var image: PixelImage<SemanticPixel<RGBA>>
    
    @Published
    var colorPalettes: [Int : ColorPalette]
    
    init(id: String, title: String, image: PixelImage<SemanticPixel<RGBA>>, root: SemanticIdentifier, colorPalettes: [Int : [RGBA]]) {
        self.id = id
        self.root = root
        self.image = image
        self.colorPalettes = [:]
        
        for (key, colors) in colorPalettes {
            self.colorPalettes[key] = ColorPalette(colors: colors.map { IdentifiableColor(color: $0, id: UUID()) })
        }        
    }
    
    func recomputeColorPalette() {
        root = SemanticIdentifier(id: -1, name: "Root")
        colorPalettes = [:]
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
    
    init(createUsing metadata: ArtworkMetadata) {
        self.id = metadata.id
        self.root = SemanticIdentifier(id: -1, name: "Root")
        self.image = PixelImage(width: metadata.size.width, height: metadata.size.height)
        let palette = ColorPalette(colors: [IdentifiableColor(color: RGBA.clear, id: UUID())])
        self.colorPalettes = [0 : palette]
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
