//
//  ColorPalette.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ColorTab<T: Equatable>: View {
    var color: RGBA
    var index: T
    @Binding var state: T
    
    var body: some View {
        Button(action: {
            state = index
        }) {
            ZStack() {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)))
                if state == index {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary, lineWidth: 4)
                        .disabled(true)
                }
            }
            .frame(width: 32, height: 32)
        }
    }
}

struct ColorPaletteEditView: View {
    @ObservedObject var colorPalette: ColorPalette
    @Binding var selectedColor: IdentifiableColor
    
    var body: some View {
        VStack {
            ScrollView( .horizontal) {
                LazyHStack(alignment: .top, spacing: 4) {
                    ForEach(colorPalette.colors) { item in
                        ColorTab(color: item.color, index: item, state: $selectedColor)
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

struct ColorPaletteView: View {
    
    @ObservedObject var colorPalette: ColorPalette
    @Binding var selectedColor: IdentifiableColor
    
    @State var isEditing: Bool = false
    
    private func add() {
        colorPalette.colors.append(IdentifiableColor(color: selectedColor.color, id: UUID()))
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
                ColorPaletteEditView(colorPalette: colorPalette, selectedColor: $selectedColor)
            } else {
                CollectionView(colorPalette: colorPalette, selectedColor: $selectedColor, addCallback: add)
            }
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
