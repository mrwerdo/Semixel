//
//  ToolButton.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

protocol ToolButtonState: Equatable {
    var isSelected: Bool { get }
    static var deselected: Self { get }
}

extension ToolButtonState {
    var isSelected: Bool {
        return self != .deselected
    }
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
                image
            }
            .frame(width: 48, height: 48, alignment: .center)
        }
    }
    
    var image: some View {
        return Image(systemName: tool.iconName).font(Font.system(size: 24))
    }
}

enum BinaryState: ToolButtonState {
    case selected
    case deselected
}

extension BinaryState {
    var isSelected: Bool {
        return self == .selected
    }

    static func create(_ selectedTool: Binding<ToolType?>,
                       tool: ToolType,
                       _ deselected: @escaping () -> ()) -> ToolButton<Self> {
        return ToolButton<Self>(selectedTool, tool: tool) { (state) -> Self in
            switch state {
            case .selected:
                return .deselected
            case .deselected:
                deselected()
                return .selected
            }
        }
    }
}

enum TerneryState: ToolButtonState {
    case deselected
    case resizing
    case translating
}

extension TerneryState {
    static func create(_ selectedTool: Binding<ToolType?>, tool: ToolType, resizing: @escaping () -> (), translating: @escaping () -> (), complete: @escaping () -> ()) -> ToolButton<Self> {
        return ToolButton<Self>(selectedTool, tool: tool) { state -> Self in
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
            }
        }
    }
}

enum OneShotState: ToolButtonState {
    case deselected
}

extension OneShotState {
    var isSelected: Bool {
        return false
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, tool: ToolType, selected: @escaping () -> ()) -> ToolButton<Self> {
        ToolButton<Self>(selectedTool, tool: tool) { state -> Self in
            selected()
            return state
        }
    }
}
