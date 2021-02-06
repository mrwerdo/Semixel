//
//  PixelImage.swift
//  Semixel
//
//  Created by Andrew Thompson on 10/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit


protocol ColorTypeProtocol {
    static var clear: Self { get }
    static var cgColorSpace: CGColorSpace { get }
    func convertToCGColor() -> CGColor
}

struct PixelImage<ColorType> {
    
    var buffer: [ColorType]
    private(set) var size: Size2D
    
    init(copy: PixelImage) {
        buffer = copy.buffer
        size = copy.size
    }
    
    init(width: Int, height: Int, default: ColorType) {
        buffer = [ColorType](repeating: `default`, count: width * height)
        size = Size2D(width: width, height: height)
    }
    
    init(size: Size2D, buffer: [ColorType]) {
        self.buffer = buffer
        self.size = size
    }
    
    func isValid(_ point: Point2D) -> Bool {
        return point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height
    }
    
    func floodSearch(at point: Point2D, isIncluded: (_ point: Point2D, _ color: ColorType) -> Bool) -> [Point2D] {
        var unvisitedPoints: [Point2D] = [point]
        var points = unvisitedPoints
        
        let offsets = [
            (0, 1),
            (0, -1),
            (-1, 0),
            (1, 0)
        ].map(Point2D.init)
        
        while let p = unvisitedPoints.popLast() {
            for dp in offsets {
                let point = p + dp
                if isValid(point) && !points.contains(point) && isIncluded(point, self[point.x, point.y]) {
                    points.append(point)
                    unvisitedPoints.append(point)
                }
            }
        }
        
        return points
    }
    
    subscript(x: Int, y: Int) -> ColorType {
        get {
            return buffer[y * size.width + x]
        }
        
        set {
            buffer[y * size.width + x] = newValue
        }
    }
    
    subscript(point: Point2D) -> ColorType {
        get {
            return self[point.x, point.y]
        }
        
        set {
            self[point.x, point.y] = newValue
        }
    }
}

extension PixelImage where ColorType: ColorTypeProtocol {
    init(width: Int, height: Int) {
        buffer = [ColorType](repeating: .clear, count: width * height)
        size = Size2D(width: width, height: height)
    }
    
    func moveRectangle(between p1: Point2D, and p2: Point2D, by offset: Point2D) -> PixelImage {
        return moveRectangle(between: p1, and: p2, by: offset, background: .clear)
    }
}

extension PixelImage: Codable where ColorType: Codable { }
extension PixelImage: Equatable where ColorType: Equatable { }

extension PixelImage {
    func moveRectangle(between p1: Point2D, and p2: Point2D, by offset: Point2D, background: ColorType) -> PixelImage {
        let a = Point2D(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
        let b = Point2D(x: max(p1.x, p2.x), y: max(p1.y, p2.y))
        
        var img = PixelImage(copy: self)
        
        for y in a.y...b.y {
            for x in a.x...b.x {
                img[x, y] = background
            }
        }
        
        for y in a.y...b.y {
            for x in a.x...b.x {
                img[x + offset.x, y + offset.y] = self[x, y]
            }
        }
        
        return img
    }

    func drawEllipse(from p0: Point2D, to p1: Point2D, color: ColorType) -> PixelImage {
        
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
        
        var img = PixelImage(copy: self)
        
        for point in points {
            img[point] = color
        }
        
        return img
    }

    func drawLine(from p1: Point2D, to p2: Point2D, color: ColorType) -> PixelImage {
        // See the algorithm here: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm

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
        
        // Render path...
        var img = PixelImage(copy: self)
        
        for point in path {
            img[point] = color
        }
        
        return img
    }
}

extension PixelImage {
    func move(selection: SelectedRegion, by offset: Point2D, background: ColorType) -> PixelImage {
        // Everything inside of selection is translated by offset,
        var img = PixelImage(copy: self)
        
        let selectedPoints = selection.selectedPoints
        
        for point in selectedPoints {
            img[point] = background
        }
        
        for point in selection.selectedPoints where img.isValid(point + offset) {
            img[point + offset] = self[point]
        }
        
        return img
    }
}
