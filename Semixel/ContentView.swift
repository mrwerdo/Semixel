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

struct PixelGridImage: View {
    
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let numberOfHorizontalGridLines = Int(geometry.size.height / self.verticalSpacing)
                let numberOfVerticalGridLines = Int(geometry.size.width / self.horizontalSpacing)
                for index in 0...numberOfVerticalGridLines {
                    let vOffset: CGFloat = CGFloat(index) * self.horizontalSpacing
                    path.move(to: CGPoint(x: vOffset, y: 0))
                    path.addLine(to: CGPoint(x: vOffset, y: geometry.size.height))
                }
                for index in 0...numberOfHorizontalGridLines {
                    let hOffset: CGFloat = CGFloat(index) * self.verticalSpacing
                    path.move(to: CGPoint(x: 0, y: hOffset))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: hOffset))
                }
            }
            .stroke()
        }
    }
}



struct InteractiveImage: View {
    
    @State var lastScaleFactor: CGFloat = 1.0
    @State var scale: CGFloat
    @State var position: CGPoint = .zero
    @State var lastPosition: CGPoint = .zero
    
    let size: (width: Int, height: Int)
    
    init(width: Int, height: Int) {
        size = (width, height)
        _scale = State(initialValue: CGFloat(min(width, height)))
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: event.translation.width - lastPosition.x, y: event.translation.height - lastPosition.y)
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
                
                let newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                
                if Int(newPosition.x) + Int(scale) <= size.width && Int(newPosition.y) + Int(scale) < size.height && Int(newPosition.x) >= 0 && Int(newPosition.y) >= 0 {
                    self.position = newPosition
                    print(self.position, scale, size)
                }
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }
    
    var zoom: some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged({ factor in
                let delta = factor / self.lastScaleFactor
                self.lastScaleFactor = factor
                let scale = max(1.0, self.scale / delta)
                
                if Int(position.x) + Int(scale) <= size.width && Int(position.y) + Int(scale) < size.height && Int(position.x) >= 0 && Int(position.y) >= 0 {
                    self.scale = scale
                    print(self.position, scale, size)
                }
            })
            .onEnded({ factor in
                self.lastScaleFactor = 1.0
            })
    }
    
    var body: some View {
        ZStack {
            PixelBufferView(origin: position, scale: scale, size: size)
                .frame(maxWidth: 365, maxHeight: 365, alignment: .center)
//            Image("pixel_art")
//                .resizable()
//                .scaledToFit()
//            PixelGridImage(horizontalSpacing: 8, verticalSpacing: 8)
        }
        .frame(maxWidth: 365, alignment: .center)
        .border(Color(.black), width: 4)
        .gesture(zoom)
        .simultaneousGesture(drag)
        .mask(Rectangle().frame(width: 365, height: 365, alignment: .center))
    }
}


struct ContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            InteractiveImage(width: 64, height: 64)
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
