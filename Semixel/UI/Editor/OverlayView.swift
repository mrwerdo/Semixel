//
//  OverlayView.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct OverlayView: View {
    
    var pixelSize: CGSize
    var image: PixelImage<SemanticPixel<RGBA>>
    var position: CGPoint
    
    var shapeStartPosition: Point2D?
    var shapeEndPosition: Point2D?
    var translation: CGPoint
    
    private var pencilPosition: CGPoint {
        let x = round(position.x / pixelSize.width)
        let y = round(position.y / pixelSize.height)
        return CGPoint(x: (x + 0.5) * pixelSize.width, y: (y + 0.5) * pixelSize.height)
    }
    
    func selectionView(p1 a: Point2D, p2 b: Point2D, offset: Point2D) -> some View {
        let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
        let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
        
        let x = CGFloat(p1.x + p2.x - image.size.width + 2 * offset.x)/2 * pixelSize.width
        let y = CGFloat(p1.y + p2.y - image.size.height + 2 * offset.y)/2 * pixelSize.height
        
        let w = CGFloat(abs(p2.x - p1.x)) * pixelSize.width
        let h = CGFloat(abs(p2.y - p1.y)) * pixelSize.height
        
        return Rectangle()
            .opacity(0.0)
            .frame(width: w, height: h, alignment: .center)
            .border(Color(.gray), width: 2)
            .offset(x: x, y: y)
    }
    
    func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
    
    var pencilGridPosition: Point2D? {
        let size = image.size
        let p = convertToInteger(position) + Point2D(x: size.width, y: size.height)/2
        
        if p.x < 0 || p.y < 0 || p.x >= size.width || p.y >= size.height {
            return nil
        }
        
        return p
    }
    
    private var normalImage: PixelImage<RGBA> {
        let buffer = image.buffer.map { $0.color }
        return PixelImage(size: image.size, buffer: buffer)
    }
    
    var body: some View {
        ZStack {
            PixelBufferView(pixelSize: pixelSize, image: normalImage)
            PixelGridImage(horizontalSpacing: pixelSize.width, verticalSpacing: pixelSize.height)
            
            if let p1 = shapeStartPosition {
                if let p2 = shapeEndPosition {
                    selectionView(p1: p1, p2: p2, offset: convertToInteger(translation))
                } else if let p2 = pencilGridPosition {
                    selectionView(p1: p1, p2: p2, offset: .zero)
                }
            }
            
            Rectangle()
                .opacity(0.0)
                .frame(width: pixelSize.width, height: pixelSize.height , alignment: .center)
                .border(Color(.systemRed), width: 2)
                .offset(x: pencilPosition.x, y: pencilPosition.y)
            Image(systemName: "pencil")
                .renderingMode(Image.TemplateRenderingMode.template)
                .foregroundColor(Color(.white))
                .offset(x: position.x + pixelSize.width, y: position.y)
        }
    }
}
