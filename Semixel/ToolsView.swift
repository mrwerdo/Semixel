//
//  ToolsView.swift
//  Semixel
//
//  Created by Andrew Thompson on 7/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI


struct BigButton<T>: View where T: Equatable {
    
    
    var action: ((BigButton<T>) -> ())?
    @Binding var state: T
    var object: T
    var image: String
    
    var isSelected: Bool {
        return state == object
    }
    
    init(_ action: ((BigButton<T>) -> ())?, _ state: Binding<T>, _ object: T, image: String) {
        self.action = action
        self.object = object
        self.image = image
        _state = state
    }
    
    var background: some View {
        if isSelected {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemFill))
        } else {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
        }
    }
    
    var body: some View {
        Button(action: {
            action?(self)
            state = object
        }) {
            ZStack(alignment: .center) {
                background
                Image(systemName: image).font(Font.system(size: 36))
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}

struct Tools: View {
    
    enum ToolType: Equatable {
        case pencil
        case brush
        case shape
        case selection
        case none
    }
    
    @Binding var tool: ToolType
    
    var selected: ((ToolButton) -> ())?
    
    typealias ToolButton = BigButton<ToolType>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ToolButton(selected, $tool, .pencil, image: "pencil.tip")
                ToolButton(selected, $tool, .brush, image: "paintbrush")
                ToolButton(selected, $tool, .shape, image: "circle")
                ToolButton(selected, $tool, .none, image: "minus")
                ToolButton(selected, $tool, .none, image: "square.on.circle")
            }
            HStack {
                ToolButton(selected, $tool, .selection, image: "selection.pin.in.out")
                ToolButton(selected, $tool, .none, image: "magnifyingglass")
                ToolButton(selected, $tool, .none, image: "arrow.uturn.left")
                ToolButton(selected, $tool, .none, image: "arrow.uturn.right")
                ToolButton(selected, $tool, .none, image: "rotate.left")
            }
        }
    }
}
