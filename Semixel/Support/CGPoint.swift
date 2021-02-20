//
//  CGPoint.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    init(_ cgsize: CGSize) {
        self.init()
        self.x = cgsize.width
        self.y = cgsize.height
    }
    init(_ v: CGVector) {
        self.init()
        x = v.dx
        y = v.dy
    }
}

public extension CGPoint {

    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(
            x: lhs.x + rhs.x,
            y: lhs.y + rhs.y
        )
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y
        )
    }

    static func *(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(
            x: lhs.x * rhs.x,
            y: lhs.y * rhs.y
        )
    }

    static func /(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(
            x: lhs.x / rhs.x,
            y: lhs.y / rhs.y
        )
    }

    static prefix func -(arg: CGPoint) -> CGPoint {
        return CGPoint(
            x: -arg.x,
            y: -arg.y
        )
    }

    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static func -=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    static func *=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
    }

    static func /=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x /= rhs.x
        lhs.y /= rhs.y
    }
}
