//
//  ToolsMenu.swift
//  Semixel
//
//  Created by Andrew Thompson on 24/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ToolMenuButton<State>: View {
    
    var state: State
    var isSelected: Bool
    var imageName: String
    var selected: () -> ()
    @Binding var currentState: State
    
    init(_ currentState: Binding<State>, state: State, image: String, isSelected: Bool = false, selected: @escaping () -> () = {}) {
        self.state = state
        self._currentState = currentState
        self.isSelected = isSelected
        self.imageName = image
        self.selected = selected
    }
    
    private func update() {
        currentState = state
        selected()
    }
    
    var body: some View {
        Button(action: update) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(.systemGray4) : Color(.secondarySystemBackground))
                Image(systemName: imageName).font(Font.system(size: 24))
            }
            .frame(width: 48, height: 48, alignment: .center)
        }
    }
}

struct ToolsMenuV2: View {
    
    enum MenuState {
        case main
        case selection
        case transformation
    }
    
    @State var menuState: MenuState = .main
    @State var selectionStarted: Bool = false
    
    @EnvironmentObject var artwork: SemanticArtwork
    
    @Binding var tool: ToolType?
    @Binding var selectedSemanticIdentifierId: Int
    @Binding var selectedColor: IdentifiableColor
    @Binding var statusText: String
    @Binding var position: Point2D
    @Binding var shapeStartPosition: Point2D?
    @Binding var shapeEndPosition: Point2D?
    @Binding var translation: Point2D
    
    var main: some View {
        HStack {
            TerneryState.create($tool,
                                tool: .shape) {
                resizing(statusText: "Shape tool.")()
            } translating: {
                translating()
            } complete: {
                completed { (p1, p2, offset) in
                    artwork.image = translatedShape(p1: p1, p2: p2)
                }()
            }
            ToolMenuButton<MenuState>($menuState, state: .selection, image: "cursorarrow")
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
    
    typealias SemanticImage = PixelImage<SemanticPixel<RGBA>>
    
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
            TerneryState.create($tool, tool: .rectangularSelect) {
                resizing(statusText: "Selection tool.")()
                selectionStarted = true
            } translating: {
                translating()
            } complete: {
                completed { (p1, p2, offset) in
                    artwork.image = artwork.image.moveRectangle(between: p1, and: p2, by: offset)
                }()
            }
            ToolMenuButton<MenuState>($menuState,
                                      state: selectionStarted ? .transformation : .main,
                                      image: selectionStarted ? "arrow.up.and.down.and.arrow.left.and.right" : "cursorarrow",
                                      isSelected: !selectionStarted)
            OneShotState.create($tool, tool: .wand) {
                print("Wand")
                selectionStarted = true
            }
            BinaryState.create($tool, tool: .brush) {
                print("Toggle Mode")
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
                selectionStarted = false
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
    
    func resizing(statusText: String) -> () -> () {
        return {
            reset()
            self.statusText = statusText
            shapeStartPosition = position
        }
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
    
    func completed(callback: @escaping (_ p1: Point2D, _ p2: Point2D, _ offset: Point2D) -> ()) -> () -> () {
        return {
            statusText = "Complete."
            if let p2 = shapeEndPosition {
                if let p1 = shapeStartPosition {
                    callback(p1, p2, translation)
                }
                shapeEndPosition = nil
                shapeStartPosition = nil
            }
        }
    }
    
    func onDrag(_ delta: CGPoint) {
        if tool == nil {
            statusText = ("(x: \(position.x), y: \(position.y))")
        }
        if tool == .pencil {
            applyPencil()
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
