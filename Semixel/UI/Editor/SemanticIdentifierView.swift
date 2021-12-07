//
//  SemanticIdentifierView.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI
import SemixelCore

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct SemanticIdentifierView: View {
    
    @Binding
    var root: SemanticIdentifier
    
    @Binding
    var selection: Int
    
    var body: some View {
        VStack {
            List(root.children, children: \.childrenOrNil) { item in
                MultipleSelectionRow(title: item.name, isSelected: selection == item.id) {
                    selection = item.id
                }
            }
            Button {
                let count = root.children.count
                root.children.append(SemanticIdentifier(id: count, name: "Identifier \(count)"))
            } label: {
                Text("Add")
            }
        }
    }
}
