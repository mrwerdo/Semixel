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


struct PixelImage {
    struct RGBA: Equatable {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
        
        static var white: RGBA {
            return RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        static var clear: RGBA {
            return RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
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
        
        init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
            self.init(
                red: CGFloat(red)/255,
                green: CGFloat(green)/255,
                blue: CGFloat(blue)/255,
                alpha: CGFloat(alpha)/255)
        }
    }
    
    var buffer: [RGBA]
    private(set) var size: Size2D
    
    init(copy: PixelImage) {
        buffer = copy.buffer
        size = copy.size
    }
    
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
        
        var img = PixelImage(copy: self)
        
        for y in a.y...b.y {
            for x in a.x...b.x {
                img[x, y] = .white
            }
        }
        
        for y in a.y...b.y {
            for x in a.x...b.x {
                img[x + offset.x, y + offset.y] = self[x, y]
            }
        }
        
        return img
    }

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
        
        var img = PixelImage(copy: self)
        
        for point in points {
            img[point] = color
        }
        
        return img
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
        var img = PixelImage(copy: self)
        
        for point in path {
            img[point] = color
        }
        
        return img
    }
}

extension PixelImage {
    
    init(uiImage: UIImage) {
        self.init(width: uiImage.width, height: uiImage.height)
        uiImage.enumeratePixels { (x, y, color) in
            buffer[y * size.width + x] = color
        }
    }
    
    func write(to url: URL) throws {
        
        struct WritingError: Error, CustomStringConvertible {
            var description: String
        }
        
        var buffer = [UInt8](repeating: 0, count: size.width * size.height * 4)
        
        for y in 0..<size.height {
            for x in 0..<size.width {
                let c = self[x, y]
                buffer[4 * (y * size.width + x) + 0] = UInt8((c.red * 255).rounded())
                buffer[4 * (y * size.width + x) + 1] = UInt8((c.green * 255).rounded())
                buffer[4 * (y * size.width + x) + 2] = UInt8((c.blue * 255).rounded())
                buffer[4 * (y * size.width + x) + 3] = UInt8((c.alpha * 255).rounded())
            }
        }
        
        guard let provider = CGDataProvider(data: Data(bytes: buffer, count: buffer.count) as CFData) else {
            throw WritingError(description: "Could not create data provider.")
        }
            
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bpc = 8 * MemoryLayout<UInt8>.stride
        let bpp = 8 * MemoryLayout<UInt8>.stride * 4
        let bpr = size.width * 4
        
        guard let img = CGImage(width: size.width,
                                height: size.height,
                                bitsPerComponent: bpc,
                                bitsPerPixel: bpp,
                                bytesPerRow: bpr,
                                space: colorSpace,
                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                provider: provider,
                                decode: nil,
                                shouldInterpolate: false, intent: .defaultIntent) else {
            throw WritingError(description: "Could not create CGImage.")
        }
        
        guard let data = UIImage(cgImage: img).pngData() else {
            throw WritingError(description: "Could not encode to png data.")
        }
        
        try data.write(to: url)
    }
}

extension UIImage {
    
    var width: Int {
        return cgImage?.width ?? 0
    }

    var height: Int {
        return cgImage?.height ?? 0
    }

    private func extractPixel(_ componentLayout: CGBitmapInfo.ComponentLayout, _ dataPtr: UnsafePointer<UInt8>, _ pixelOffset: Int, _ cgImage: CGImage) -> PixelImage.RGBA {
        if componentLayout.count == 4 {
            let index: (r: Int, g: Int, b: Int, a: Int)
            
            switch componentLayout {
            case .bgra:
                index = (2, 1, 0, 3)
            case .abgr:
                index = (3, 2, 1, 0)
            case .argb:
                index = (1, 2, 3, 0)
            case .rgba:
                index = (0, 1, 2, 3)
            default:
                return .clear
            }
            
            var red = dataPtr[pixelOffset + index.r]
            var green = dataPtr[pixelOffset + index.g]
            var blue = dataPtr[pixelOffset + index.b]
            let alpha = dataPtr[pixelOffset + index.a]
            
            // If chroma components are premultiplied by alpha and the alpha is `0`,
            // keep the chroma components to their current values.
            if cgImage.bitmapInfo.chromaIsPremultipliedByAlpha && alpha != 0 {
                let invUnitAlpha = 255/CGFloat(alpha)
                red = UInt8((CGFloat(red)*invUnitAlpha).rounded())
                green = UInt8((CGFloat(green)*invUnitAlpha).rounded())
                blue = UInt8((CGFloat(blue)*invUnitAlpha).rounded())
            }
            
            return PixelImage.RGBA(red: red, green: green, blue: blue, alpha: alpha)
            
        } else if componentLayout.count == 3 {
            let index: (r: Int, g: Int, b: Int)
            
            switch componentLayout {
            case .bgr:
                index = (2, 1, 0)
            case .rgb:
                index = (0, 1, 2)
            default:
                return .clear
            }
            
            return PixelImage.RGBA(red: dataPtr[pixelOffset + index.r],
                                   green: dataPtr[pixelOffset + index.g],
                                   blue: dataPtr[pixelOffset + index.b],
                                   alpha: 255)
            
        } else {
            assertionFailure("Unsupported number of pixel components")
            return .clear
        }
    }
    
    func pixelColor(x: Int, y: Int) -> PixelImage.RGBA {
        assert(
            0..<width ~= x && 0..<height ~= y,
            "Pixel coordinates are out of bounds")

        guard
            let cgImage = cgImage,
            let data = cgImage.dataProvider?.data,
            let dataPtr = CFDataGetBytePtr(data),
            let colorSpaceModel = cgImage.colorSpace?.model,
            let componentLayout = cgImage.bitmapInfo.componentLayout
        else {
            assertionFailure("Could not get a pixel of an image")
            return .clear
        }

        assert(
            colorSpaceModel == .rgb,
            "The only supported color space model is RGB")
        assert(
            cgImage.bitsPerPixel == 32 || cgImage.bitsPerPixel == 24,
            "A pixel is expected to be either 4 or 3 bytes in size")

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel/8
        let pixelOffset = y*bytesPerRow + x*bytesPerPixel

        return extractPixel(componentLayout, dataPtr, pixelOffset, cgImage)
    }
    
    func enumeratePixels(_ closure: (_ x: Int, _ y: Int, _ color: PixelImage.RGBA) -> ()) {
        guard
            let cgImage = cgImage,
            let data = cgImage.dataProvider?.data,
            let dataPtr = CFDataGetBytePtr(data),
            let colorSpaceModel = cgImage.colorSpace?.model,
            let componentLayout = cgImage.bitmapInfo.componentLayout
        else {
            assertionFailure("Could not get a pixel of an image")
            return
        }

        assert(
            colorSpaceModel == .rgb,
            "The only supported color space model is RGB")
        assert(
            cgImage.bitsPerPixel == 32 || cgImage.bitsPerPixel == 24,
            "A pixel is expected to be either 4 or 3 bytes in size")

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel/8

        for y in 0..<width {
            for x in 0..<height {
                let pixelOffset = y*bytesPerRow + x*bytesPerPixel
                let color = extractPixel(componentLayout, dataPtr, pixelOffset, cgImage)
                closure(x, y, color)
            }
        }
    }

}

public extension CGBitmapInfo {

    enum ComponentLayout {

        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb

        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }

    }

    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)

        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }

    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }

}
