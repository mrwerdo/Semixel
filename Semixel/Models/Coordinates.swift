//
//  Coordinates.swift
//  Gravity Evaders
//
//  Created by Andrew Thompson on 22/11/19.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation


public protocol Countable : Comparable, Hashable {
    static func +=(a: inout Self, b: Self)
    static prefix func -(n: Self) -> Self
    static func *=(a: inout Self, b: Self)
    static func /=(a: inout Self, b: Self)
    
    static func +(a: Self, b: Self) -> Self
    static func -(a: Self, b: Self) -> Self
    static func *(a: Self, b: Self) -> Self
    static func /(a: Self, b: Self) -> Self
}

public extension Countable {
    
    static func -=(a: inout Self, b: Self) {
        a = a - b
    }
    
    static func +(a: Self, b: Self) -> Self {
        var sum = a
        sum += b
        return sum
    }
    
    static func -(a: Self, b: Self) -> Self {
        var sum = a
        sum += -b
        return sum
    }
    
    static func *(a: Self, b: Self) -> Self {
        var sum = a
        sum *= b
        return sum
    }
    
    static func /(a: Self, b: Self) -> Self {
        var sum = a
        sum /= b
        return sum
    }
}

public protocol CoordinateIn2Dimensions : Countable {
    associatedtype Measure : Countable
    
    var x: Measure { get set }
    var y: Measure { get set }
    var distanceFromOrigin: Measure { get }
}

public extension CoordinateIn2Dimensions {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    var distanceFromOrigin: Measure {
        return x*x + y*y
    }
    
    static func +=(a: inout Self, b: Self) {
        a.x += b.x
        a.y += b.y
    }
    
    static prefix func -(n: Self) -> Self {
        var r = n
        r.x = -n.x
        r.y = -n.y
        return r
    }
    
    static func *=(a: inout Self, b: Self) {
        a.x *= b.x
        a.y *= b.y
    }
    
    static func /=(a: inout Self, b: Self) {
        a.x /= b.x
        a.y /= b.y
    }
    
    static func <(a: Self, b: Self) -> Bool {
        return a.distanceFromOrigin < b.distanceFromOrigin
    }
    
    static func ==(a: Self, b: Self) -> Bool {
        return a.x == b.x && a.y == b.y
    }
    
    static func >(a: Self, b: Self) -> Bool {
        return a.distanceFromOrigin > b.distanceFromOrigin
    }
    
    static func *=(a: inout Self, b: Measure) {
        a.x *= b
        a.y *= b
    }
    
    static func +=(a: inout Self, b: Measure)  {
        a.x += b
        a.y += b
    }
    static func -=(a: inout Self, b: Measure) {
        a.x -= b
        a.y -= b
    }
    static func /=(a: inout Self, b: Measure) {
        a.x /= b
        a.y /= b
    }
    
    static func *(a: Self, b: Measure) -> Self {
        var i = a
        i *= b
        return i
    }
    
    static func *(a: Measure, b: Self) -> Self {
        var i = b
        i *= a
        return i
    }
    
    static func /(a: Self, b: Measure) -> Self {
        var i = a
        i /= b
        return i
    }
    
    static func /(a: Measure, b: Self) -> Self {
        var i = b
        i /= a
        return i
    }
}

public protocol CoordinateIn3Dimensions : CoordinateIn2Dimensions {
    var z: Measure { get set }
}

// Note:    The operators in this extension must overload the operators in the
//          extension `CoordinateIn2Dimensions` above.
public extension CoordinateIn3Dimensions {
    
    var hashValue: Int {
        let a = x.hashValue
        let b = y.hashValue
        let c = z.hashValue
        
        return a ^ b + (b ^ c << 16) + (a ^ c << 32)
    }
    
    var distanceFromOrigin: Measure {
        let a: Measure = x * x
        let b: Measure = y * y
        let c: Measure = z * z
        return a + b + c
        
        // This was causing slower complie times.
        // return x*x + y*y + z*z
    }
    
    static func +=(a: inout Self, b: Self) {
        a.x += b.x
        a.y += b.y
        a.z += b.z
    }
    
    static prefix func -(n: Self) -> Self {
        var r = n
        r.x = -n.x
        r.y = -n.y
        r.z = -n.z
        return r
    }
    
    static func -=(a: inout Self, b: Self) {
        a.x -= b.x
        a.y -= b.y
        a.z -= b.z
    }
    
    static func *=(a: inout Self, b: Self) {
        a.x *= b.x
        a.y *= b.y
        a.z *= b.z
    }
    
    static func /=(a: inout Self, b: Self) {
        a.x /= b.x
        a.y /= b.y
        a.z /= b.z
    }
    
    static func <(a: Self, b: Self) -> Bool {
        return a.distanceFromOrigin < b.distanceFromOrigin
    }
    
    static func ==(a: Self, b: Self) -> Bool {
        return a.x == b.x && a.y == b.y && a.z == b.z
    }
    
    static func >(a: Self, b: Self) -> Bool {
        return a.distanceFromOrigin > b.distanceFromOrigin
    }
}

extension CGPoint {
    func heading(to point: CGPoint) -> CGFloat {
        let difference = point - self
        return atan2(difference.y, difference.x)
    }
    
    func vector(headingTo point: CGPoint, speed: CGFloat) -> CGVector {
        let difference = point - self
        let theta = atan2(difference.y, difference.x)
        return CGVector(dx: speed * cos(theta), dy: speed * sin(theta))
    }
}

public protocol CountableArea : Countable {
    associatedtype Measure: Countable
    
    var width: Measure { get set }
    var height: Measure { get set }
    var area: Measure { get }
}

public extension CountableArea {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
    
    var area: Measure {
        return width * height
    }
    
    static func ==(a: Self, b: Self) -> Bool {
        return a.width == b.width && a.height == b.height
    }
    
    static func <(a: Self, b: Self) -> Bool {
        return a.area < b.area
    }
    
    static func >(a: Self, b: Self) -> Bool {
        return a.area > b.area
    }
    
    static func +=(a: inout Self, b: Self) {
        a.width += b.width
        a.height += b.height
    }
    static prefix func -(a: Self) -> Self {
        var r = a
        r.width = -a.width
        r.height = -a.height
        return r
    }
    static func *=(a: inout Self, b: Self) {
        a.width *= b.width
        a.height *= b.height
    }
    
    static func /=(a: inout Self, b: Self) {
        a.width /= b.width
        a.height /= b.height
    }
}

public extension CountableArea where Measure == Int {
    func iterateCoordinates(apply: (Point2D) -> ()) {
        for x in 0..<width {
            for y in 0..<height {
                apply(Point2D(x: x, y: y))
            }
        }
    }
}


public protocol CountableVolume : Comparable {
    associatedtype Measure: Countable
    
    var width: Measure { get set }
    var height: Measure { get set }
    var breadth: Measure { get set }
    var volume: Measure { get }
}

public extension CountableVolume {
    var volume: Measure {
        return width * height * breadth
    }
    
    static func ==(a: Self, b: Self) -> Bool {
        return a.width == b.width && a.height == b.height && a.breadth == b.breadth
    }
    
    static func <(a: Self, b: Self) -> Bool {
        return a.volume < b.volume
    }
    
    static func >(a: Self, b: Self) -> Bool {
        return a.volume > b.volume
    }
}

public extension CountableVolume where Measure == Int {
    func iterateCoordinates(apply: (Point3D) throws -> ()) rethrows {
        for x in 0..<width {
            for y in 0..<height {
                for z in 0..<breadth {
                    try apply(Point3D(x: x, y: y, z: z))
                }
            }
        }
    }
}

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

// -----------------------------------------------------------------------------
// MARK: - Countable Protocol Conformance
// -----------------------------------------------------------------------------

extension Int : Countable { }
extension CGFloat : Countable { }

// -----------------------------------------------------------------------------
// MARK: - Coordinate Protocol Conformance
// -----------------------------------------------------------------------------

extension CGPoint : CoordinateIn2Dimensions {
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
    
    func distance(to p: CGPoint) -> CGFloat {
        return sqrt((p - self).distanceFromOrigin)
    }
}

extension CGVector : CoordinateIn2Dimensions {
    public var x: CGFloat {
        get { return dx }
        set { dx = newValue }
    }
    
    public var y: CGFloat {
        get { return dy }
        set { dy = newValue }
    }
}

extension CGVector {
    public static func *(lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
    
    public static func *(lhs: CGFloat, rhs: CGVector) -> CGVector {
        return CGVector(dx: rhs.dx * lhs, dy: rhs.dy * lhs)
    }
}

extension CGSize : CountableArea {
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
        return CGSize(lhs.width * rhs,lhs.height * rhs)
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

extension CGRect {
    var center: CGPoint {
        get {
            return CGPoint(x: width / 2, y: height / 2) + origin
        }
        set {
            let k = CGPoint(x: width / 2, y: height / 2)
            origin = newValue - k
        }
    }
    
    var corners: [CGPoint] {
        let a = origin
        let b = origin + CGPoint(x: size.width, y: 0)
        let c = origin + CGPoint(x: 0, y: size.height)
        let d = origin + CGPoint(x: size.width, y: size.height)
        
        return [a, b, c, d]
    }
}
