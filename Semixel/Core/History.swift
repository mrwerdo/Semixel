//
//  History.swift
//  Semixel
//
//  Created by Andrew Thompson on 18/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

// History is stored as a tree of changes from a base image. The head of the history is the
// current state of the document. There can be multiple heads if there are different versions of the
// file. We might allow the user to navigate other history states. Who knows? So this means that
// all of the history is stored, so it can be played back to the user.
// A change can go forwards and backwards, meaning that it can be used for both undoing and redoing
// the change. The data stored for a change depends on its type. If it's a shape tool, then it stores
// a set of points, old colour, and new colour. If it's a transformation then it stores the reverse
// operation with enough data to undo the transformation.

protocol Operation: Codable {
    typealias Image = PixelImage<SemanticPixel>
    
    // Assumes that `image` is equal to the image before this operation was applied.
    func undo(_ image: inout Image)
    // Assumes that `image` is equal to the image before this operation was applied.
    func redo(_ image: inout Image)
    
    static var type: String { get }
}

struct AnyOperation: Codable, Operation {
    
    enum Keys: CodingKey {
        case type
        case operation
    }
    
    var operation: Operation
    
    func undo(_ image: inout Image) {
        operation.undo(&image)
    }
    
    func redo(_ image: inout Image) {
        operation.redo(&image)
    }
    
    static var type: String {
        return String(describing: Swift.type(of: AnyOperation.self))
    }
    
    init(_ operation: Operation) {
        self.operation = operation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case Ops.Transformation.type:
            operation = try container.decode(Ops.Transformation.self, forKey: .operation)
        case Ops.Assignment.type:
            operation = try container.decode(Ops.Assignment.self, forKey: .operation)
        default:
            throw LoadingError(description: "Unknown type: \(type), or type not implemented.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container  = encoder.container(keyedBy: Keys.self)
        let dynamicType = Swift.type(of: operation)
        print("Dynamic type is: \(dynamicType)")
        if let transformation = operation as? Ops.Transformation {
            try container.encode(dynamicType.type, forKey: .type)
            try container.encode(transformation, forKey: .operation)
        } else if let assignment = operation as? Ops.Assignment {
            try container.encode(dynamicType.type, forKey: .type)
            try container.encode(assignment, forKey: .operation)
        } else if let op = operation as? AnyOperation {
            try op.encode(to: encoder)
        } else {
            throw LoadingError(description: "Unimplemented type.")
        }
    }
}

class HistoryNode: Codable {
    var previous: HistoryNode?
    var next: [HistoryNode] = []
    var operation: AnyOperation
    
    init(_ operation: Operation, previous: HistoryNode?) {
        self.operation = AnyOperation(operation)
        self.previous = previous
    }
}

class History: Codable {
    private var tree: HistoryNode?
    var head: HistoryNode?
    
    init() {
        tree = nil
    }
    
    func record<Op>(_ operation: Op) where Op: Operation {
        if let head = head {
            head.next.append(HistoryNode(operation, previous: head))
            self.head = head.next.last
        } else {
            tree = HistoryNode(operation, previous: nil)
            head = tree
        }
    }
}

enum Ops {
    struct Transformation: Operation {
        typealias Image = PixelImage<SemanticPixel>
        typealias Pixel = SemanticPixel
        
        static var type: String { String(describing: Transformation.self) }
        
        var points: [Point2D]
        var offset: Point2D
        var overWrittenPixels: [Pixel]
        var selectedPixels: [Pixel]
        var backgroundColor: Pixel
        var horizontalFlip: Bool
        var verticalFlip: Bool
        var flipRect: Rect2D
        
        func undo(_ image: inout Image) {
            for (point, color) in zip(points, selectedPixels) {
                image[point] = color
            }
            
            for (point, color) in zip(points, overWrittenPixels) where image.isValid(point + offset) {
                image[point + offset] = color
            }
        }
        
        func redo(_ image: inout Image) {
            var region = SelectedRegion(size: image.size, default: false)
            region.update(points: points, mode: .select)
            image = image.transform(selection: region,
                                    horizontalFlip: horizontalFlip,
                                    verticalFlip: verticalFlip,
                                    offset: offset,
                                    background: backgroundColor)
        }
    }
    
    struct Assignment: Operation {
        typealias Image = PixelImage<SemanticPixel>
        typealias Pixel = SemanticPixel
        
        static var type: String { String(describing: Swift.type(of: self)) }
        
        var points: [Point2D]
        var oldColors: [Pixel]
        var newColors: [Pixel]
        
        func undo(_ image: inout Image) {
            for (point, color) in zip(points, oldColors) {
                image[point] = color
            }
        }
        
        func redo(_ image: inout Image) {
            for (point, color) in zip(points, newColors) {
                image[point] = color
            }
        }
    }
}
