//
//  PixelImage+UIImage.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import UIKit

struct WritingError: Error, CustomStringConvertible {
    var description: String
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
