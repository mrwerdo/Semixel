//
//  Point2D.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

@frozen
public struct Point2D: Codable, Equatable, Hashable {
    public var x: Int
    public var y: Int
    
    @inlinable
    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }
    
    @inlinable
    public static var zero: Point2D {
        return Point2D()
    }
}

public extension Point2D {
    @inlinable
    static func +(lhs: Point2D, rhs: Point2D) -> Point2D {
        Point2D(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    @inlinable
    static func -(lhs: Point2D, rhs: Point2D) -> Point2D {
        Point2D(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    @inlinable
    static func *(lhs: Point2D, rhs: Point2D) -> Point2D {
        Point2D(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }

    @inlinable
    static func /(lhs: Point2D, rhs: Point2D) -> Point2D {
        Point2D(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }

    @inlinable
    static prefix func -(arg: Point2D) -> Point2D {
        Point2D(x: -arg.x, y: -arg.y)
    }

    @inlinable
    static func +=(lhs: inout Point2D, rhs: Point2D) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    @inlinable
    static func -=(lhs: inout Point2D, rhs: Point2D) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    @inlinable
    static func *=(lhs: inout Point2D, rhs: Point2D) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
    }

    @inlinable
    static func /=(lhs: inout Point2D, rhs: Point2D) {
        lhs.x /= rhs.x
        lhs.y /= rhs.y
    }
}

public extension Point2D {
    @inlinable
    static func *=(a: inout Self, b: Int) {
        a.x *= b
        a.y *= b
    }
    
    @inlinable
    static func +=(a: inout Self, b: Int)  {
        a.x += b
        a.y += b
    }
    
    @inlinable
    static func -=(a: inout Self, b: Int) {
        a.x -= b
        a.y -= b
    }
    
    @inlinable
    static func /=(a: inout Self, b: Int) {
        a.x /= b
        a.y /= b
    }
}

public extension Point2D {
    
    @inlinable
    static func *(a: Point2D, b: Int) -> Self {
        var i = a
        i *= b
        return i
    }
    
    @inlinable
    static func *(a: Int, b: Point2D) -> Self {
        var i = b
        i *= a
        return i
    }
    
    @inlinable
    static func /(a: Point2D, b: Int) -> Self {
        var i = a
        i /= b
        return i
    }
    
    @inlinable
    static func /(a: Int, b: Point2D) -> Self {
        var i = b
        i /= a
        return i
    }
}

public extension Point2D {
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

