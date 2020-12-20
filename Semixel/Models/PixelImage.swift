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

struct RGBA: Equatable, ColorTypeProtocol {
    func convertToCGColor() -> CGColor {
        var components: [CGFloat] = [
            red,
            green,
            blue,
            alpha
        ]
        return CGColor(colorSpace: RGBA.cgColorSpace, components: &components)!
    }
    
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

struct PixelImage<ColorType: ColorTypeProtocol> {
    
    var buffer: [ColorType]
    private(set) var size: Size2D
    
    init(copy: PixelImage) {
        buffer = copy.buffer
        size = copy.size
    }
    
    init(width: Int, height: Int) {
        buffer = [ColorType](repeating: .clear, count: width * height)
        size = Size2D(width: width, height: height)
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

extension PixelImage {
    func moveRectangle(between p1: Point2D, and p2: Point2D, by offset: Point2D) -> PixelImage {
        let a = Point2D(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
        let b = Point2D(x: max(p1.x, p2.x), y: max(p1.y, p2.y))
        
        var img = PixelImage(copy: self)
        
        for y in a.y...b.y {
            for x in a.x...b.x {
                img[x, y] = .clear
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


extension RGBA {
    
//    {"Flickr Pink":"f72585",
//    "Byzantine":"b5179e",
//    "Purple":"7209b7",
//    "Purple 2":"560bad",
//    "Trypan Blue":"480ca8",
//    "Trypan Blue 2":"3a0ca3",
//    "Persian Blue":"3f37c9",
//    "Ultramarine Blue":"4361ee",
//    "Dodger Blue":"4895ef",
//    "Vivid Sky Blue":"4cc9f0"}
    
    /* Array */

//    /* Object */
//    {"Xiketic":"03071e","Dark Sienna":"370617","Rosewood":"6a040f","Dark Red":"9d0208","Rosso Corsa":"d00000","Vermilion":"dc2f02","Persimmon":"e85d04","Carrot Orange":"f48c06","Orange Web":"faa307","Selective Yellow":"ffba08"}
    
    static let defaultColorPalette: [RGBA] = [
        "f72585", "b5179e", "7209b7", "560bad", "480ca8",
        "3a0ca3", "3f37c9", "4361ee", "4895ef", "4cc9f0",
        // Second one
        "03071e","370617","6a040f","9d0208","d00000","dc2f02","e85d04","f48c06","faa307","ffba08",
    ].compactMap(RGBA.init(hex:))
    
    init?(hex: String) {
        if hex.count == 6, let value = Int(hex, radix: 16) {
            red = CGFloat((value & 0xFF0000) >> 16) / 0xFF
            green = CGFloat((value & 0x00FF00) >> 8) / 0xFF
            blue = CGFloat(value & 0xFF) / 0xFF
            alpha = 1.0
        } else if hex.count == 3, let value = Int(hex, radix: 16) {
            red = CGFloat((value & 0xF00) >> 8) / 0xFF
            green = CGFloat((value & 0x0F0) >> 4) / 0xFF
            blue = CGFloat(value & 0xF) / 0xFF
            alpha = 1.0
        } else {
            return nil
        }
    }
}

struct WritingError: Error, CustomStringConvertible {
    var description: String
}

extension RGBA {
    static var cgColorSpace: CGColorSpace {
        get {
            return CGColorSpaceCreateDeviceRGB()
        }
    }
}

extension PixelImage {
    
//    init(uiImage: UIImage) {
//        self.init(width: uiImage.width, height: uiImage.height)
//        uiImage.enumeratePixels { (x, y, color) in
//            buffer[y * size.width + x] = color
//        }
//    }
    
    func write(to url: URL) throws {
        guard let img = convertToCGImage() else {
            throw WritingError(description: "Could not create CGImage.")
        }
        
        guard let data = UIImage(cgImage: img).pngData() else {
            throw WritingError(description: "Could not encode to png data.")
        }
        
        try data.write(to: url)
    }
    
    func convertToCGImage() -> CGImage? {
        var buffer = [UInt8](repeating: 0, count: size.width * size.height * 4)
        
        let colorSpace: CGColorSpace = ColorType.cgColorSpace
        
        for y in 0..<size.height {
            for x in 0..<size.width {
                guard let components = self[x, y].convertToCGColor().components else {
                    fatalError("The converted color must have accessible components.")
                }
                
                let n = colorSpace.numberOfComponents + 1
                for (i, c) in components.enumerated() {
                    buffer[n * (y * size.width + x) + i] = UInt8((c * 255).rounded())
                }
            }
        }
        
        guard let provider = CGDataProvider(data: Data(bytes: buffer, count: buffer.count) as CFData) else {
            return nil
        }
        
        let bpc = 8 * MemoryLayout<UInt8>.stride
        let bpp = 8 * MemoryLayout<UInt8>.stride * 4
        let bpr = size.width * 4
        
        return CGImage(width: size.width,
                       height: size.height,
                       bitsPerComponent: bpc,
                       bitsPerPixel: bpp,
                       bytesPerRow: bpr,
                       space: colorSpace,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)
    }
}

extension UIImage {
    
    var width: Int {
        return cgImage?.width ?? 0
    }

    var height: Int {
        return cgImage?.height ?? 0
    }

    private func extractPixel(_ componentLayout: CGBitmapInfo.ComponentLayout, _ dataPtr: UnsafePointer<UInt8>, _ pixelOffset: Int, _ cgImage: CGImage) -> RGBA {
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
            
            return RGBA(red: red, green: green, blue: blue, alpha: alpha)
            
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
            
            return RGBA(red: dataPtr[pixelOffset + index.r],
                        green: dataPtr[pixelOffset + index.g],
                        blue: dataPtr[pixelOffset + index.b],
                        alpha: 255)
            
        } else {
            assertionFailure("Unsupported number of pixel components")
            return .clear
        }
    }
    
    func pixelColor(x: Int, y: Int) -> RGBA {
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
    
    func enumeratePixels(_ closure: (_ x: Int, _ y: Int, _ color: RGBA) -> ()) {
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
