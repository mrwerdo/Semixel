//
//  ColorPalette.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ColorTab: View {
    var color: RGBA
    var index: Int
    @Binding var state: Int
    
    var body: some View {
        Button(action: {
            state = index
        }) {
            ZStack() {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)))
                if state == index {
                    RoundedRectangle(cornerRadius: 8)
                        .opacity(0.0)
                        .disabled(true)
                        .border(Color.secondary, width: 4)
                }
            }
            .frame(width: 32, height: 32)
        }
    }
}

struct ColorPaletteEditView: View {
    @Binding var colors: [RGBA]
    @Binding var selectedColorIndex: Int
    
    private var selectedColor: Binding<RGBA> {
        Binding {
            colors[selectedColorIndex]
        } set: {
            colors[selectedColorIndex] = $0
        }
    }
    
    var body: some View {
        VStack {
            ScrollView( .horizontal) {
                LazyHStack(alignment: .top, spacing: 4) {
                    ForEach(0..<colors.count) { index in
                        ColorTab(color: colors[index], index: index, state: $selectedColorIndex)
                    }
                }
            }
            Slider(value: selectedColor.red, in: 0...1.0) {
                Text("Red")
            }
            Slider(value: selectedColor.green, in: 0...1.0) {
                Text("Green")
            }
            Slider(value: selectedColor.blue, in: 0...1.0) {
                Text("Blue")
            }
            Slider(value: selectedColor.alpha, in: 0...1.0) {
                Text("Alpha")
            }
        }
    }
}

struct ColorPalette: View {
    
    @Binding var identifier: SemanticIdentifier
    @Binding var selectedColorIndex: Int?
    
    @State var isEditing: Bool = false
    
    private func add() {
        print(#function)
    }
    
    private func eyeDropper() {
        print(#function)
    }
    
    private func edit() {
        isEditing.toggle()
    }
    
    private func replace() {
        print(#function)
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
            .font(Font.system(size: 20))
            if isEditing, selectedColorIndex != nil {
                ColorPaletteEditView(colors: $identifier.colorPalette, selectedColorIndex: Binding { selectedColorIndex! } set: { selectedColorIndex = $0 })
            } else {
                CollectionView(colors: identifier.colorPalette, selectedColorIndex: $selectedColorIndex, addCallback: add)
            }
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
