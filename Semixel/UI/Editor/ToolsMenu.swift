//
//  ToolsMenu.swift
//  Semixel
//
//  Created by Andrew Thompson on 24/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ToolsMenu: View {
    
    typealias SemanticImage = PixelImage<SemanticPixel<RGBA>>
    
    enum MenuState {
        case main
        case selection
        case transformation
    }
    
    @State var menuState: MenuState = .main
    @State var selectionStarted: Bool = false
    @State var isAppendMode: Bool = true
    
    @EnvironmentObject var artwork: SemanticArtwork
    
    @Binding var tool: ToolType?
    @Binding var selectedSemanticIdentifierId: Int
    @Binding var selectedColor: IdentifiableColor
    @Binding var statusText: String
    @Binding var position: Point2D
    @Binding var shapeStartPosition: Point2D?
    @Binding var shapeEndPosition: Point2D?
    @Binding var translation: Point2D
    
    @Binding var selectedRegion: SelectedRegion?
    
    var main: some View {
        HStack {
            TerneryState.create($tool,
                                tool: .shape) {
                resizing(statusText: "Shape tool.")
            } translating: {
                translating()
            } complete: {
                completed { (p1, p2, offset) in
                    artwork.image = translatedShape(p1: p1, p2: p2)
                }
            }
            ToolMenuButton<MenuState>($menuState, state: .selection, image: "cursorarrow") {
                isAppendMode = true
            }
            OneShotState.create($tool, tool: .brush) {
                statusText = "Applied paint bucket."
                let oldColor = artwork.image[position]
                let points = artwork.image.floodSearch(at: position) { (_, c) -> Bool in c.color == oldColor.color && c.id == oldColor.id }
                for point in points {
                    artwork.image[point] = getCurrentSemanticPixel()
                }
            }
            BinaryState.create($tool, tool: .pencil) {
                reset()
                statusText = "Pencil selected."
                applyPencil()
            }
            OneShotState.create($tool, tool: .undo) {
                statusText = "Undone"
            }
            OneShotState.create($tool, tool: .redo) {
                statusText = "Redone"
            }
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
    
    var selection: some View {
        HStack {
            BinaryState.create($tool, tool: .rectangularSelect) {
                resizing(statusText: "Selection tool.")
            } selected: {
                selectionStarted = true
                if selectedRegion == nil {
                    selectedRegion = SelectedRegion(size: artwork.image.size)
                }
                shapeEndPosition = position
                completed { (a, b, offset) in
                    let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
                    let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
                    let rect = Rect2D(c1: p1 + offset, c2: p2 + offset)
                    if var k = selectedRegion {
                        k.update(points: rect.points, mode: .toggle)
                        selectedRegion = k
                    }
                }
            }
            ToolMenuButton<MenuState>($menuState,
                                      state: selectionStarted ? .transformation : .main,
                                      image: selectionStarted ? "arrow.up.and.down.and.arrow.left.and.right" : "cursorarrow",
                                      isSelected: !selectionStarted) {
                tool = .translation
                translation = .zero
            }
            OneShotState.create($tool, tool: .wand) {
                print("Wand")
                selectionStarted = true
            }
            ToolMenuButton<Void>(state: (), image: isAppendMode ? ToolType.selectionModeAdd.iconName : ToolType.selectionModeRemove.iconName) {
                isAppendMode.toggle()
            }
            OneShotState.create($tool, tool: .undo) {
                print("Undo")
            }
            OneShotState.create($tool, tool: .redo) {
                print("Redo")
            }
        }
    }
    
    var transformation: some View {
        HStack {
            OneShotState.create($tool, tool: .rotate) {
                print("Rotate")
            }
            ToolMenuButton<MenuState>($menuState, state: .main, image: "checkmark.circle") {
                if let selection = selectedRegion {
                    artwork.image = artwork.image.move(selection: selection, by: translation, background: .clear)
                }
                selectionStarted = false
                reset()
                tool = .selection
                selectedRegion = nil
            }
            OneShotState.create($tool, tool: .copy) {
                print("Copy")
            }
            OneShotState.create($tool, tool: .cut) {
                print("Cut")
            }
            OneShotState.create($tool, tool: .vflip) {
                print("Vflip")
            }
            OneShotState.create($tool, tool: .hflip) {
                print("Hflip")
            }
        }
    }
    
    var body: AnyView {
        switch menuState {
        case .main:
            return AnyView(main)
        case .selection:
            return AnyView(selection)
        case .transformation:
            return AnyView(transformation)
        }
    }
    
    func resizing(statusText: String) {
            reset()
            self.statusText = statusText
            shapeStartPosition = position
    }
    
    func translating() {
        statusText = "Translating..."
        if shapeStartPosition != nil {
            translation = .zero
            shapeEndPosition = position
//            let p = convertToInteger(position)
//            position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
        }
    }
    
    func completed(callback: (_ p1: Point2D, _ p2: Point2D, _ offset: Point2D) -> ()) {
        statusText = "Complete."
        if let p2 = shapeEndPosition {
            if let p1 = shapeStartPosition {
                callback(p1, p2, translation)
            }
            shapeEndPosition = nil
            shapeStartPosition = nil
        }
    }
    
    func reset() {
        shapeStartPosition = nil
        shapeEndPosition = nil
        translation = .zero
    }
    
    func applyPencil() {
        artwork.image[position] = getCurrentSemanticPixel()
    }
    
    func getCurrentSemanticPixel() -> SemanticPixel<RGBA> {
        return SemanticPixel<RGBA>(id: selectedSemanticIdentifierId, color: selectedColor.color)
    }
}
