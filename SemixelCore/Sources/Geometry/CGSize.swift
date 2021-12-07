//
//  CGSize.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import CoreGraphics

public extension CGSize {
    @inlinable
    init(_ dx: CGFloat = 0, _ dy: CGFloat = 0) {
        self.init()
        self.width = dx
        self.height = dy
    }
    
    @inlinable
    init(square: CGFloat) {
        self.init()
        self.width = square
        self.height = square
    }
}

extension CGSize {
    @inlinable
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(lhs.width * rhs, lhs.height * rhs)
    }
    
    @inlinable
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
    @inlinable
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    @inlinable
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    @inlinable
    static func *(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }

    @inlinable
    static func /(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
    }

    @inlinable
    static prefix func -(arg: CGSize) -> CGSize {
        CGSize(width: -arg.width, height: -arg.height)
    }

    @inlinable
    static func +=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }

    @inlinable
    static func -=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width -= rhs.width
        lhs.height -= rhs.height
    }

    @inlinable
    static func *=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width *= rhs.width
        lhs.height *= rhs.height
    }

    @inlinable
    static func /=(lhs: inout CGSize, rhs: CGSize) {
        lhs.width /= rhs.width
        lhs.height /= rhs.height
    }
}
