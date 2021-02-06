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
    var image: PixelImage<RGBA>
    var position: Point2D
    
    var showGrid: Bool
    var showBoundingRectangle: Bool
    var shapeStartPosition: Point2D?
    var shapeEndPosition: Point2D?
    @Binding var selectedRegion: SelectedRegion?
    var translating: Bool
    var translation: Point2D
    
    @Binding var __position: CGPoint
    
    private var pencilPosition: CGPoint {
        let x = round(__position.x / pixelSize.width)
        let y = round(__position.y / pixelSize.height)
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
    
    private var size: CGSize {
        CGSize(width: pixelSize.width * CGFloat(image.size.width),
               height: pixelSize.height * CGFloat(image.size.height))
    }
    
    var body: some View {
        ZStack {
            PixelBufferView(pixelSize: pixelSize, image: image)
            if showGrid {
                PixelGridImageView(horizontalSpacing: pixelSize.width, verticalSpacing: pixelSize.height)
            }
            
            if let path = selectedRegion?.boundingPath {
                if translating {
                    Path(path)
                        .transform(CGAffineTransform(scaleX: pixelSize.width, y: pixelSize.height))
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5], dashPhase: 0))
                        .foregroundColor(Color(.lightGray))
                        .offset(x: CGFloat(translation.x) * pixelSize.width, y: CGFloat(translation.y) * pixelSize.height)
                } else {
                    Path(path)
                        .transform(CGAffineTransform(scaleX: pixelSize.width, y: pixelSize.height))
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5], dashPhase: 0))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            if showBoundingRectangle, let p1 = shapeStartPosition {
                if let p2 = shapeEndPosition {
                    selectionView(p1: p1, p2: p2, offset: translation)
                } else {
                    selectionView(p1: p1, p2: position, offset: .zero)
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
                .offset(x: __position.x + pixelSize.width, y: __position.y)
        }
        .frame(width: size.width, height: size.height)
    }
}
