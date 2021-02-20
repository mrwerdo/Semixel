//
//  Rect2D.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

public struct Rect2D: Hashable, Equatable, Codable {
    private var lx: Int = 0
    private var ly: Int = 0
    private var ux: Int = 0
    private var uy: Int = 0
    
    public init() { }
    
    public init(c1: Point2D, c2: Point2D) {
        lx = min(c1.x, c2.x)
        ly = min(c1.y, c2.y)
        ux = max(c1.x, c2.x)
        uy = max(c1.y, c2.y)
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        lx = min(x, x + width)
        ly = min(y, y + height)
        ux = max(x, x + width)
        uy = max(y, y + height)
    }
    
    public init(origin: Point2D, size: Size2D) {
        self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
    
    public static var zero: Rect2D {
        return Rect2D()
    }
    
    public var center: Point2D {
        get {
            Point2D(x: lx + ux, y: ly + uy) / 2
        }
    }
    
    public var origin: Point2D {
        get {
            bottomLeft
        }
        set {
            bottomLeft = newValue
        }
    }
    
    public var size: Size2D {
        get {
            Size2D(width: ux - lx, height: uy - ux)
        }
        set {
            ux = lx + newValue.width
            uy = ly + newValue.height
        }
    }

    public var bottomLeft: Point2D {
        get {
            Point2D(x: lx, y: ly)
        }
        set {
            lx = newValue.x
            ly = newValue.y
        }
    }
    
    public var bottomRight: Point2D {
        get {
            Point2D(x: ux, y: ly)
        }
        set {
            ux = newValue.x
            ly = newValue.y
        }
    }
    
    public var topLeft: Point2D {
        get {
            Point2D(x: lx, y: uy)
        }
        set {
            lx = newValue.x
            uy = newValue.y
        }
    }
    
    public var topRight: Point2D {
        get {
            Point2D(x: ux, y: uy)
        }
        set {
            ux = newValue.x
            uy = newValue.y
        }
    }
}

extension Rect2D {
    var points: [Point2D] {
        var p = [Point2D]()
        p.reserveCapacity(size.width *  size.height)
        for y in bottomLeft.y..<topLeft.y {
            for x in bottomLeft.x..<bottomRight.x {
                p.append(Point2D(x: x, y: y))
            }
        }
        return p
    }
}
