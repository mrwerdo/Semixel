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
    
    @State var tool: ToolType?
    @State var menuState: MenuState = .main
    @State var selectionStarted: Bool = false
    
    func resizing() { }
    func translating() { }
    func complete()  { }
    
    var main: some View {
        HStack {
            TerneryState.create($tool,
                                tool: .shape) {
                print("Shape tool: resizing...")
            } translating: {
                print("Shape tool: translating...")
            } complete: {
                print("Shape tool: complete.")
            }
            ToolMenuButton<MenuState>($menuState, state: .selection, image: "cursorarrow")
            OneShotState.create($tool, tool: .brush) {
                print("Paint bucket")
            }
            BinaryState.create($tool, tool: .pencil) {
                print("Pencil up")
            }
            OneShotState.create($tool, tool: .undo) {
                print("Undo")
            }
            OneShotState.create($tool, tool: .redo) {
                print("Redo")
            }
        }
    }
    
    var nextSelectionState: MenuState {
        if selectionStarted {
            return .transformation
        } else {
            return .main
        }
    }
    
    var selection: some View {
        HStack {
            TerneryState.create($tool, tool: .rectangularSelect) {
                print("Select: started...")
                selectionStarted = true
            } translating: {
                print("Select: translating...")
            } complete: {
                print("Select: completed.")
            }
            ToolMenuButton<MenuState>($menuState,
                                      state: nextSelectionState,
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
}
