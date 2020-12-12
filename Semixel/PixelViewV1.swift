//
//  PixelView.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

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
            if verticalSpacing > 1 && horizontalSpacing > 1 {
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
}

struct TouchDownButton<Label: View>: View {
    
    @Binding var state: Bool
    var started: (() -> ())?
    var ended: (() -> ())?
    var label: () -> Label
    
    var touchDownGesture: some Gesture {
        
        let touchDown = LongPressGesture(minimumDuration: 0)
            .onEnded { _ in
                state = true
                started?()
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

struct PixelViewV1: View {
    
    @State var tool: Tools.ToolType = .pencil
    @State var color: Color = Color(.systemBlue)
    
    @EnvironmentObject var artwork: Artwork
    
    var image: PixelImage {
        get {
            return artwork.pixelImage
        }
        nonmutating set {
            artwork.pixelImage = newValue
        }
    }
    
    @State var position: CGPoint = .zero
    @State var depressed: Bool = false
    @State var shapeStartPosition: Point2D? = nil
    @State var shapeEndPosition: Point2D? = nil
    @State var translation: CGPoint = .zero
    @State var lastPosition: CGPoint = .zero
    
    @State var speed: CGFloat = 0.8
    
    var size: CGSize {
        return CGSize(width: CGFloat(image.size.width) * pixelSize.width,
                      height: CGFloat(image.size.height) * pixelSize.height)
    }
    
    var pixelSize: CGSize {
        return CGSize(width: 384 / CGFloat(image.size.width), height: 384 / CGFloat(image.size.height))
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: speed * (event.translation.width - lastPosition.x),
                                    y: speed * (event.translation.height - lastPosition.y))
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
                var newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                
                newPosition.x = max(-size.width/2, min(newPosition.x, size.width/2 - 12))
                newPosition.y = max(-size.height/2, min(newPosition.y, size.height/2 - 12))
                
                self.position = newPosition
                updateTranslation(delta)
                onDrag()
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }
    
    var composedImage: PixelImage {
        if let p1 = shapeStartPosition, tool == .shape {
            // Render shape on top of the image.
            guard let p2 = pencilGridPosition else {
                print("warning: could not get pencil position!")
                return image
            }
            
            guard let c = PixelImage.RGBA(color) else {
                print("warning: could not get current color")
                return image
            }
            
            // draw line in this case...
            return image.drawEllipse(from: p1, to: p2, color: c)
//            return image.drawLine(from: p1, to: p2, color: c)
        } else if tool == .selection, let p1 = shapeStartPosition, let p2 = shapeEndPosition {
            // Grab the pixels in the rectangle between p1 and p2, draw each one translated by p3.
            return image.moveRectangle(between: p1, and: p2, by: convertToInteger(translation))
        } else {
            return image
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack {
                PixelBufferView(pixelSize: pixelSize, image: composedImage)
                    .frame(maxWidth: size.width, maxHeight: size.height, alignment: .center)
                PixelGridImage(horizontalSpacing: pixelSize.width, verticalSpacing: pixelSize.height)
                
                
                if let p1 = shapeStartPosition {
                    if let p2 = shapeEndPosition {
                        selectionView(p1: p1, p2: p2, offset: convertToInteger(translation))
                    } else if let p2 = pencilGridPosition {
                        selectionView(p1: p1, p2: p2, offset: .zero)
                    }
                }
                
                Rectangle()
                    .opacity(0.0)
                    .frame(width: pixelSize.width, height: pixelSize.height , alignment: .center)
                    .border(Color(.systemRed), width: 2)
                    .offset(x: pencilPosition.x, y: pencilPosition.y)
                Image(systemName: "pencil")
                    .renderingMode(Image.TemplateRenderingMode.template)
                    .foregroundColor(Color(.white))
                    .offset(x: position.x + pixelSize.width, y: position.y)
            }
            .frame(maxWidth: size.width, maxHeight: size.height, alignment: .center)
            .gesture(drag)
            .mask(Rectangle().frame(width: size.width, height: size.height, alignment: .center))
            .padding(2)
            .border(Color(.secondarySystemBackground), width: 2)
            
            Tools(tool: $tool) { button in
                if button.object != tool {
                    reset()
                }
            }
            
            HStack(spacing: 8) {
                ColorTab(tag: 1, color: Color(.systemBlue), selected: selected)
                ColorTab(tag: 2, color: Color(.systemGreen), selected: selected)
                ColorTab(tag: 3, color: Color(.systemIndigo), selected: selected)
                ColorTab(tag: 4, color: Color(.systemOrange), selected: selected)
                ColorTab(tag: 5, color: Color(.systemPink), selected: selected)
            }.padding([.bottom], 8)
            TouchDownButton(state: $depressed, started: interactionStarted, ended: interactionEnded) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 200, height: 100, alignment: .center)
                    Text("Push").font(.largeTitle)
                }
            }
        }
    }
    
    private var pencilPosition: CGPoint {
        let x = round(position.x / pixelSize.width)
        let y = round(position.y / pixelSize.height)
        return CGPoint(x: (x + 0.5) * pixelSize.width, y: (y + 0.5) * pixelSize.height)
    }
    
    var pencilGridPosition: Point2D? {
        let p = convertToInteger(position) + Point2D(x: image.size.width, y: image.size.height)/2
        
        if p.x < 0 || p.y < 0 || p.x >= image.size.width || p.y >= image.size.height {
            return nil
        }
        
        return p
    }
    
    func reset() {
        shapeStartPosition = nil
        shapeEndPosition = nil
        translation = .zero
    }
    
    func updateTranslation(_ delta: CGPoint) {
        // Update `translation` ensuring that the selection rectangle defined by
        // `shapeStartPosition` and `shapeEndPosition` do not go outside of the bounds of the image.
        // Translation is measured in terms of pixels (i.e. CGFloats) while the image is measured
        // in terms of points (i.e. Ints)
        
        guard let a = shapeStartPosition, let b = shapeEndPosition else {
            return
        }
        
        let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
        let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
        
        translation.x = max(CGFloat(-p1.x) * pixelSize.width,
                            min(translation.x + delta.x,
                                CGFloat(image.size.width - p2.x) * pixelSize.width))
        translation.y = max(CGFloat(-p1.y) * pixelSize.height,
                            min(translation.y + delta.y,
                                CGFloat(image.size.height - p2.y) * pixelSize.height))
    }
    
    func selectionView(p1 a: Point2D, p2 b: Point2D, offset: Point2D) -> some View {
        let p1 = Point2D(x: min(a.x, b.x), y: min(a.y, b.y))
        let p2 = Point2D(x: max(a.x, b.x) + 1, y: max(a.y, b.y) + 1)
        
        let x = CGFloat(p1.x + p2.x - image.size.width + 2 * offset.x)/2 * pixelSize.width
        let y = CGFloat(p1.y + p2.y - image.size.height + 2 * offset.y)/2 * pixelSize.height
        
        let w = CGFloat(abs(p2.x - p1.x)) * pixelSize.width
        let h = CGFloat(abs(p2.y - p1.y)) * pixelSize.height
        
        return Rectangle()
            .opacity(0.0)
            .frame(width: w, height: h, alignment: .center)
            .border(Color(.gray), width: 2)
            .offset(x: x, y: y)
    }
    
    func selected(_ colortab: ColorTab) {
        color = colortab.color
    }
    
    func onDrag() {
        if depressed, tool == .pencil, let p = pencilGridPosition, let c = PixelImage.RGBA(color) {
            applyPencil(p, c)
        }
    }
    
    func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
    
    func interactionStarted() {
        guard let p = pencilGridPosition, let c = PixelImage.RGBA(color) else {
            return
        }
        
        if tool == .shape {
            startShape(p, c)
        } else if tool == .selection {
            startSelection(p, c)
        }
    }
    
    func interactionEnded() {
        guard let p = pencilGridPosition, let c = PixelImage.RGBA(color) else {
            return
        }
        
        switch tool {
        case .pencil:
            applyPencil(p, c)
        case .brush:
            applyPaintBucket(p, c)
        case .shape:
            endShape(p, c)
        case .selection:
            endSelection(p, c)
        default:
            print("tool: \(tool), color: \(color)")
        }
    }
    
    func applyPencil(_ p: Point2D, _ color: PixelImage.RGBA) {
        image[p] = color
    }
    
    func applyPaintBucket(_ p: Point2D, _ color: PixelImage.RGBA) {
        // actually works like a paint bucket, but who cares...
        let oldColor = image[p]
        let points = image.floodSearch(at: p) { (_, c) -> Bool in c == oldColor }
        for point in points {
            image[point] = color
        }
    }
    
    func startShape(_ point: Point2D, _ color: PixelImage.RGBA) {
        shapeStartPosition = point
    }
    
    func endShape(_ point: Point2D, _ color: PixelImage.RGBA) {
        if let start = shapeStartPosition {
            image = image.drawEllipse(from: start, to: point, color: color)
            shapeStartPosition = nil
        }
    }
    
    func startSelection(_ point: Point2D, _ color: PixelImage.RGBA) {
        if shapeStartPosition == nil {
            shapeStartPosition = point
        }
    }
    
    func endSelection(_ point: Point2D, _ color: PixelImage.RGBA) {
        if let p2 = shapeEndPosition {
            if let p1 = shapeStartPosition {
                image = image.moveRectangle(between: p1, and: p2, by: convertToInteger(translation))
            }
            shapeEndPosition = nil
            shapeStartPosition = nil
        } else if shapeStartPosition != nil {
            translation = .zero
            shapeEndPosition = pencilGridPosition
            let p = convertToInteger(position)
            position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
        }
    }
}
