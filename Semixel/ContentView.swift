//
//  ContentView.swift
//  Semixel
//
//  Created by Andrew Thompson on 9/7/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct BigButton: View {
    
    var image: String
    
    var body: some View {
        Button(action: {
            print("button tapped")
        }) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                Image(systemName: image).font(Font.system(size: 36))
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}

struct Tools: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                BigButton(image: "pencil.tip")
                BigButton(image: "paintbrush")
                BigButton(image: "circle")
                BigButton(image: "minus")
                BigButton(image: "square.on.circle")
            }
            HStack {
                BigButton(image: "selection.pin.in.out")
                BigButton(image: "magnifyingglass")
                BigButton(image: "arrow.uturn.left")
                BigButton(image: "arrow.uturn.right")
                BigButton(image: "rotate.left")
            }
        }
    }
}

struct ColorTab: View {
    var tag: Int
    var color: Color
    
    var body: some View {
        Button(action: {
            print("color tab tapped")
        }) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(color).frame(width: 32, height: 32, alignment: .center)
                Image(systemName: "\(abs(tag)).circle")
                    .background(
                        Rectangle()
                            .fill(Color(.secondarySystemBackground)))
                    .frame(width: 32, height: 32, alignment: .center)
                    .border(Color(.systemGray3), width: 2.0)
            }.mask(
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 64, height: 32, alignment: .center))
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            Image("pixel_art")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 365, alignment: .center)
                .border(Color(.systemGray5), width: 4)
            Tools()
            HStack(spacing: 8) {
                ColorTab(tag: 1, color: Color(.systemBlue))
                ColorTab(tag: 2, color: Color(.systemGreen))
                ColorTab(tag: 3, color: Color(.systemIndigo))
                ColorTab(tag: 4, color: Color(.systemOrange))
                ColorTab(tag: 5, color: Color(.systemPink))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
