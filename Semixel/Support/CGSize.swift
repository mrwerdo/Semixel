//
//  CGSize.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import CoreGraphics

extension CGSize {
    init(_ dx: CGFloat = 0, _ dy: CGFloat = 0) {
        self.init()
        self.width = dx
        self.height = dy
    }
    
    init(square: CGFloat) {
        self.init()
        self.width = square
        self.height = square
    }
}

extension CGSize {
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(lhs.width * rhs, lhs.height * rhs)
    }
    
    static func *(lhs: CGFloat, rhs: CGSize) -> CGSize {
        return CGSize(rhs.width * lhs, rhs.height * lhs)
    }
    
    static func /(lhs: CGFloat, rhs: CGSize) -> CGSize {
        return CGSize(rhs.width / lhs, rhs.height / lhs)
    }
    
    static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(lhs.width / rhs, lhs.height / rhs)
    }
}

public extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    static func *(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }

    static func /(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
    }

    static prefix func -(arg: CGSize) -> CGSize {
        CGSize(width: -arg.width, height: -arg.height)
    }

    static func +=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }

    static func -=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width -= rhs.width
        lhs.height -= rhs.height
    }

    static func *=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width *= rhs.width
        lhs.height *= rhs.height
    }

    static func /=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width /= rhs.width
        lhs.height /= rhs.height
    }
}
