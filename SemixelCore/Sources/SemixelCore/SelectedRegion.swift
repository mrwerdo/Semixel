//
//  SelectedRegion.swift
//  Semixel
//
//  Created by Andrew Thompson on 27/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import CoreGraphics
import Geometry

public struct SelectedRegion {
    public enum UpdateMode {
        case toggle
        case deselect
        case select
    }
    
    public init(size: Size2D, default: Bool = false) {
        self.size = size
        selectionBuffer = [Bool](repeating: `default`, count: size.width * size.height)
    }
    
    private var selectionBuffer: [Bool]
    private(set) var size: Size2D
    
    private func isValid(_ p: Point2D) -> Bool {
        return 0..<size.width ~= p.x && 0..<size.height ~= p.y
    }
    
    public mutating func update(points: [Point2D], mode: UpdateMode) {
        for point in points {
            assert(isValid(point))
            switch mode {
            case .select:
                selectionBuffer[point.y * size.width + point.x] = true
            case .deselect:
                selectionBuffer[point.y * size.width + point.x] = false
            case .toggle:
                selectionBuffer[point.y * size.width + point.x].toggle()
            }
        }
    }
    
    public func boundingPath(horizontalFlip: Bool, verticalFlip: Bool) -> CGPath {
        let path = CGMutablePath()
        
        let ha: Int = horizontalFlip ? 1 : 0
        let hb: Int = horizontalFlip ? -1 : 1
        let va: Int = verticalFlip ? 1 : 0
        let vb: Int = verticalFlip ? -1 : 1
        
        let rect = boundingRectangle
        
        func map(_ point: Point2D) -> CGPoint {
            CGPoint(x: ha * (rect.bottomRight.x + rect.bottomLeft.x + 1) + hb * point.x,
                    y: va * (rect.bottomLeft.y + rect.topLeft.y + 1) + vb * point.y)
        }
        
        for y in 0..<size.height {
            for x in 0..<size.width {
                for edge in adjacentEdgesTo(x, y) {
                    // Each line segment should actually be closed at this point.
                    path.move(to: map(edge.start))
                    path.addLine(to: map(edge.end))
                    path.closeSubpath()
                }
            }
        }
        
        return path
    }
    
    public var selectedPoints: [Point2D] {
        var points: [Point2D] = []
        for y in 0..<size.height {
            for x in 0..<size.width {
                if isSelected(at: x, y, default: false) {
                    points.append(Point2D(x: x, y: y))
                }
            }
        }
        return points
    }
    
    public var boundingRectangle: Rect2D {
        let points = selectedPoints
        if points.count > 0 {
            var r = Rect2D(c1: points.first!, c2: points.first!)
            for point in points {
                r.bottomLeft.x = min(r.bottomLeft.x, point.x)
                r.bottomLeft.y = min(r.bottomLeft.y, point.y)
                r.topRight.x = max(r.topRight.x, point.x)
                r.topRight.y = max(r.topRight.y, point.y)
            }
            return r
        } else {
            return .zero
        }
    }
    
    private struct Edge {
        var start: Point2D
        var end: Point2D
    }
    
    public func isSelected(at x: Int, _ y: Int, default: Bool) -> Bool {
        return (isValid(Point2D(x: x, y: y)) && selectionBuffer[y * size.width + x]) || `default`
    }
    
    /// Examine the four pixels located around pixel and return any that are located on the border.
    private func adjacentEdgesTo(_ x: Int, _ y: Int) -> [Edge] {

        let selected = selectionBuffer[y * size.width + x]
        var edges: [Edge] = []
        
        if selected != isSelected(at: x, y - 1, default: false) {
            edges.append(Edge(start: Point2D(x: x, y: y),
                              end: Point2D(x: x + 1, y: y)))
        }
        
        if selected != isSelected(at: x, y + 1, default: false) {
            edges.append(Edge(start: Point2D(x: x, y: y + 1),
                              end: Point2D(x: x + 1, y: y + 1)))
        }
        
        if selected != isSelected(at: x - 1, y, default: false) {
            edges.append(Edge(start: Point2D(x: x, y: y),
                              end: Point2D(x: x, y: y + 1)))
        }
        
        if selected != isSelected(at: x + 1, y, default: false) {
            edges.append(Edge(start: Point2D(x: x + 1, y: y),
                              end: Point2D(x: x + 1, y: y + 1)))
        }
        
        return edges
    }
}
