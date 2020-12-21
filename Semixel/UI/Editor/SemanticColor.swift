//
//  SemanticColor.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import UIKit

class SemanticColor: Equatable {
    var label: Int
    var color: RGBA
    
    init(label: Int, color: RGBA) {
        self.label = label
        self.color = color
    }
    
    static func ==(lhs: SemanticColor, rhs: SemanticColor) -> Bool {
        return lhs.label == rhs.label && lhs.color == rhs.color
    }
}

extension SemanticColor: Identifiable {
    var id: String {
        return "\(label), \(color.red), \(color.green), \(color.blue), \(color.alpha)"
    }
}

extension SemanticColor {
    var cgColor: CGColor {
        get {
            return CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        }
        set {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if UIColor(cgColor: newValue).getRed(&r, green: &g, blue: &b, alpha: &a) {
                color = RGBA(red: r, green: g, blue: b, alpha: a)
            }
        }
    }
}
