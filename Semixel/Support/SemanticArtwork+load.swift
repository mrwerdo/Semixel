//
//  SemanticArtwork+load.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import UIKit

struct EncodedSemanticArtwork: Codable {
    var size: Size2D
    var identifierTree: SemanticIdentifier
    var colorPalettes: [Int: [RGBA]]
    var semantics: [Int]
    var pixels: [RGBA]
}

func load<T: Decodable>(url: URL) throws -> T {
    let decoder = JSONDecoder()
    let data = try Data(contentsOf: url)
    return try decoder.decode(T.self, from: data)
}

extension SemanticArtwork {
    
    struct DecodingError: Error, CustomStringConvertible {
        var description: String
    }
    
    convenience init(url: URL, _ esa: EncodedSemanticArtwork) throws {
        if esa.size.width * esa.size.height != esa.semantics.count {
            throw DecodingError(description: "Incorrect number of semantic identifiers.")
        }

        if esa.semantics.count != esa.pixels.count {
            throw DecodingError(description: "Incorrect number of pixels.")
        }

        // Check that every semantic identifier in the image is contained in semIdGraph.
        for id in esa.semantics {
            if !esa.identifierTree.contains(id) {
                throw DecodingError(description: "Image contanis unknown semantic identifier.")
            }
        }

        let buffer = zip(esa.semantics, esa.pixels).map { id, color in
            SemanticPixel<RGBA>(id: id, color: color)
        }

        let image = PixelImage<SemanticPixel<RGBA>>(size: esa.size, buffer: buffer)
        self.init(url: url,
                  image: image,
                  root: esa.identifierTree,
                  colorPalettes: esa.colorPalettes)
    }
    
    func write(to url: URL) throws {
        let semantics = image.buffer.map { $0.id }
        let pixels = image.buffer.map { $0.color }
        
//        for (id, palette) in colorPalettes {
//            root[id].colorPalette = palette.colors.map { $0.color }
//        }
        
        let esa = EncodedSemanticArtwork(size: image.size,
                                         identifierTree: root,
                                         colorPalettes: colorPalettes.mapValues { $0.colors.map { $0.color } },
                                         semantics: semantics,
                                         pixels: pixels)
        let encoder = JSONEncoder()
        let data = try encoder.encode(esa)
        try data.write(to: url)
    }
}
