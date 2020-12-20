//
//  Artwork.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

class Artwork: Identifiable, ObservableObject {
    var id: URL {
        return url
    }
    
    var name: String
    var url: URL
    @Published var pixelImage: PixelImage<RGBA>

    private var uiImage: UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
    
    var size: Size2D {
        let w = Int(uiImage?.size.width.rounded() ?? 0)
        let h = Int(uiImage?.size.height.rounded() ?? 0)
        return Size2D(width: w, height: h)
    }
    
    var image: Image {
        if let img = pixelImage.convertToCGImage() {
            return Image(decorative: img, scale: 1.0)
        } else {
            return Image(systemName: "questionmark")
        }
    }
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
        let image = UIImage(contentsOfFile: url.path)!
        self.pixelImage = PixelImage<RGBA>(width: image.width, height: image.height)
        image.enumeratePixels { (x, y, color) in
            self.pixelImage.buffer[y * pixelImage.size.width + x] = color
        }
    }
    
}
