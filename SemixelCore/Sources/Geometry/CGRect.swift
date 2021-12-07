//
//  CGRect.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import CoreGraphics

public extension CGRect {
    @inlinable
    var center: CGPoint {
        get {
            return CGPoint(x: width / 2, y: height / 2) + origin
        }
        set {
            let k = CGPoint(x: width / 2, y: height / 2)
            origin = newValue - k
        }
    }
    
    @inlinable
    var corners: [CGPoint] {
        let a = origin
        let b = origin + CGPoint(x: size.width, y: 0)
        let c = origin + CGPoint(x: 0, y: size.height)
        let d = origin + CGPoint(x: size.width, y: size.height)
        
        return [a, b, c, d]
    }
}
