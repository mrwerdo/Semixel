//
//  Geometry.swift
//  Gravity Evaders
//
//  Created by Andrew Thompson on 22/11/19.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

// -----------------------------------------------------------------------------
// MARK: - Coordinate Concrete Types
// -----------------------------------------------------------------------------

public struct Point2D : CoordinateIn2Dimensions, Codable {
    public var x: Int
    public var y: Int
    
    public init() {
        x = 0
        y = 0
    }
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    static var zero: Point2D {
        return Point2D()
    }
}

public struct Point3D : CoordinateIn3Dimensions, CustomStringConvertible {
    public var x: Int
    public var y: Int
    public var z: Int
    
    public init() {
        x = 0
        y = 0
        z = 0
    }
    
    public init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    public init(tuple: (x: Int, y: Int, z: Int)) {
        self.x = tuple.x
        self.y = tuple.y
        self.z = tuple.z
    }
    
    public var description: String {
        return "(x: \(x), y: \(y), z: \(z))"
    }
    
    public static func +(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x + rhs.x,
                       y: lhs.y + rhs.y,
                       z: lhs.z + rhs.z
        )
    }
    
    public static func -(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x - rhs.x,
                       y: lhs.y - rhs.y,
                       z: lhs.z - rhs.z
        )
    }
    
    public static func *(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x * rhs.x,
                       y: lhs.y * rhs.y,
                       z: lhs.z * rhs.z
        )
    }
    
    public static func /(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x / rhs.x,
                       y: lhs.y / rhs.y,
                       z: lhs.z / rhs.z
        )
    }
    
    public static func +=(lhs: inout Point3D, rhs: Point3D) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }
    
    public static func -=(lhs: inout Point3D, rhs: Point3D) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }
    
    public static func *=(lhs: inout Point3D, rhs: Point3D) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
        lhs.z *= rhs.z
    }
    
    public static func /=(lhs: inout Point3D, rhs: Point3D) {
        lhs.x /= rhs.x
        lhs.y /= rhs.y
        lhs.z /= rhs.z
    }
    
    public static prefix func -(n: Point3D) -> Point3D {
        return Point3D(x: -n.x, y: -n.y, z: -n.z)
    }
}

public struct Size2D : CountableArea, Codable {
    public var width: Int
    public var height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}


public struct Size3D : CountableVolume {
    public var width: Int
    public var height: Int
    public var breadth: Int
    
    public init(width: Int = 0, height: Int = 0, breadth: Int = 0) {
        self.width = width
        self.height = height
        self.breadth = breadth
    }
    
    public var verticies: [Point3D] {
        typealias P = Point3D
        return [ P(x: 0,y: 0,z: 0),
                 P(x: 0,y: 0,z: breadth),
                 P(x: 0,y: height, z: 0),
                 P(x: 0, y: height, z: breadth),
                 P(x: width, y: 0, z: 0),
                 P(x: width, y: 0, z: breadth),
                 P(x: width, y: height, z: 0),
                 P(x: width, y: height, z: breadth)
        ]
    }
}

extension Point3D : Hashable {
    public var hashValue: Int {
        return x.hashValue ^ y.hashValue << 16 ^ z.hashValue << 32
    }
}

extension Size3D : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(breadth)
    }
    
    var coordinates: [Point3D] {
        var cs = [Point3D]()
        cs.reserveCapacity(volume)
        for x in 0..<width {
            for y in 0..<height {
                for z in 0..<breadth {
                    cs.append(Point3D(x: x, y: y, z: z))
                }
            }
        }
        return cs
    }
}

struct Rect2D: Hashable, Equatable, Codable {
    private var lx: Int
    private var ly: Int
    private var ux: Int
    private var uy: Int
}

extension Rect2D {
    
    init() {
        lx = 0
        ly = 0
        ux = 0
        uy = 0
    }
    
    init(c1: Point2D, c2: Point2D) {
        let lx = min(c1.x, c2.x)
        let ly = min(c1.y, c2.y)
        let ux = max(c1.x, c2.x)
        let uy = max(c1.y, c2.y)
        self.init(lx: lx, ly: ly, ux: ux, uy: uy)
    }
    
    init(x: Int, y: Int, width: Int, height: Int) {
        self.init(lx: x, ly: y, ux: y + width, uy: y + height)
    }
    
    init(origin: Point2D, size: Size2D) {
        self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
    
    var center: Point2D {
        get {
            Point2D(x: lx + ux, y: ly + uy) / 2
        }
    }
    
    var origin: Point2D {
        get {
            bottomLeft
        }
        set {
            bottomLeft = newValue
        }
    }
    
    var size: Size2D {
        get {
            Size2D(width: ux - lx, height: uy - ux)
        }
        set {
            ux = lx + newValue.width
            uy = ly + newValue.height
        }
    }

    var bottomLeft: Point2D {
        get {
            Point2D(x: lx, y: ly)
        }
        set {
            lx = newValue.x
            ly = newValue.y
        }
    }
    
    var bottomRight: Point2D {
        get {
            Point2D(x: ux, y: ly)
        }
        set {
            ux = newValue.x
            ly = newValue.y
        }
    }
    
    var topLeft: Point2D {
        get {
            Point2D(x: lx, y: uy)
        }
        set {
            lx = newValue.x
            uy = newValue.y
        }
    }
    
    var topRight: Point2D {
        get {
            Point2D(x: ux, y: uy)
        }
        set {
            ux = newValue.x
            uy = newValue.y
        }
    }
    
    static var zero: Rect2D {
        return Rect2D()
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

extension Point2D {
    func line(to point: Point2D) -> [Point2D] {
        // See the algorithm here: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm

        let p1 = self
        let p2 = point
        
        var path: [Point2D] = [p1]
        
        func plotLineLow(a: Point2D, b: Point2D) {
            let dx = b.x - a.x
            let dy = abs(b.y - a.y)
            let yi = b.y - a.y < 0 ? -1 : 1
            var D = 2 * dy - dx
            
            var y = a.y
            for x in a.x...b.x {
                path.append(Point2D(x: x, y: y))
                if D > 0 {
                    y += yi
                    D += 2 * (dy - dx)
                } else {
                    D += 2 * dy
                }
            }
        }
        
        func plotLineHigh(a: Point2D, b: Point2D) {
            let dx = abs(b.x - a.x)
            let dy = b.y - a.y
            let xi = b.x - a.x < 0 ? -1 : 1
            var D = 2 * dx - dy
            
            var x = a.x
            for y in a.y...b.y {
                path.append(Point2D(x: x, y: y))
                if D > 0 {
                    x += xi
                    D += 2 * (dx - dy)
                } else {
                    D += 2 * dx
                }
            }
        }
        
        if abs(p2.y - p1.y) < abs(p2.x - p1.x) {
            if p1.x > p2.x {
                plotLineLow(a: p2, b: p1)
            } else {
                plotLineLow(a: p1, b: p2)
            }
        } else {
            if p1.y > p2.y {
                plotLineHigh(a: p2, b: p1)
            } else {
                plotLineHigh(a: p1, b: p2)
            }
        }
        
        return path
    }
    
    func ellipse(to other: Point2D) -> [Point2D] {
        
        let p0 = self
        let p1 = other
        
        // Source: http://members.chello.at/~easyfilter/Bresenham.pdf
        
        var points: [Point2D] = []
        
        func setPixel(_ x: Int, _ y: Int) {
            points.append(Point2D(x: x, y: y))
        }
        
        var a = abs(p1.x - p0.x)
        let b = abs(p1.y - p0.y)
        var b1 = b & 1
        var dx = Double(4 * (1 - a) * b * b)
        var dy = Double(4 * (b1 + 1) * a * a)
        var err = dx + dy + Double(b1 * a * a)
        var e2: Double = 0.0
        
        var x0 = p0.x
        var y0 = p0.y
        var x1 = p1.x
        var y1 = p1.y
        
        if (x0 > x1) {
            x0 = x1
            x1 += a
        }
        
        if (y0 > y1) {
            y0 = y1
        }
        
        y0 += (b + 1)/2
        y1 = y0 - b1
        
        a = 8*a*a
        b1 = 8*b*b
        
        repeat {
            setPixel(x1, y0)
            setPixel(x0, y0)
            setPixel(x0, y1)
            setPixel(x1, y1)
            e2 = 2*err
            if (e2 <= dy) {
                y0 += 1
                y1 -= 1
                dy += Double(a)
                err += dy
            }
            
            if (e2 >= dx || 2 * err > dy) {
                x0 += 1
                x1 -= 1
                dx += Double(b1)
                err += dx
            }
        } while (x0 <= x1)
        
        while (y0 - y1 <= b) {
            setPixel(x0 - 1, y0)
            setPixel(x1 + 1, y0)
            y0 += 1
            setPixel(x0 - 1, y1)
            setPixel(x1 + 1, y1)
            y1 -= 1
        }
        return points
    }
}

