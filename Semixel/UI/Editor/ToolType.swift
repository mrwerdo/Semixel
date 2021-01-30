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
    case circle
    case line
    case selection
    case undo
    case redo
    case settings
    case rectangularSelect
    case wand
    case copy
    case cut
    case rotate
    case vflip
    case hflip
    case selectionModeAdd
    case selectionModeRemove
    case translation
    case complete
    
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
        case .circle:
            return "circle"
        case .line:
            return "line.diagonal"
        case .selection:
            return "cursorarrow"
        case .settings:
            return "square.3.stack.3d"
        case .rectangularSelect:
            return "rectangle"
        case .wand:
            return "wand.and.stars"
        case .copy:
            return "doc.on.doc"
        case .cut:
            return "scissors"
        case .rotate:
            return "rotate.left"
        case .vflip:
            return "arrow.up.and.down.righttriangle.up.righttriangle.down"
        case .hflip:
            return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .selectionModeAdd:
            return "rectangle.badge.plus"
        case .selectionModeRemove:
            return "rectangle.badge.minus"
        case .translation:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .complete:
            return "checkmark.circle"
        }
    }
    
    var isShape: Bool {
        return self == .circle || self == .line
    }
}
