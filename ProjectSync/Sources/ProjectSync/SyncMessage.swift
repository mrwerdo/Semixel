//
//  SyncMessage.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import CoreGraphics

struct RGBA: Equatable, Codable, Hashable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    
    static var white: RGBA {
        return RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    static var clear: RGBA {
        return RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    }
    
    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.init(
            red: CGFloat(red)/255,
            green: CGFloat(green)/255,
            blue: CGFloat(blue)/255,
            alpha: CGFloat(alpha)/255)
    }
}

enum PixelType: String, Codable {
    case semantic
}

struct Size2D: Codable, CustomStringConvertible {
    var width: Int
    var height: Int
    
    var description: String {
        return "\(width)x\(height)"
    }
}

struct ArtworkMetadata: Identifiable, Codable {
    let id: String
    let title: String
    let size: Size2D
    let pixelType: PixelType
    let path: String
    let project: String?
}

struct SyncRequest: Codable {
    let project: String?
    let filter: String?
    let projectBaseDirectory: String
}

struct SyncResponse: Codable {
    var artworkList: [ArtworkMetadata]
    var pixelData: [String : [RGBA]]
}
