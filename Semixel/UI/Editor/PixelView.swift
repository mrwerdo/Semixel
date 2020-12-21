//
//  PixelView.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelView: View {
    @EnvironmentObject var artwork: Artwork
    @State var colors: [SemanticColor] = RGBA
        .defaultColorPalette
        .enumerated()
        .map {
            SemanticColor(label: "\($0)", color: $1)
        }
    
    var selectedColor: RGBA {
        return selectedObject.color
    }
    
    @State var selectedObject = SemanticColor(label: "0", color: RGBA.defaultColorPalette.first ?? RGBA.white)
    @State var statusText: String = ""
    
    var size: CGSize {
        return CGSize(width: 32 * 12, height: 32 * 12)
    }
    
    var pixelSize: CGSize {
        return CGSize(width: 12, height: 12)
    }
    
    @State var fullScreenDragEnabled: Bool = false
    @State var tool: ToolType? = nil
    @State var position: CGPoint = .zero
    @State var lastPosition: CGPoint = .zero
    @State var speed: CGFloat = 0.8
    
    @State var shapeStartPosition: Point2D?
    @State var shapeEndPosition: Point2D?
    @State var translation: CGPoint = .zero

    var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: speed * (event.translation.width - lastPosition.x),
                                    y: speed * (event.translation.height - lastPosition.y))
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
                var newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                
                newPosition.x = max(-size.width/2, min(newPosition.x, size.width/2 - 12))
                newPosition.y = max(-size.height/2, min(newPosition.y, size.height/2 - 12))
                
                self.position = newPosition
                onDrag(delta)
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }

    
    var pencilGridPosition: Point2D? {
        let size = artwork.pixelImage.size
        let p = convertToInteger(position) + Point2D(x: size.width, y: size.height)/2
        
        if !isValid(p) {
            return nil
        }
        
        return p
    }
    
    func isValid(_ p: Point2D) -> Bool {
        let size = artwork.pixelImage.size
        return !(p.x < 0 || p.y < 0 || p.x >= size.width || p.y >= size.height)
    }
    
    func translatedShape(p1: Point2D, p2: Point2D) -> PixelImage<RGBA> {
        let p3 = convertToInteger(translation)
        let a = p1 + p3
        let b = p2 + p3
        
        if isValid(a) && isValid(b) {
            return artwork.pixelImage.drawEllipse(from: a, to: b, color: selectedColor)
        } else {
            return artwork.pixelImage
        }
    }
    
    var composedImage: PixelImage<RGBA> {
        if let p1 = shapeStartPosition, tool == .shape {
            // Render shape on top of the image.
            
            if let p2 = shapeEndPosition {
                return translatedShape(p1: p1, p2: p2)
            } else if let p2 = pencilGridPosition {
                return artwork.pixelImage.drawEllipse(from: p1, to: p2, color: selectedColor)
            } else {
                print("warning: could not get pencil position!")
                return artwork.pixelImage
            }
            
            // draw line in this case...
//            return image.drawLine(from: p1, to: p2, color: c)
        } else if tool == .selection, let p1 = shapeStartPosition, let p2 = shapeEndPosition {
            // Grab the pixels in the rectangle between p1 and p2, draw each one translated by p3.
            return artwork.pixelImage.moveRectangle(between: p1, and: p2, by: convertToInteger(translation))
        } else {
            return artwork.pixelImage
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            OverlayView(pixelSize: pixelSize,
                        image: composedImage,
                        position: position,
                        shapeStartPosition: shapeStartPosition,
                        shapeEndPosition: shapeEndPosition,
                        translation: translation)
                .frame(maxWidth: size.width, maxHeight: size.height)
                .gesture(drag)
                .padding()
            Spacer()
            Text(statusText)
            ZStack {
                HStack {
                    Spacer()
                    HStack {
                        VStack {
                            PencilState.create($tool) {
                                reset()
                                statusText = "Pencil selected."
                                if let p = pencilGridPosition {
                                    applyPencil(p)
                                }
                            }
                            ShapeState.create($tool,
                                              resizing: resizing(statusText: "Shape tool."),
                                              translating: translating,
                                              complete: completed { (p1, p2, offset) in
                                    artwork.pixelImage = translatedShape(p1: p1, p2: p2)
                            })
                            UndoState.create($tool) {
                                statusText = "Undone"
                            }
                        }
                        VStack {
                            PaintBucketState.create($tool) {
                                statusText = "Applied paint bucket."
                                if let p = pencilGridPosition {
                                    let oldColor = artwork.pixelImage[p]
                                    let points = artwork.pixelImage.floodSearch(at: p) { (_, c) -> Bool in c == oldColor }
                                    for point in points {
                                        artwork.pixelImage[point] = selectedColor
                                    }
                                }
                            }
                            
                            SelectionState.create($tool,
                                                  resizing: resizing(statusText: "Selection tool."),
                                                  translating: translating,
                                                  complete: completed { (p1, p2, offset) in
                                                    artwork.pixelImage = artwork.pixelImage.moveRectangle(between: p1,
                                                                                                          and: p2,
                                                                                                          by: offset)
                                                  })
                            RedoState.create($tool) {
                                statusText = "Redone"
                            }
                        }
                    }.padding([.top, .bottom, .leading])
                    ColorPalette(colors: $colors, selectedColor: $selectedObject)
                        .padding([.top, .bottom, .trailing])
                    Spacer()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .ignoresSafeArea())
        }
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarTitle(artwork.name, displayMode: .inline)
    }
    
    func resizing(statusText: String) -> () -> () {
        return {
            reset()
            self.statusText = statusText
            if let point = pencilGridPosition {
                shapeStartPosition = point
            }
        }
    }
    
    func translating() {
        statusText = "Translating..."
        if shapeStartPosition != nil {
            translation = .zero
            shapeEndPosition = pencilGridPosition
            let p = convertToInteger(position)
            position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
        }
    }
    
    func completed(callback: @escaping (_ p1: Point2D, _ p2: Point2D, _ offset: Point2D) -> ()) -> () -> () {
        return {
            statusText = "Complete."
            if let p2 = shapeEndPosition {
                if let p1 = shapeStartPosition {
                    callback(p1, p2, convertToInteger(translation))
                }
                shapeEndPosition = nil
                shapeStartPosition = nil
            }
        }
    }
    
    func onDrag(_ delta: CGPoint) {
        if let p = pencilGridPosition {
            if tool == nil {
                statusText = ("(x: \(p.x), y: \(p.y))")
            }
            if tool == .pencil {
                applyPencil(p)
            }
        }
        updateTranslation(delta)
    }
    
    func updateTranslation(_ delta: CGPoint) {
        // Update `translation` ensuring that the selection rectangle defined by
        // `shapeStartPosition` and `shapeEndPosition` do not go outside of the bounds of the image.
        // Translation is measured in terms of pixels (i.e. CGFloats) while the image is measured
        // in terms of points (i.e. Ints)
        
        guard let a = shapeStartPosition, let b = shapeEndPosition else {
            return
        }
        
        let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
        let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
        
        translation.x = max(CGFloat(-p1.x) * pixelSize.width,
                            min(translation.x + delta.x,
                                CGFloat(artwork.pixelImage.size.width - p2.x) * pixelSize.width))
        translation.y = max(CGFloat(-p1.y) * pixelSize.height,
                            min(translation.y + delta.y,
                                CGFloat(artwork.pixelImage.size.height - p2.y) * pixelSize.height))
    }
    
    func reset() {
        shapeStartPosition = nil
        shapeEndPosition = nil
        translation = .zero
    }
    
    func applyPencil(_ p: Point2D) {
        artwork.pixelImage[p] = selectedColor
    }

    func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
}

