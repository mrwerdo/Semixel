//
//  ToolsView.swift
//  Semixel
//
//  Created by Andrew Thompson on 7/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI


struct BigButton<T>: View where T: Equatable {
    
    
    @Binding var state: T
    var object: T
    var image: String
    
    var isSelected: Bool {
        return state == object
    }
    
    init(_ state: Binding<T>, _ object: T, image: String) {
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
        case none
    }
    
    @Binding var tool: ToolType
    
    func selected(_ tool: ToolType) {
        self.tool = tool
    }
    
    typealias ToolButton = BigButton<ToolType>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ToolButton($tool, .pencil, image: "pencil.tip")
                ToolButton($tool, .brush, image: "paintbrush")
                ToolButton($tool, .shape, image: "circle")
                ToolButton($tool, .none, image: "minus")
                ToolButton($tool, .none, image: "square.on.circle")
            }
            HStack {
                ToolButton($tool, .none, image: "selection.pin.in.out")
                ToolButton($tool, .none, image: "magnifyingglass")
                ToolButton($tool, .none, image: "arrow.uturn.left")
                ToolButton($tool, .none, image: "arrow.uturn.right")
                ToolButton($tool, .none, image: "rotate.left")
            }
        }
    }
}
