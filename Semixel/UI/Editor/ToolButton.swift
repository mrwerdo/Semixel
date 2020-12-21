//
//  ToolButton.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

protocol ToolButtonState: Equatable {
    associatedtype Icon: View
    var image: Icon { get }
    var isSelected: Bool { get }
    
    static var deselected: Self { get }
    static var tool: ToolType { get }
}

struct ToolButton<State: ToolButtonState>: View {
    var tool: ToolType
    @Binding var selectedTool: ToolType?
    var transition: (State) -> State
    @SwiftUI.State var state: State = .deselected
    
    init(_ selectedTool: Binding<ToolType?>, tool: ToolType, transition: @escaping (State) -> State) {
        self._selectedTool = selectedTool
        self.tool = tool
        self.transition = transition
    }
    
    private func update() {
        if tool != selectedTool {
            state = State.deselected
        }
        let nextState = transition(state)
        state = nextState
        selectedTool = state == State.deselected ? nil : tool
    }
    
    private var isSelected: Bool {
        return state.isSelected && tool == selectedTool
    }
    
    var body: some View {
        Button(action: update) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(.systemGray4) : Color(.secondarySystemBackground))
                state.image
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}

protocol BinaryState: ToolButtonState {
    static var selected: Self { get }
    static var deselected: Self { get }
}

extension BinaryState {
    var image: some View {
        return Image(systemName: "pencil.tip").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self == .selected
    }

    static func create(_ selectedTool: Binding<ToolType?>, _ draw: @escaping () -> ()) -> ToolButton<Self> {
        return ToolButton<Self>(selectedTool, tool: .pencil) { (state) -> Self in
            switch state {
            case .selected:
                return .deselected
            case .deselected:
                draw()
                return .selected
            default:
                fatalError("BinaryState can have only two states.")
            }
        }
    }
}

enum PencilState: BinaryState {
    case deselected
    case selected
    static var tool: ToolType {
        return .pencil
    }
}

protocol TerneryState: ToolButtonState {
    static var deselected: Self { get }
    static var resizing: Self { get }
    static var translating: Self { get }
}

extension TerneryState {
    var image: some View {
        return Image(systemName: Self.tool.iconName).font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self != .deselected
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, resizing: @escaping () -> (), translating: @escaping () -> (), complete: @escaping () -> ()) -> ToolButton<Self> {
        return ToolButton<Self>(selectedTool, tool: Self.tool) { state -> Self in
            switch state {
            case .deselected:
                resizing()
                return .resizing
            case .resizing:
                translating()
                return .translating
            case .translating:
                complete()
                return .deselected
            default:
                fatalError("TerneryState should not have more than three cases.")
            }
        }
    }
}

enum SelectionState: TerneryState {
    case deselected
    case resizing
    case translating
    
    static var tool: ToolType { return .selection }
}

enum ShapeState: TerneryState {
    case deselected
    case resizing
    case translating
    
    static var tool: ToolType { return .shape }
}

protocol OneShotState: ToolButtonState { }

extension OneShotState {
    var image: some View {
        return Image(systemName: Self.tool.iconName).font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return false
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, selected: @escaping () -> ()) -> ToolButton<Self> {
        ToolButton<Self>(selectedTool, tool: Self.tool) { state -> Self in
            selected()
            return state
        }
    }
}

struct PaintBucketState: OneShotState {
    static var tool: ToolType {
        return .brush
    }
    
    static var deselected: PaintBucketState {
        return PaintBucketState()
    }
}

struct UndoState: OneShotState {
    static var tool: ToolType {
        return .undo
    }
    
    static var deselected: UndoState {
        return UndoState()
    }
}

struct RedoState: OneShotState {
    static var tool: ToolType {
        return .redo
    }
    
    static var deselected: RedoState {
        return RedoState()
    }
}
