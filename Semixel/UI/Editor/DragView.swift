//
//  DragView.swift
//  Semixel
//
//  Created by Andrew Thompson on 6/2/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import SwiftUI
import Geometry
import SemixelCore

struct DragView<Content: View>: View {
    var imageSize: Size2D
    var pixelSize: CGSize
    var translating: Bool
    
    var shapeStartPosition: Point2D?
    var shapeEndPosition: Point2D?
    
    @Binding var position: Point2D
    @Binding var speed: CGFloat
    @Binding var translation: Point2D
    
    @Binding var zoomFactor: CGFloat
    
    @Binding var __position: CGPoint
    @State var lastPosition: CGPoint = .zero
    @State var __translation: CGPoint = .zero
    @State var didSyncPosition: Bool = false
    @State var lastZoomFactor: CGFloat = 1.0
    
    var onDrag: (CGPoint) -> ()
    var content: Content
    
    private func updateTranslation(_ delta: CGPoint) {
        // Update `translation` ensuring that the selection rectangle defined by
        // `shapeStartPosition` and `shapeEndPosition` do not go outside of the bounds of the image.
        // Translation is measured in terms of pixels (i.e. CGFloats) while the image is measured
        // in terms of points (i.e. Ints)
        
        if !translating {
            guard let a = shapeStartPosition, let b = shapeEndPosition else {
                return
            }
            
            let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
            let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
            
            __translation.x = max(CGFloat(-p1.x) * pixelSize.width,
                                  min(__translation.x + delta.x,
                                      CGFloat(imageSize.width - p2.x) * pixelSize.width))
            __translation.y = max(CGFloat(-p1.y) * pixelSize.height,
                                  min(__translation.y + delta.y,
                                      CGFloat(imageSize.height - p2.y) * pixelSize.height))
            
            translation = convertToInteger(__translation)
        } else {
            __translation.x += delta.x
            __translation.y += delta.y
            translation = convertToInteger(__translation)
        }
    }
    
    private var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: speed * (event.translation.width - lastPosition.x),
                                    y: speed * (event.translation.height - lastPosition.y))
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
                var newPosition = CGPoint(x: __position.x + delta.x, y: __position.y + delta.y)
                
                newPosition.x = max(-size.width/2, min(newPosition.x, size.width/2 - pixelSize.width))
                newPosition.y = max(-size.height/2, min(newPosition.y, size.height/2 - pixelSize.height))
                
                self.__position = newPosition
                
                updatePosition()
                updateTranslation(delta)
                self.onDrag(delta)
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }
    
    private var zoomGesture: some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.001)
            .onChanged { value in
                zoomFactor *= value / lastZoomFactor
                zoomFactor = max(1, zoomFactor)
                lastZoomFactor = value
            }
            .onEnded { value in
                lastZoomFactor = 1.0
            }
    }
    
    private func updatePosition() {
        let p = convertToInteger(CGPoint(x: __position.x / zoomFactor, y: __position.y / zoomFactor)) + Point2D(x: imageSize.width, y: imageSize.height)/2
        if 0..<imageSize.width ~= p.x && 0..<imageSize.height ~= p.y {
            position = p
        }
    }
    
    private func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
    
    private var size: CGSize {
        CGSize(width: pixelSize.width * CGFloat(imageSize.width),
               height: pixelSize.height * CGFloat(imageSize.height))
    }
    
    var body: some View {
        content
            .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
            .gesture(drag)
            .onAppear(perform: {
                if !didSyncPosition {
                    updatePosition()
                }
            })
            .gesture(zoomGesture)
    }
}
