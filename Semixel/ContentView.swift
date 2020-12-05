//
//  ContentView.swift
//  Semixel
//
//  Created by Andrew Thompson on 9/7/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct BigButton<T>: View where T: Equatable {
    
    
    @Binding var state: T
    var object: T
    var image: String
    
    var isSelected: Bool {
        return state == object
    }
    
    init(_ state: Binding<T>, _ object: T, image: String) {
        self.object = object
        self.image = image
        _state = state
    }
    
    var background: some View {
        if isSelected {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemFill))
        } else {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
        }
    }
    
    var body: some View {
        Button(action: {
            print("button tapped")
            state = object
        }) {
            ZStack(alignment: .center) {
                background
                Image(systemName: image).font(Font.system(size: 36))
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}

struct Tools: View {
    
    enum ToolType: Equatable {
        case pencil
        case brush
        case shape
        case none
    }
    
    @Binding var tool: ToolType
    
    func selected(_ tool: ToolType) {
        self.tool = tool
    }
    
    typealias ToolButton = BigButton<ToolType>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ToolButton($tool, .pencil, image: "pencil.tip")
                ToolButton($tool, .brush, image: "paintbrush")
                ToolButton($tool, .shape, image: "circle")
                ToolButton($tool, .none, image: "minus")
                ToolButton($tool, .none, image: "square.on.circle")
            }
            HStack {
                ToolButton($tool, .none, image: "selection.pin.in.out")
                ToolButton($tool, .none, image: "magnifyingglass")
                ToolButton($tool, .none, image: "arrow.uturn.left")
                ToolButton($tool, .none, image: "arrow.uturn.right")
                ToolButton($tool, .none, image: "rotate.left")
            }
        }
    }
}

struct ColorTab: View {
    var tag: Int
    var color: Color
    
    var selected: ((ColorTab) -> ())? = nil
    
    var body: some View {
        Button(action: {
            print("color tab tapped")
            selected?(self)
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
    @Binding var position: CGPoint
    @State var lastPosition: CGPoint = .zero
    @Binding var image: PixelImage
    
    let size: (width: Int, height: Int)
    
    init(image: Binding<PixelImage>, position: Binding<CGPoint>) {
        _position = position
        size = (image.wrappedValue.size.width, image.wrappedValue.size.height)
        _scale = State(initialValue: CGFloat(min(size.width, size.height)))
        _image = image
    }
    
    var drag: some Gesture {
//        DragGesture()
//            .onChanged({ event in
//                let delta = CGPoint(x: event.translation.width - lastPosition.x, y: event.translation.height - lastPosition.y)
//                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
//
//                let newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
//
//                if Int(newPosition.x) + Int(scale) <= size.width && Int(newPosition.y) + Int(scale) < size.height && Int(newPosition.x) >= 0 && Int(newPosition.y) >= 0 {
//                    self.position = newPosition
//                    print(self.position, scale, size)
//                }
//            })
//            .onEnded({ delta in
//                self.lastPosition = .zero
//            })
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: event.translation.width - lastPosition.x, y: event.translation.height - lastPosition.y)
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)

                let newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                self.position = newPosition
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
            PixelBufferView(origin: .zero, scale: scale, size: size, image: $image)
                .frame(maxWidth: 365, maxHeight: 365, alignment: .center)
            Image(systemName: "pencil")
                .renderingMode(Image.TemplateRenderingMode.template).foregroundColor(Color(.white)).border(Color(.systemBlue), width: 4)
                .offset(x: position.x + 2, y: position.y + 2)
//                .position(position)
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
    
    @State var tool: Tools.ToolType = .pencil
    @State var color: Color = Color(.systemBlue)
    @State var image: PixelImage = PixelImage(width: 32, height: 32)
    @State var position: CGPoint = .zero
    
    func selected(_ colortab: ColorTab) {
        color = colortab.color
    }
    
    var body: some View {
        VStack(alignment: .center) {
            InteractiveImage(image: $image, position: $position)
            Tools(tool: $tool)
            HStack(spacing: 8) {
                ColorTab(tag: 1, color: Color(.systemBlue), selected: selected)
                ColorTab(tag: 2, color: Color(.systemGreen), selected: selected)
                ColorTab(tag: 3, color: Color(.systemIndigo), selected: selected)
                ColorTab(tag: 4, color: Color(.systemOrange), selected: selected)
                ColorTab(tag: 5, color: Color(.systemPink), selected: selected)
            }.padding([.bottom], 8)
            Button(action: push, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 200, height: 100, alignment: .center)
                    Text("Push").font(.largeTitle)
                }
            })
        }
    }
    
    func push() {
        switch tool {
        case .pencil:
            let scale = CGFloat(365.0 / 32.0)
            let x = Int(round(position.x / scale)) + image.size.width/2
            let y = Int(round(position.y / scale)) + image.size.height/2
            var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            
            
            if UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) {
                print("tool: \(tool), position: \(x), \(y), color: \(r), \(g), \(b), \(a)")
                image.buffer[y * image.size.width + x] = PixelImage.RGBA(red: r, green: g, blue: b, alpha: a)
            }
        default:
            print("tool: \(tool), color: \(color)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
