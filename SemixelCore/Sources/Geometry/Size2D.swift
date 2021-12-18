//
//  Size2D.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//


@frozen
public struct Size2D : Codable, Equatable, Hashable {
    public var width: Int
    public var height: Int
    
    @inlinable
    public init(width: Int = 0, height: Int = 0) {
        self.width = width
        self.height = height
    }
    
    @inlinable
    public static var zero: Size2D {
        return Size2D()
    }
}

public extension Size2D {
    func iterateCoordinates(apply: (Point2D) -> ()) {
        for x in 0..<width {
            for y in 0..<height {
                apply(Point2D(x: x, y: y))
            }
        }
    }
}

public extension Size2D {
    @inlinable
    static func +(lhs: Size2D, rhs: Size2D) -> Size2D {
        Size2D(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    @inlinable
    static func -(lhs: Size2D, rhs: Size2D) -> Size2D {
        Size2D(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    @inlinable
    static func *(lhs: Size2D, rhs: Size2D) -> Size2D {
        Size2D(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }

    @inlinable
    static func /(lhs: Size2D, rhs: Size2D) -> Size2D {
        Size2D(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
    }

    @inlinable
    static prefix func -(arg: Size2D) -> Size2D {
        Size2D(width: -arg.width, height: -arg.height)
    }

    @inlinable
    static func +=(lhs: inout Size2D, rhs: Size2D) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }

    @inlinable
    static func -=(lhs: inout Size2D, rhs: Size2D) {
        lhs.width -= rhs.width
        lhs.height -= rhs.height
    }

    @inlinable
    static func *=(lhs: inout Size2D, rhs: Size2D) {
        lhs.width *= rhs.width
        lhs.height *= rhs.height
    }

    @inlinable
    static func /=(lhs: inout Size2D, rhs: Size2D) {
        lhs.width /= rhs.width
        lhs.height /= rhs.height
    }
}

public extension Size2D {
    @inlinable
    static func *=(a: inout Size2D, b: Int) {
        a.width *= b
        a.height *= b
    }
    
    @inlinable
    static func +=(a: inout Size2D, b: Int)  {
        a.width += b
        a.height += b
    }
    
    @inlinable
    static func -=(a: inout Size2D, b: Int) {
        a.width -= b
        a.height -= b
    }
    
    @inlinable
    static func /=(a: inout Size2D, b: Int) {
        a.width /= b
        a.height /= b
    }
}

public extension Size2D {
    @inlinable
    static func *(a: Size2D, b: Int) -> Size2D {
        Size2D(width: a.width * b, height: a.height * b)
    }
    
    @inlinable
    static func *(a: Int, b: Size2D) -> Size2D {
        Size2D(width: b.width * a, height: b.height * a)
    }
    
    @inlinable
    static func /(a: Size2D, b: Int) -> Size2D {
        Size2D(width: a.width / b, height: a.height / b)
    }
    
    @inlinable
    static func /(a: Int, b: Size2D) -> Size2D {
        Size2D(width: b.width * a, height: b.height * a)
    }
}
