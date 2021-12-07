//
//  ColorPalette.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI
import SemixelCore

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
    @EnvironmentObject var colorPalette: ColorPalette
    
    var body: some View {
        let stuff: [IdentifiableColor] = colorPalette.colors
        return VStack {
            ScrollView( .horizontal) {
                LazyHStack(alignment: .top, spacing: 4) {
                    ForEach(stuff, id: \.id) { (item: IdentifiableColor) in
                        ColorTab(color: item.color, index: item.id, state: $colorPalette.selectedIndex)
                    }
                }
            }
            Slider(value: colorPalette.currentColor.red, in: 0...1.0) {
                Text("Red")
            }
            Slider(value: colorPalette.currentColor.green, in: 0...1.0) {
                Text("Green")
            }
            Slider(value: colorPalette.currentColor.blue, in: 0...1.0) {
                Text("Blue")
            }
            Slider(value: colorPalette.currentColor.alpha, in: 0...1.0) {
                Text("Alpha")
            }
        }
    }
}

struct ColorPaletteView: View {
    @EnvironmentObject var colorPalette: ColorPalette
    
    @State var isEditing: Bool = false
    
    var eyeDropper: () -> ()
    
    private func edit() {
        isEditing.toggle()
    }
    
    private func replace() {
        colorPalette.remove(id: colorPalette.selectedIndex)
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
                ColorPaletteEditView()
            } else {
                CollectionView()
            }
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}
