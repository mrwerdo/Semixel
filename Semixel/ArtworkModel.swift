//
//  ArtworkModel.swift
//  Semixel
//
//  Created by Andrew Thompson on 10/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

class Artwork: Identifiable, ObservableObject {
    var id: URL {
        return url
    }
    
    var name: String
    var url: URL
    @Published var pixelImage: PixelImage

    private var uiImage: UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
    
    var size: Size2D {
        let w = Int(uiImage?.size.width.rounded() ?? 0)
        let h = Int(uiImage?.size.height.rounded() ?? 0)
        return Size2D(width: w, height: h)
    }
    
    var image: Image {
        if let img = uiImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "questionmark")
        }
    }
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
        self.pixelImage = PixelImage(uiImage: UIImage(contentsOfFile: url.path)!)
    }
    
}

private func load() -> [Artwork] {
    guard let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Default Artwork") else {
        print("Failed to find urls for Default Artwork subdirectory.")
        return []
    }
    
    return urls.map { url in
        Artwork(name: url.lastPathComponent, url: url)
    }
}

final class ArtworkModel: ObservableObject {
    @Published var artwork: [Artwork] = load()
}
