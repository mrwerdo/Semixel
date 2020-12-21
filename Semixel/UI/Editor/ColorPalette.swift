//
//  ColorPalette.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ColorPalette: View {
    @Binding var colors: [SemanticColor]
    @Binding var selectedColor: SemanticColor
    
    @State var isAddingNewColor = false
    
    func addCallback() {
        print("Adding new color...")
    }
    
    var body: some View {
        VStack {
            ColorPicker("", selection: $selectedColor.cgColor, supportsOpacity: true)
            CollectionView(colors: colors, selectedColor: $selectedColor, addCallback: addCallback)
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
