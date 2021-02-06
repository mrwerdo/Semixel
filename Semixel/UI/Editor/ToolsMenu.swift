//
//  ToolsMenu.swift
//  Semixel
//
//  Created by Andrew Thompson on 24/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

/*
 ToolsMenu could be improved to satisfy the following:
 1. If a tool is has multiple states, and the user selects another tool, then the original tool
    should reset to its initial state.
 2. There are some tools that do not have state.
 3. There are some tools that operate on the selection - these should not reset the selection
    animation.
 4. The selection tool has a nested menu.
 5. Navigating between the menus should not reset the behaviour.
 
 Any improvements should enhance the readability of the implementation.
 */

struct ToolsMenu: View {
    
    enum MenuState {
        case main
        case selection
        case transformation
    }
    
    @State var menuState: MenuState = .main
    @State var selectionStarted: Bool = false
    @State var isAppendMode: Bool = true
    @State var isLineTool: Bool = true
    
    @EnvironmentObject var artwork: SemanticArtwork
    
    @Binding var tool: ToolType?
    @Binding var selectedSemanticIdentifierId: Int
    @Binding var selectedColor: Int
    @Binding var statusText: String
    @Binding var position: Point2D
    @Binding var shapeStartPosition: Point2D?
    @Binding var shapeEndPosition: Point2D?
    @Binding var translation: Point2D
    
    @Binding var selectedRegion: SelectedRegion?
    
    func icon(for type: ToolType) -> some View {
        Image(systemName: type.iconName).font(Font.system(size: 24))
    }
    
    private func longPressCallback() {
        isLineTool.toggle()
        tool = nil
        reset()
    }
    
    var main: some View {
        HStack {
            TerneryState.create($tool,
                                tool: isLineTool ? .line : .circle) {
                resizing(statusText: isLineTool ? "Line tool." : "Circle tool.")
            } translating: {
                translating()
            } complete: {
                completed { (p1, p2, offset) in
                    artwork.image = translatedShape(p1: p1, p2: p2)
                }
            }
            .buttonStyle(LongPressButtonStyle(minimumDuration: 0.3, maximumDistance: 100, callback: longPressCallback))
            AnyToolButton(isSelected: false, image: icon(for: .selection)) {
                isAppendMode = true
                menuState = .selection
            }
            OneShotState.create($tool, tool: .brush) {
                statusText = "Applied paint bucket."
                let oldColor = artwork.image[position]
                let points = artwork.image.floodSearch(at: position) { (_, c) -> Bool in c.color == oldColor.color && c.semantic == oldColor.semantic }
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
    
    func translatedShape(p1: Point2D, p2: Point2D) -> PixelImage<SemanticPixel> {
        let a = p1 + translation
        let b = p2 + translation
        
        if artwork.image.isValid(a) && artwork.image.isValid(b) {
            switch tool {
            case .line:
                return artwork.image.drawLine(from: a, to: b, color: getCurrentSemanticPixel())
            case .circle:
                return artwork.image.drawEllipse(from: a, to: b, color: getCurrentSemanticPixel())
            default:
                return artwork.image
            }
        } else {
            return artwork.image
        }
    }
    
    var selection: some View {
        HStack {
            BinaryState.create($tool, tool: .rectangularSelect) {
                selectionStarted = true
                resizing(statusText: "Selection tool.")
            } selected: {
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
            AnyToolButton(isSelected: !selectionStarted,
                          image: icon(for: selectionStarted ? .translation : .selection)) {
                if selectionStarted {
                    menuState = .transformation
                    tool = .translation
                    translation = .zero
                } else {
                    menuState = .main
                }
            }
            OneShotState.create($tool, tool: .wand) {
                print("Wand")
                selectionStarted = true
            }
            AnyToolButton(isSelected: false, image: icon(for: isAppendMode ? .selectionModeAdd : .selectionModeRemove)) {
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
            AnyToolButton(isSelected: false, image: icon(for: .complete)) {
                menuState = .main
                if let selection = selectedRegion {
                    artwork.image = artwork.image.move(selection: selection, by: translation, background: .clear)
                }
                selectionStarted = false
                reset()
                tool = .complete
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
    
    func getCurrentSemanticPixel() -> SemanticPixel {
        return SemanticPixel(semantic: selectedSemanticIdentifierId, color: selectedColor)
    }
}
