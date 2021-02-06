//
//  SemanticColor.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import UIKit
import Combine
import SwiftUI

typealias ColorIdentifier = Int

struct IdentifiableColor: Identifiable, Equatable, Codable {
    var id: ColorIdentifier
    var color: RGBA
    
    init(id: ColorIdentifier, color: RGBA) {
        self.id = id
        self.color = color
    }
}

class ColorPalette: ObservableObject {
    @Published
    var colors: [IdentifiableColor]
    
    @Published
    var selectedIndex: Int = 0
    
    var currentColor: Binding<RGBA> {
        Binding { () -> RGBA in
            self[rgba: self.selectedIndex]
        } set: { (newValue) in
            self[rgba: self.selectedIndex] = newValue
        }
    }

    func color(with id: ColorIdentifier) -> IdentifiableColor? {
        return colors.first { $0.id == id }
    }

    func remove(id: ColorIdentifier) {
        if let oldIndex = colors.firstIndex(where: { $0.id == selectedIndex }) {
            if oldIndex > colors.startIndex {
                let index = colors.index(before: oldIndex)
                selectedIndex = colors[index].id
            } else if oldIndex < colors.endIndex {
                let index = colors.index(after: oldIndex)
                selectedIndex = colors[index].id
            }
        }
        colors.removeAll { $0.id == id }
    }
    
    subscript(rgba id: ColorIdentifier) -> RGBA {
        get { color(with: id)?.color ?? .clear }
        set {
            let index = colors.firstIndex(where: { $0.id == id })!
            colors[index].color = newValue
        }
    }
    
    @discardableResult
    func add(_ color: RGBA, updateSelection: Bool = false) -> ColorIdentifier {
        let index = getNewId()
        colors.append(IdentifiableColor(id: index, color: color))
        
        if updateSelection {
            selectedIndex = index
        }
        
        return index
    }
    
    private func getNewId() -> ColorIdentifier {
        var index = 1
        while colors.map({$0.id}).contains(index) {
            index += 1
        }
        return index
    }
    
    init(colors: [Int: RGBA]) {
        self.colors = colors.map { IdentifiableColor(id: $0.key, color: $0.value) }
    }
    
    init(_ colors: [IdentifiableColor]) {
        self.colors = colors
    }
}
