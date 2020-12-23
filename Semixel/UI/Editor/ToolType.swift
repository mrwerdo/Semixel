//
//  ToolType.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation

enum ToolType: Equatable {
    case pencil
    case brush
    case shape
    case selection
    case none
    case undo
    case redo
    case settings
    
    var iconName: String {
        switch self {
        case .brush:
            return "paintbrush"
        case .pencil:
            return "pencil.tip"
        case .redo:
            return "arrow.uturn.right"
        case .undo:
            return "arrow.uturn.left"
        case .shape:
            return "circle"
        case .selection:
            return "cursorarrow"
        case .none:
            return "questionmark"
        case .settings:
            return "square.3.stack.3d"
        }
    }
}
