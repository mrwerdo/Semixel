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
        
        init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
        
        init?(_ color: Color) {
            red = 0; green = 0; blue = 0; alpha = 0
            guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return nil
            }
        }
    }
    
    var buffer: [RGBA]
    private(set) var size: Size2D
    
    init(width: Int, height: Int) {
        buffer = [RGBA](repeating: .white, count: width * height)
        size = Size2D(width: width, height: height)
    }
    
    func isValid(_ point: Point2D) -> Bool {
        return point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height
    }
    
    func floodSearch(at point: Point2D, isIncluded: (_ point: Point2D, _ color: RGBA) -> Bool) -> [Point2D] {
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
}

extension PixelImage {
    func moveRectangle(between p1: Point2D, and p2: Point2D, by offset: Point2D) -> PixelImage {
        let a = Point2D(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
        let b = Point2D(x: max(p1.x, p2.x), y: max(p1.y, p2.y))
        
        var img = self
        
        for y in a.y..<b.y {
            for x in a.x..<b.x {
                img[x, y] = .white
            }
        }
        
        for y in a.y..<b.y {
            for x in a.x..<b.x {
                img[x + offset.x, y + offset.y] = self[x, y]
            }
        }
        
        return img
    }
}

extension PixelImage {
    func drawEllipse(from p0: Point2D, to p1: Point2D, color: RGBA) -> PixelImage {
        
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
        
        var img = self
        
        for point in points {
            img[point] = color
        }
        
        return img
    }
}

extension PixelImage {
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
