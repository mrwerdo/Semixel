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

protocol HasDefaultColor {
    static var clear: Self { get }
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

extension PixelImage where ColorType: HasDefaultColor {
    init(width: Int, height: Int) {
        buffer = [ColorType](repeating: .clear, count: width * height)
        size = Size2D(width: width, height: height)
    }
    
    func moveRectangle(between p1: Point2D, and p2: Point2D, by offset: Point2D) -> PixelImage {
        return moveRectangle(between: p1, and: p2, by: offset, background: .clear)
    }
    
    func transform(selection: SelectedRegion, horizontalFlip: Bool = false, verticalFlip: Bool = false, offset: Point2D = .zero) -> PixelImage {
        transform(selection: selection,
             horizontalFlip: horizontalFlip,
             verticalFlip: verticalFlip,
             offset: offset,
             background: .clear)
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
        var img = PixelImage(copy: self)
        for point in p0.ellipse(to: p1) {
            img[point] = color
        }
        return img
    }

    func drawLine(from p1: Point2D, to p2: Point2D, color: ColorType) -> PixelImage {
        var img = PixelImage(copy: self)
        for point in p1.line(to: p2) {
            img[point] = color
        }
        return img
    }
}

extension PixelImage {
    func transform(selection: SelectedRegion, horizontalFlip: Bool, verticalFlip: Bool, offset: Point2D, background: ColorType) -> PixelImage {
        if !verticalFlip && !horizontalFlip && offset == .zero {
            return self
        }
        
        let rect = selection.boundingRectangle
        let points = selection.selectedPoints
        
        let ha: Int = horizontalFlip ? 1 : 0
        let hb: Int = horizontalFlip ? -1 : 1
        let va: Int = verticalFlip ? 1 : 0
        let vb: Int = verticalFlip ? -1 : 1
        
        var img = PixelImage(copy: self)

        for point in points {
            img[point] = background
        }
        
        for point in points {
            let newPoint = Point2D(x: ha * (rect.bottomRight.x + rect.bottomLeft.x) + hb * point.x + offset.x,
                                y: va * (rect.bottomLeft.y + rect.topLeft.y) + vb * point.y + offset.y)
            if isValid(newPoint) {
                img[newPoint] = self[point]
            }
        }
        
        return img
    }
}
