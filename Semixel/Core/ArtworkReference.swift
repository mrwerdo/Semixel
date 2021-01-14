//
//  ArtworkReference.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import SwiftUI

enum PixelType {
    case semantic
}

struct ArtworkMetadata: Identifiable {
    var preview: Image
    var title: String
    var id: String
    var size: Size2D
    var pixelType: PixelType
}

extension ArtworkMetadata {
    private var type: String {
        switch pixelType {
        case .semantic:
            return "semantic"
        }
    }
    
    var subtitle: String {
        return "\(type) - \(size.width)x\(size.height)"
    }
}

class ArtworkStore: ObservableObject {
    
    @Published var artwork: [ArtworkMetadata] = []
    
    func save(_ artwork: ArtworkMetadata) throws {
        
    }
    
    func remove(_ artwork: ArtworkMetadata) throws {
        
    }
    
    func model(for artwork: ArtworkMetadata) -> SemanticArtwork {
        
    }
    
    func view(for artwork: ArtworkMetadata) -> some View {
        let destination = PixelView()
            .environmentObject(model(for: artwork))
        return destination
    }
}
