//
//  RGBA.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct RGBA: Equatable, ColorTypeProtocol, Codable {
    func convertToCGColor() -> CGColor {
        var components: [CGFloat] = [
            red,
            green,
            blue,
            alpha
        ]
        return CGColor(colorSpace: RGBA.cgColorSpace, components: &components)!
    }
    
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
    
    init?(_ color: Color) {
        red = 0; green = 0; blue = 0; alpha = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.init(
            red: CGFloat(red)/255,
            green: CGFloat(green)/255,
            blue: CGFloat(blue)/255,
            alpha: CGFloat(alpha)/255)
    }
}

extension RGBA {
    
//    {"Flickr Pink":"f72585",
//    "Byzantine":"b5179e",
//    "Purple":"7209b7",
//    "Purple 2":"560bad",
//    "Trypan Blue":"480ca8",
//    "Trypan Blue 2":"3a0ca3",
//    "Persian Blue":"3f37c9",
//    "Ultramarine Blue":"4361ee",
//    "Dodger Blue":"4895ef",
//    "Vivid Sky Blue":"4cc9f0"}
    
    /* Array */

//    /* Object */
//    {"Xiketic":"03071e","Dark Sienna":"370617","Rosewood":"6a040f","Dark Red":"9d0208","Rosso Corsa":"d00000","Vermilion":"dc2f02","Persimmon":"e85d04","Carrot Orange":"f48c06","Orange Web":"faa307","Selective Yellow":"ffba08"}
    
    static let defaultColorPalette: [RGBA] = [
        "f72585", "b5179e", "7209b7", "560bad", "480ca8",
        "3a0ca3", "3f37c9", "4361ee", "4895ef", "4cc9f0",
        // Second one
        "03071e","370617","6a040f","9d0208","d00000","dc2f02","e85d04","f48c06","faa307","ffba08",
    ].compactMap(RGBA.init(hex:))
    
    init?(hex: String) {
        if hex.count == 6, let value = Int(hex, radix: 16) {
            red = CGFloat((value & 0xFF0000) >> 16) / 0xFF
            green = CGFloat((value & 0x00FF00) >> 8) / 0xFF
            blue = CGFloat(value & 0xFF) / 0xFF
            alpha = 1.0
        } else if hex.count == 3, let value = Int(hex, radix: 16) {
            red = CGFloat((value & 0xF00) >> 8) / 0xFF
            green = CGFloat((value & 0x0F0) >> 4) / 0xFF
            blue = CGFloat(value & 0xF) / 0xFF
            alpha = 1.0
        } else {
            return nil
        }
    }
}

extension RGBA {
    static var cgColorSpace: CGColorSpace {
        get {
            return CGColorSpaceCreateDeviceRGB()
        }
    }
}
