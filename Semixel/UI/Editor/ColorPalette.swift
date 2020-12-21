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
    
    func addCallback() {
        print("Adding new color...")
    }
    
    func eyeDropper() {
        
    }
    
    func edit() {
        
    }
    
    func replace() {
        
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Button(action: eyeDropper) {
                    Image(systemName: "eyedropper")
                }
                .padding(4)
                Button(action: edit) {
                    Image(systemName: "slider.vertical.3")
                }
                .padding(4)
                Button(action: replace) {
                    Image(systemName: "xmark")
                }
                .padding(4)
            }
            .font(Font.system(size: 22))
            CollectionView(colors: colors, selectedColor: $selectedColor, addCallback: addCallback)
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
