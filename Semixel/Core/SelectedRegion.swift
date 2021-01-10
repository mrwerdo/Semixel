//
//  SelectedRegion.swift
//  Semixel
//
//  Created by Andrew Thompson on 27/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import CoreGraphics

struct SelectedRegion {
    enum UpdateMode {
        case toggle
        case deselect
        case select
    }
    
    init(size: Size2D) {
        self.size = size
        selectionBuffer = [Bool](repeating: false, count: size.width * size.height)
    }
    
    private var selectionBuffer: [Bool]
    private(set) var size: Size2D
    
    private func isValid(_ p: Point2D) -> Bool {
        return 0..<size.width ~= p.x && 0..<size.height ~= p.y
    }
    
    mutating func update(points: [Point2D], mode: UpdateMode) {
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
    
    var boundingPath: CGPath {
        var edges: [Edge] = []
        
        for y in 0..<size.width {
            for x in 0..<size.height {
                edges.append(contentsOf: adjacentEdgesTo(x, y))
            }
        }
        
        let path = CGMutablePath()
        
        for edge in edges {
            // Each line segment should actually be closed at this point.
            path.move(to: CGPoint(x: edge.start.x, y: edge.start.y))
            path.addLine(to: CGPoint(x: edge.end.x, y: edge.end.y))
            path.closeSubpath()
        }
        
        return path
    }
    
    var selectedPoints: [Point2D] {
        var points: [Point2D] = []
        for y in 0..<size.width {
            for x in 0..<size.height {
                if isSelected(at: x, y, default: false) {
                    points.append(Point2D(x: x, y: y))
                }
            }
        }
        return points
    }
    
    private struct Edge {
        var start: Point2D
        var end: Point2D
    }
    
    func isSelected(at x: Int, _ y: Int, default: Bool) -> Bool {
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
    
    // fixme: make computeBoundingPath() for disjoint regions
    // This algorithm appears to work correctly for connected regions, but fails when two disjoint
    // regions intersect because the assumption that only two edges intersect at a given point is
    // false - there might be four edges that intersect at a given point, two from different
    // regions.
    private func computeBoundingPath() -> CGPath {
        
        var edges: [Edge] = []
        
        for y in 0..<size.width {
            for x in 0..<size.height {
                edges.append(contentsOf: adjacentEdgesTo(x, y))
            }
        }
        
        var lineSegments: [[Edge]] = []
        
        // Suppose a square pixel image has length w. Then the maximum number of selected regions
        // that can be achieved is at most w*w/2 + 1. In this arragement, every selected pixel has four
        // deselected pixels - which forms a chess board pattern. The number of edges is at most
        // 2*w*w + 4 (which occurs when w is odd). This gives a worst case complexity of the algorithm
        // for square pixel images, ignoring the algorithmic complexity of underlying data structures,
        // to be (2*w*w + 4) * (w*w/2 + 1).
        // If we instead count based on the number of pixels n, then w*w = n, and we have a decent
        // algorithm: (2*n + 4)(n/2 + 1) = (n*n + 2*n + 2*n + 4) = (n*n + 4*n + 4).
        
        for var edge in edges {
            // Repeatedly add edges into lineSegments...
            // Find a line segment that this edge can be inserted into.
            
            var firstLineSegment: (Int, [Edge])? = nil
            var secondLineSegment: (Int, [Edge])? = nil
            
            for (i, l) in lineSegments.enumerated() {
                if l.first!.start == edge.start || l.first!.start == edge.end
                    || l.last!.start == edge.start || l.last!.end == edge.end {
                    if firstLineSegment == nil {
                        firstLineSegment = (i, l)
                    } else if secondLineSegment == nil {
                        secondLineSegment = (i, l)
                    } else {
                        fatalError("this should never occur because the border cannot intersect in"
                                   + "three places.")

                    }
                }
            }
            
            if let (firstIndex, firstLineSegment) = firstLineSegment,
               let (secondIndex, secondLineSegment) = secondLineSegment {
                // Under this branch the edge in consideration matched multiple line segments. This
                // means that they need to be connected together to form a single connected line
                // segment.
                // The orders are either firstLineSegment <-> edge <-> secondLineSegment,
                // or secondLineSegment <-> edge <-> firstLineSegment. If edge was on the outside,
                // then it would have only matched one lineSegment, and hence this branch would not
                // execute.
                
                let lineSegment: [Edge]
                
                if firstLineSegment.last!.end == edge.start && edge.end == secondLineSegment.first!.start {
                    lineSegment = firstLineSegment + [edge] + secondLineSegment
                } else if firstLineSegment.last!.end == edge.end && edge.end == secondLineSegment.first!.start {
                    swap(&edge.start, &edge.end)
                    lineSegment = firstLineSegment + [edge] + secondLineSegment
                } else if secondLineSegment.last!.end == edge.start && edge.end == firstLineSegment.first!.start {
                    lineSegment = secondLineSegment + [edge] + firstLineSegment
                } else if secondLineSegment.last!.end == edge.end && edge.start == firstLineSegment.first!.start {
                    swap(&edge.start, &edge.end)
                    lineSegment = secondLineSegment + [edge] + firstLineSegment
                } else {
                    fatalError("The edge does not somehow connect firstLineSegment and secondLineSegment.")
                }
                
                if firstIndex > secondIndex {
                    lineSegments.remove(at: firstIndex)
                    lineSegments.remove(at: secondIndex)
                } else if secondIndex > firstIndex {
                    lineSegments.remove(at: secondIndex)
                    lineSegments.remove(at: firstIndex)
                } else {
                    fatalError()
                }
                lineSegments.append(lineSegment)
                
            } else if let (index, lineSegment) = firstLineSegment {
                var lineSegment = lineSegment
                if lineSegment.first!.start == edge.end {
                    lineSegment.insert(edge, at: 0)
                } else if lineSegment.first!.start == edge.start {
                    swap(&edge.start, &edge.end)
                    lineSegment.insert(edge, at: 0)
                } else if lineSegment.last!.end ==  edge.start {
                    lineSegment.append(edge)
                } else if lineSegment.last!.end == edge.end {
                    swap(&edge.start, &edge.end)
                    lineSegment.append(edge)
                }
                
                // No other cases need to be considered because the above maintains the invariant
                // that given any consecutive pair of edges a, b from a line segment, a.end == b.start.
                // Knowing this and that there cannot be any three way intersections for a border
                // imply that no other cases need to be checked.
                
                lineSegments[index] = lineSegment
            } else {
                lineSegments.append([edge])
            }
        }
        
        // Convert the line segments into paths that can be drawn.
        
        let path = CGMutablePath()
        
        for lineSegment in lineSegments {
            // Each line segment should actually be closed at this point.
            assert(lineSegment.first!.start == lineSegment.last!.end)
            let points = lineSegment.map { CGPoint(x: $0.start.x, y: $0.end.y) }
            path.addLines(between: points)
            path.closeSubpath()
        }
        
        return path
    }
}
