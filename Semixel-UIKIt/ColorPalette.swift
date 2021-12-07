//
//  ColorPalette.swift
//  Semixel-UIKIt
//
//  Created by Andrew Thompson on 7/12/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import UIKit

struct Color {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
    
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red) / 255,
                       green: CGFloat(green) / 255,
                       blue: CGFloat(blue) / 255,
                       alpha: CGFloat(alpha) / 255)
    }
    
    init?(hex: String, alpha: UInt8 = 255) {
        if hex.count == 3 {
            var a = hex.startIndex
            var b = hex.index(after: a)
            red = UInt8(hex[a..<b], radix: 16) ?? 0
            a = b
            b = hex.index(after: a)
            green = UInt8(hex[a..<b], radix: 16) ?? 0
            a = b
            b = hex.index(after: a)
            blue = UInt8(hex[a..<b], radix: 16) ?? 0
            self.alpha = alpha
        } else if hex.count == 6 {
            var a = hex.startIndex
            var b = hex.index(after: a)
            red = UInt8(hex[a...b], radix: 16) ?? 0
            a = hex.index(after: b)
            b = hex.index(after: a)
            green = UInt8(hex[a...b], radix: 16) ?? 0
            a = hex.index(after: b)
            b = hex.index(after: a)
            blue = UInt8(hex[a...b], radix: 16) ?? 0
            self.alpha = alpha
        } else {
            return nil
        }
    }
}
