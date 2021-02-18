//
//  PixelView.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct PixelView: View {
    
    @EnvironmentObject var artwork: SemanticArtwork
    @EnvironmentObject var metadata: ArtworkMetadata
    @EnvironmentObject var store: ArtworkStore
    
    @State var editingTitle: Bool = false
    
    @State var selectedSemanticIdentifierId: Int = 0
    @State var statusText: String = ""
    
    @State var fullScreenDragEnabled: Bool = false
    @State var tool: ToolType? = nil
    @State var position: Point2D = .zero
    @State var speed: CGFloat = 0.8
    
    @State var shapeStartPosition: Point2D?
    @State var shapeEndPosition: Point2D?
    @State var translation: Point2D = .zero
    
    @State var selectedRegion: SelectedRegion?
    @State var showMetadataView: Bool = false
    
    @State var showGrid: Bool = true
    
    @State var verticalFlip: Bool = false
    @State var horizontalFlip: Bool = false
    
    @State var __position: CGPoint = .zero
    
    func translatedShape(p1: Point2D, p2: Point2D) -> PixelImage<SemanticPixel> {
        let a = p1 + translation
        let b = p2 + translation
        
        if artwork.image.isValid(a) && artwork.image.isValid(b) {
            switch tool {
            case .circle:
                return artwork.image.drawEllipse(from: a, to: b, color: getCurrentSemanticPixel())
            case .line:
                return artwork.image.drawLine(from: a, to: b, color: getCurrentSemanticPixel())
            default:
                return artwork.image
            }
        } else {
            return artwork.image
        }
    }
    
    var composedImage: PixelImage<SemanticPixel> {
        if let p1 = shapeStartPosition, tool?.isShape == true {
            // Render shape on top of the image.
            
            if let p2 = shapeEndPosition {
                return translatedShape(p1: p1, p2: p2)
            } else {
                switch tool {
                case .circle:
                    return artwork.image.drawEllipse(from: p1, to: position, color: getCurrentSemanticPixel())
                case .line:
                    return artwork.image.drawLine(from: p1, to: position, color: getCurrentSemanticPixel())
                default:
                    return artwork.image
                }
            }
        } else if tool == .selection, let p1 = shapeStartPosition, let p2 = shapeEndPosition {
            // Grab the pixels in the rectangle between p1 and p2, draw each one translated by p3.
            return artwork.image.moveRectangle(between: p1, and: p2, by: translation)
        } else if let selection = self.selectedRegion {
            return artwork.image
                .transform(selection: selection, horizontalFlip: horizontalFlip, verticalFlip: verticalFlip, offset: translation)
        } else {
            return artwork.image
        }
    }
    
    private var bitmapImage: PixelImage<RGBA> {
        let image = composedImage
        let buffer = image.buffer.map { artwork.colorPalette[rgba: $0.color] }
        return PixelImage(size: image.size, buffer: buffer)
    }
    
    var overlay: some View {
        let size = CGSize(width: CGFloat(artwork.image.size.width), height: CGFloat(artwork.image.size.height))
        return GeometryReader() { geometry in
            DragView(imageSize: artwork.image.size,
                     pixelSize: CGSize(square: floor(min(geometry.size.width / size.width,
                                                   geometry.size.height / size.height))),
                     translating: tool == .translation,
                     shapeStartPosition: shapeStartPosition,
                     shapeEndPosition: shapeEndPosition,
                     position: $position,
                     speed: $speed,
                     translation: $translation,
                     __position: $__position,
                     onDrag: onDrag,
                     content:
                        OverlayView(pixelSize: CGSize(square: floor(min(geometry.size.width / size.width,
                                                                  geometry.size.height / size.height))),
                                    image: bitmapImage,
                                    position: position,
                                    showGrid: showGrid,
                                    showBoundingRectangle: tool != .line,
                                    shapeStartPosition: shapeStartPosition,
                                    shapeEndPosition: shapeEndPosition,
                                    selectedRegion: $selectedRegion,
                                    translating: tool == .translation,
                                    translation: translation,
                                    selectionVerticalFlipped: verticalFlip,
                                    selectionHorizontalFlipped: horizontalFlip,
                                    __position: $__position)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height,
                               alignment: .center))
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .center) {
                Spacer()
                overlay
                    .padding()
                    .gesture(dismissKeyboard)
                Text(statusText)
                    .frame(height: 30, alignment: .bottom)
                VStack {
                    ToolsMenu(tool: $tool,
                              selectedSemanticIdentifierId: $selectedSemanticIdentifierId,
                              selectedColor: $artwork.colorPalette.selectedIndex,
                              statusText: $statusText,
                              position: $position,
                              shapeStartPosition: $shapeStartPosition,
                              shapeEndPosition: $shapeEndPosition,
                              translation: $translation,
                              selectedRegion: $selectedRegion,
                              verticalFlip: $verticalFlip,
                              horizontalFlip: $horizontalFlip)
                        .environmentObject(artwork)
                        .padding(.top)
                    HStack {
                        Spacer()
                        SemanticIdentifierView(root: $artwork.root, selection: $selectedSemanticIdentifierId)
                            .padding(.bottom)
                        ColorPaletteView(eyeDropper: eyeDropper)
                            .environmentObject(artwork.colorPalette)
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
            .ignoresSafeArea(.keyboard)
            .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
        }
        .halfModalSheet(isPresented: $showMetadataView,
                        content: ArtworkMetadataView(isPresented: $showMetadataView,
                                                     showGrid: $showGrid))
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Title", text: $metadata.title) {
                    editingTitle = $0
                } onCommit: {
                    editingTitle = false
                    ignoreErrors { try store.saveMetadata() }
                }
                .font(Font.system(size: 15, weight: .medium))
            }
        }
        .navigationBarItems(trailing: attributesButton)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var dismissKeyboard: some Gesture {
        TapGesture()
            .onEnded {
                if editingTitle {
                    hideKeyboard()
                }
            }
    }
    
    var attributesButton: some View {
        Button(action: {
            showMetadataView.toggle()
        }, label: {
            Image(systemName: "ellipsis.circle")
                .font(Font.title2.weight(.light))
                .contentShape(Rectangle())
        })
    }

    private func eyeDropper() {
        artwork.colorPalette.selectedIndex = artwork.image[position].color
        statusText = "Selected color at (x: \(position.x), y: \(position.y))"
    }
    
    func onDrag(_ delta: CGPoint) {
        if tool == nil {
            statusText = ("(x: \(position.x), y: \(position.y))")
        }
        if tool == .pencil {
            artwork.assign(pixel: getCurrentSemanticPixel(), at: [position])
        }
    }
    
    func getCurrentSemanticPixel() -> SemanticPixel {
        return SemanticPixel(semantic: selectedSemanticIdentifierId, color: artwork.colorPalette.selectedIndex)
    }
}

