//
//  SemanticArtwork.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import UIKit

class SemanticArtwork: Identifiable, ObservableObject {
    var id: URL {
        return url
    }
    
    var name: String {
        return url.lastPathComponent
    }
    var url: URL
    
    @Published
    var root: SemanticIdentifier
    
    @Published
    var image: PixelImage<SemanticPixel<RGBA>>
    
    @Published
    var colorPalettes: ColorPaletteData
    
    init(url: URL, image: PixelImage<SemanticPixel<RGBA>>, root: SemanticIdentifier) {
        self.url = url
        self.root = root
        self.image = image
        self.colorPalettes = ColorPaletteData(semanticTag: 0, colors: [:])
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
