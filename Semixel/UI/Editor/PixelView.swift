//
//  PixelView.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelView: View {
    
    typealias SemanticImage = PixelImage<SemanticPixel<RGBA>>
    
    @EnvironmentObject var artwork: SemanticArtwork
    
    @State var _selectedColor: IdentifiableColor = IdentifiableColor(color: .white, id: UUID())
    @State var selectedSemanticIdentifierId: Int = 0
    @State var statusText: String = ""
    
    @State var fullScreenDragEnabled: Bool = false
    @State var tool: ToolType? = nil
    @State var position: Point2D = .zero
    @State var speed: CGFloat = 0.8
    
    @State var shapeStartPosition: Point2D?
    @State var shapeEndPosition: Point2D?
    @State var translation: Point2D = .zero
    
    var pixelSize: CGSize {
        return CGSize(width: 12, height: 12)
    }
    
    var selectedColor: Binding<IdentifiableColor> {
        Binding<IdentifiableColor> {
            _selectedColor
        } set: { newValue in
            if let index = selectedColorPalette.colors.firstIndex(where: { $0.id == newValue.id }) {
                selectedColorPalette.colors[index].color = newValue.color
            }
            _selectedColor = newValue
        }
    }
    
    var selectedColorPalette: ColorPalette {
        let identifier = artwork.root.find(matching: selectedSemanticIdentifierId) ?? artwork.root
        if let palette = artwork.colorPalettes[identifier.id] {
            return palette
        } else {
            let palette = ColorPalette(colors: [IdentifiableColor(color: .white, id: UUID())])
            artwork.colorPalettes[identifier.id] = palette
            return palette
        }
    }
    
    func translatedShape(p1: Point2D, p2: Point2D) -> SemanticImage {
        let a = p1 + translation
        let b = p2 + translation
        
        if artwork.image.isValid(a) && artwork.image.isValid(b) {
            return artwork.image.drawEllipse(from: a, to: b, color: getCurrentSemanticPixel())
        } else {
            return artwork.image
        }
    }
    
    var composedImage: SemanticImage {
        if let p1 = shapeStartPosition, tool == .shape {
            // Render shape on top of the image.
            
            if let p2 = shapeEndPosition {
                return translatedShape(p1: p1, p2: p2)
            } else {
                return artwork.image.drawEllipse(from: p1, to: position, color: getCurrentSemanticPixel())
            }
            
            // draw line in this case...
//            return image.drawLine(from: p1, to: p2, color: c)
        } else if tool == .selection, let p1 = shapeStartPosition, let p2 = shapeEndPosition {
            // Grab the pixels in the rectangle between p1 and p2, draw each one translated by p3.
            return artwork.image.moveRectangle(between: p1, and: p2, by: translation)
        } else {
            return artwork.image
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            OverlayView(pixelSize: pixelSize,
                        image: composedImage,
                        position: $position,
                        shapeStartPosition: shapeStartPosition,
                        shapeEndPosition: shapeEndPosition,
                        speed: $speed,
                        translation: $translation,
                        onDrag: onDrag)
                .padding()
            Spacer()
            Text(statusText)
            VStack {
                ToolsMenuV2(tool: $tool,
                            selectedSemanticIdentifierId: $selectedSemanticIdentifierId,
                            selectedColor: selectedColor,
                            statusText: $statusText,
                            position: $position,
                            shapeStartPosition: $shapeStartPosition,
                            shapeEndPosition: $shapeEndPosition,
                            translation: $translation)
                    .environmentObject(artwork)
                    .padding(.top)
                HStack {
                    Spacer()
                    SemanticIdentifierView(root: $artwork.root, selection: $selectedSemanticIdentifierId)
                    ColorPaletteView(colorPalette: selectedColorPalette, selectedColor: selectedColor)
                        .padding([.top, .bottom, .trailing])
                    Spacer()
                }
            }
            .frame(height: 320)
            .fixedSize(horizontal: false, vertical: true)
            .background(Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .ignoresSafeArea())
        }
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarTitle(artwork.title, displayMode: .inline)
    }
    
    func onDrag(_ delta: CGPoint) {
        if tool == nil {
            statusText = ("(x: \(position.x), y: \(position.y))")
        }
        if tool == .pencil {
            artwork.image[position] = getCurrentSemanticPixel()
        }
    }
    
    func getCurrentSemanticPixel() -> SemanticPixel<RGBA> {
        return SemanticPixel<RGBA>(id: selectedSemanticIdentifierId, color: _selectedColor.color)
    }
}

