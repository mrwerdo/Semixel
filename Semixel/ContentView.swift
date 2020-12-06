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
    
    var dragStarted: (() -> ())?
    var dragCompleted: (() -> ())?
    
    let size: (width: Int, height: Int)
    
    init(image: Binding<PixelImage>, position: Binding<CGPoint>, dragStarted: (() -> ())? = nil, dragCompleted: (() -> ())? = nil) {
        _position = position
        size = (image.wrappedValue.size.width, image.wrappedValue.size.height)
        _scale = State(initialValue: CGFloat(min(size.width, size.height)))
        _image = image
        self.dragStarted = dragStarted
        self.dragCompleted = dragCompleted
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: event.translation.width - lastPosition.x, y: event.translation.height - lastPosition.y)
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)

                let newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                self.position = newPosition
                dragStarted?()
            })
            .onEnded({ delta in
                self.lastPosition = .zero
                dragCompleted?()
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
    
    private let length: CGFloat = 384
    
    private var pixelPosition: CGPoint {
        let x = round(position.x / 12)
        let y = round(position.y / 12)
        return CGPoint(x: x * 12 + 6, y: y * 12 + 6)
    }
    
    var body: some View {
        ZStack {
            PixelBufferView(origin: .zero, scale: scale, size: size, image: $image)
                .frame(maxWidth: length, maxHeight: length, alignment: .center)
            Rectangle()
                .opacity(0.0)
                .frame(width: 12, height: 12, alignment: .center)
                .border(Color(.systemRed), width: 2)
                .offset(x: pixelPosition.x, y: pixelPosition.y)
            Image(systemName: "pencil")
                .renderingMode(Image.TemplateRenderingMode.template)
                .foregroundColor(Color(.white))
                .offset(x: position.x + 12, y: position.y)
        }
        .frame(maxWidth: length, alignment: .center)
        .gesture(drag)
        .mask(Rectangle().frame(width: length, height: length, alignment: .center))
        .padding(2)
        .border(Color(.secondarySystemBackground), width: 2)
    }
}

struct TouchDownButton<Label: View>: View {
    
    @Binding var state: Bool
    var label: () -> Label
    var ended: (() -> ())?
    
    var touchDownGesture: some Gesture {
        
        let touchDown = LongPressGesture(minimumDuration: 0)
            .onEnded { _ in
                state = true
            }
        
        let touchEnded = DragGesture(minimumDistance: 0)
            .onEnded { _ in
                state = false
                ended?()
            }
        
        return SimultaneousGesture(touchDown, touchEnded)
    }
    
    var body: some View {
        label()
        .gesture(touchDownGesture)
    }
}

struct ContentView: View {
    
    @State var tool: Tools.ToolType = .pencil
    @State var color: Color = Color(.systemBlue)
    @State var image: PixelImage = PixelImage(width: 32, height: 32)
    @State var position: CGPoint = .zero
    @State var depressed: Bool = false
    
    func selected(_ colortab: ColorTab) {
        color = colortab.color
    }
    
    func onDrag() {
        if depressed {
            push()
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            InteractiveImage(image: $image, position: $position, dragStarted: onDrag)
            Tools(tool: $tool)
            HStack(spacing: 8) {
                ColorTab(tag: 1, color: Color(.systemBlue), selected: selected)
                ColorTab(tag: 2, color: Color(.systemGreen), selected: selected)
                ColorTab(tag: 3, color: Color(.systemIndigo), selected: selected)
                ColorTab(tag: 4, color: Color(.systemOrange), selected: selected)
                ColorTab(tag: 5, color: Color(.systemPink), selected: selected)
            }.padding([.bottom], 8)
            TouchDownButton(state: $depressed) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 200, height: 100, alignment: .center)
                    Text("Push").font(.largeTitle)
                }
            } ended: {
                push()
            }
        }
    }
    
    func push() {
        let scale = CGFloat(384 / 32.0)
        let x = Int(round(position.x / scale)) + image.size.width/2
        let y = Int(round(position.y / scale)) + image.size.height/2
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        if x < 0 || y < 0 || x >= image.size.width || y >= image.size.height {
            return
        }
        
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            print("warning: could not get rgb components from the selected color!")
            return
        }
        
        let c = PixelImage.RGBA(red: r, green: g, blue: b, alpha: a)

        switch tool {
        case .pencil:
            pencil(x, y, c)
        case .brush:
            brush(x, y, c)
        default:
            print("tool: \(tool), color: \(color)")
        }
    }
    
    func pencil(_ x: Int, _ y: Int, _ color: PixelImage.RGBA) {
        image[x, y] = color
    }
    
    func brush(_ x: Int, _ y: Int, _ color: PixelImage.RGBA) {
        // actually works like a paint bucket, but who cares...
        let oldColor = image[x, y]
        let points = image.floodSearch(at: x, y: y) { (_, c) -> Bool in c == oldColor }
        for point in points {
            image[point] = color
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
