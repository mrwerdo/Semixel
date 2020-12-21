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
    @Binding var state: RGBA
    
    var body: some View {
        Button(action: {
            state = color
        }) {
            ZStack() {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)))
                if state == color {
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

extension SemanticColor: Identifiable {
    var id: String {
        return "\(color.red), \(color.green), \(color.blue), \(color.alpha)"
    }
}

struct ColorPaletteEditView: View {
    var colors: [SemanticColor]
    @Binding var selectedColor: SemanticColor
    
    var body: some View {
        VStack {
            ScrollView( .horizontal) {
                LazyHStack(alignment: .top, spacing: 4) {
                    ForEach(colors) { item in
                        ColorTab(color: item.color, state: $selectedColor.color)
                    }
                }
            }
            Slider(value: $selectedColor.color.red, in: 0...1.0) {
                Text("Red")
            }
            Slider(value: $selectedColor.color.green, in: 0...1.0) {
                Text("Green")
            }
            Slider(value: $selectedColor.color.blue, in: 0...1.0) {
                Text("Blue")
            }
            Slider(value: $selectedColor.color.alpha, in: 0...1.0) {
                Text("Alpha")
            }
        }
    }
}

struct ColorPalette: View {
    @Binding var colors: [SemanticColor]
    @Binding var selectedColor: SemanticColor
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
            if isEditing {
                ColorPaletteEditView(colors: colors, selectedColor: $selectedColor)
            } else {
                CollectionView(colors: colors, selectedColor: $selectedColor, addCallback: add)
            }
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
