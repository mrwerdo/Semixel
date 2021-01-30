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

struct LongPressButtonStyle: PrimitiveButtonStyle {
    
    @State
    private var isPressed: Bool = false
    
    @State
    private var touchDownTime: Date?
    
    @State
    private var isDisabled = false
    
    var minimumDuration: TimeInterval
    var maximumDistance: CGFloat
    var callback: () -> ()

    init(minimumDuration: TimeInterval, maximumDistance: CGFloat, callback: @escaping () -> ()) {
        self.minimumDuration = minimumDuration
        self.maximumDistance = maximumDistance
        self.callback = callback
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { state in
                if isDisabled {
                    return
                }
                isPressed = true
                if touchDownTime == nil {
                    touchDownTime = state.time
                }
                let dt = state.translation
                let distance = sqrt(dt.width * dt.width + dt.height * dt.height)
                if distance > maximumDistance {
                    withAnimation(Animation.easeOut) {
                        isPressed = false
                        isDisabled = true
                    }
                }
            }
            .onEnded { state in
                if isDisabled {
                    isDisabled = false
                    return
                }
                isPressed = false
                
                guard let touchDownTime = touchDownTime else {
                    return
                }
                
                let distance = touchDownTime.distance(to: state.time)
                if distance < minimumDuration {
                    configuration.trigger()
                } else {
                    callback()
                }
                self.touchDownTime = nil
            }
        
        return configuration.label
            .foregroundColor(Color.accentColor)
            .opacity(isPressed ? 0.25 : 1.0)
            .gesture(drag)
    }
}

struct AnyToolButton<Image: View>: View {
    
    var isSelected: Bool
    var image: Image
    var selected: () -> ()
    
    var body: some View {
        Button(action: selected) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(.systemGray4) : Color(.secondarySystemBackground))
                image
            }
            .frame(width: 48, height: 48, alignment: .center)
        }
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
        AnyToolButton(isSelected: isSelected, image: image, selected: update)
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
                       _ deselected: @escaping () -> (),
                       selected: @escaping () -> () = { }) -> ToolButton<Self> {
        return ToolButton<Self>(selectedTool, tool: tool) { (state) -> Self in
            switch state {
            case .selected:
                selected()
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
