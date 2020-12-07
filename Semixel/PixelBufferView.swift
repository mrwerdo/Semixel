//
//  PixelBufferView.swift
//  Semixel
//
//  Created by Andrew Thompson on 31/10/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelBufferView: UIViewRepresentable {
    
    var pixelSize: CGSize
    var image: PixelImage
        
    var size: CGSize {
        return CGSize(width: CGFloat(image.size.width) * pixelSize.width,
                      height: CGFloat(image.size.height) * pixelSize.height)
    }
    
    init(pixelSize: CGSize, image: PixelImage) {
        self.pixelSize = pixelSize
        self.image = image
    }
    
    func updateUIView(_ view: BufferView, context: Context) {
        view.image = image
        view.pixelSize = pixelSize
    }
    
    func makeUIView(context: Context) -> BufferView {
        return BufferView(image: image, pixelSize: pixelSize, frame: CGRect(origin: .zero, size: pixelSize))
    }
    
    func makeCoordinator() -> () {
        return ()
    }
}

struct PixelImage {
    struct RGBA: Equatable {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
        
        static var white: RGBA {
            return RGBA(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
    var buffer: [RGBA]
    private(set) var size: Size2D
    
    init(width: Int, height: Int) {
        buffer = [RGBA](repeating: .white, count: width * height)
        size = Size2D(width: width, height: height)
        
        for y in 0..<size.height {
            for x in 0..<size.width {
                
                let index = y * size.width + x
                var color = RGBA(red: 0, green: 0, blue: 0, alpha: 1)
                if index % 3 == 0 {
                    color.red = 1
                } else if index % 3 == 1 {
                    color.green = 1
                } else if index % 3 == 2 {
                    color.blue = 1
                }
                
                buffer[index] = color
            }
        }
    }
    
    func isValid(_ point: Point2D) -> Bool {
        return point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height
    }
    
    func floodSearch(at x: Int, y: Int, isIncluded: (_ point: Point2D, _ color: RGBA) -> Bool) -> [Point2D] {
        var unvisitedPoints: [Point2D] = [Point2D(x: x, y: y)]
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
    
    subscript(x: Int, y: Int) -> RGBA {
        get {
            return buffer[y * size.width + x]
        }
        
        set {
            buffer[y * size.width + x] = newValue
        }
    }
    
    subscript(point: Point2D) -> RGBA {
        get {
            return self[point.x, point.y]
        }
        
        set {
            self[point.x, point.y] = newValue
        }
    }
    
    func drawLine(from p1: Point2D, to p2: Point2D, color: RGBA) -> PixelImage {
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
        var img = self
        
        for point in path {
            img[point] = color
        }
        
        return img
    }
}

class BufferView: UIView {
    
    var pixelSize: CGSize {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var image: PixelImage {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(image: PixelImage, pixelSize: CGSize, frame: CGRect) {
        self.image = image
        self.pixelSize = pixelSize
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw the buffer in the context scaling to the desired size.
        for y in 0..<image.size.height {
            for x in 0..<image.size.width {
                let rect = CGRect(x: pixelSize.width * CGFloat(x),
                                  y: pixelSize.height * CGFloat(y),
                                  width: pixelSize.width,
                                  height: pixelSize.height)
                let color = image.buffer[image.size.width * y + x]
                context.setFillColor(red: color.red,
                                     green: color.green,
                                     blue: color.blue,
                                     alpha: color.alpha)
                context.fill(rect)
            }
        }
    }
}
