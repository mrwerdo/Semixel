//
//  PixelViewV2.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct CursorDragGestureView<Content>: View {

    /// Controls how fast the cursor changes.
    var speed: CGFloat
    /// Defines the maximum and minimum position of the cursor.
    var size: CGSize
    
    @Binding
    var active: Bool
    
    private var content: Content
    
    @State
    private var lastPosition: CGPoint = .zero
    
    @State
    private var position: CGPoint = .zero
    
    init(speed: CGFloat, size: CGSize, active: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.speed = speed
        self.size = size
        self._active = active
        self.content = content()
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
                print(position)
//                updateTranslation(delta)
//                onDrag()
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }
    
    var body: some View {
            Rectangle()
//                .opacity(0.0)
                .stroke(Color.green)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .simultaneousGesture(drag)
    }
}

struct ColorTabV2: View {
    var tag: Int
    var color: PixelImage.RGBA
    @Binding var state: PixelImage.RGBA
    
    var body: some View {
        Button(action: {
            state = color
        }) {
            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(Color(CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)))
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 32, height: 32)
                Text("\(tag)")
                    .fixedSize()
                    .frame(width: 32, height: 32)
                if state == color {
                    RoundedRectangle(cornerRadius: 4)
                        .opacity(0.0)
                        .disabled(true)
                        .border(Color.secondary, width: 3)
                }
            }
            .frame(width: 64, height: 32)
            .mask(
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 64, height: 32, alignment: .center))
        }
    }
}

struct ColorPalette: View {
    
    @Binding var colors: [PixelImage.RGBA]
    @Binding var selectedColor: PixelImage.RGBA
    
    let numberOfColumns: Int = 1
    let numberOfRows: Int = 2
    
    func color(_ section: Int, x: Int, y: Int) -> PixelImage.RGBA? {
        let index = section * numberOfColumns * numberOfRows + y * numberOfRows + x
        if index < colors.count {
            return colors[index]
        }
        return nil
    }
    
    var numberOfSections: Int {
        let quotient = colors.count / (numberOfColumns * numberOfRows)
        let remainder = colors.count % (numberOfColumns * numberOfRows)
        return remainder > 0 ? quotient + 1 : quotient
    }
    
    var body: some View {
        TabView() {
            ForEach(0..<numberOfSections) { section in
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<numberOfColumns) { j in
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<numberOfRows) { i in
                                if let color = self.color(section, x: i, y: j) {
                                    ColorTabV2(tag: section * numberOfColumns * numberOfRows + j * numberOfRows + i,
                                               color: color,
                                               state: $selectedColor)
                                }
                            }
                        }.fixedSize()
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}

struct ToolButton: View {
    
    enum ButtonType {
        case oneshot
        case selectable
    }
    
    var action: ((ToolButton) -> ())?
    @Binding var state: ToolType?
    var tool: ToolType
    var type: ButtonType
    var image: String
    
    var isSelected: Bool {
        return state == tool
    }
    
    init(_ action: ((ToolButton) -> ())?, _ state: Binding<ToolType?>, _ type: ButtonType, _ object: ToolType, image: String) {
        self.action = action
        self.tool = object
        self.image = image
        _state = state
        self.type = type
    }
    
    var background: some View {
        if isSelected {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray4))
        } else {
            return RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground))
        }
    }
    
    private func update() {
        action?(self)
        switch type {
        case .oneshot:
            state = nil
        case .selectable:
            if state == tool {
                state = nil
            } else {
                state = tool
            }
        }
    }
    
    var body: some View {
        Button(action: update) {
            ZStack(alignment: .center) {
                background
                Image(systemName: image).font(Font.system(size: 24))
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}


protocol ToolButtonState: Equatable {
    associatedtype Icon: View
    var image: Icon { get }
    var isSelected: Bool { get }
    
    static var deselectedState: Self { get }
}

struct ToolButtonV2<State: ToolButtonState>: View {
    var tool: ToolType
    @Binding var selectedTool: ToolType?
    var transition: (State) -> State
    @SwiftUI.State var state: State = .deselectedState
    
    init(_ selectedTool: Binding<ToolType?>, tool: ToolType, transition: @escaping (State) -> State) {
        self._selectedTool = selectedTool
        self.tool = tool
        self.transition = transition
    }
    
    private func update() {
        if tool != selectedTool {
            state = State.deselectedState
        }
        let nextState = transition(state)
        state = nextState
        selectedTool = state == State.deselectedState ? nil : tool
    }
    
    private var isSelected: Bool {
        return state.isSelected && tool == selectedTool
    }
    
    var body: some View {
        Button(action: update) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(.systemGray4) : Color(.secondarySystemBackground))
                state.image
            }
            .frame(width: 64, height: 64, alignment: .center)
        }
    }
}

enum PencilState: ToolButtonState {
    case deselected
    case selected
    
    var image: some View {
        return Image(systemName: "pencil.tip").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self == .selected
    }
    
    static var deselectedState: PencilState {
        return .deselected
    }

    static func pencil(_ selectedTool: Binding<ToolType?>, _ draw: @escaping () -> ()) -> ToolButtonV2<PencilState> {
        return ToolButtonV2<PencilState>(selectedTool, tool: .pencil) { (state) -> PencilState in
            switch state {
            case .selected:
                return .deselected
            case .deselected:
                draw()
                return .selected
            }
        }
    }
}

enum SelectionState: ToolButtonState {
    case deselected
    case resizing
    case translating
    
    var image: some View {
        return Image(systemName: "selection.pin.in.out").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self != .deselected
    }
    
    static var deselectedState: SelectionState {
        return .deselected
    }
    
    static func selection(_ selectedTool: Binding<ToolType?>, resizing: @escaping () -> (), translating: @escaping () -> (), complete: @escaping () -> ()) -> ToolButtonV2<SelectionState> {
        return ToolButtonV2<SelectionState>(selectedTool, tool: .selection) { state -> SelectionState in
            switch state {
            case .deselected:
                resizing()
                return .resizing
            case .resizing:
                translating()
                return .translating
            case .translating:
                complete()
                return .deselected
            }
        }
    }
}

enum ShapeState: ToolButtonState {
    case deselected
    case resizing
    case translating
    
    var image: some View {
        return Image(systemName: "circle").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self != .deselected
    }
    
    static var deselectedState: ShapeState {
        return .deselected
    }
    
    static func selection(_ selectedTool: Binding<ToolType?>, resizing: @escaping () -> (), translating: @escaping () -> (), complete: @escaping () -> ()) -> ToolButtonV2<ShapeState> {
        return ToolButtonV2<ShapeState>(selectedTool, tool: .shape) { state -> ShapeState in
            switch state {
            case .deselected:
                resizing()
                return .resizing
            case .resizing:
                translating()
                return .translating
            case .translating:
                complete()
                return .deselected
            }
        }
    }
}

enum OneShotState: ToolButtonState {
    case deselected
    
    var image: some View {
        return Image(systemName: "paintbrush").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return false
    }
    
    static var deselectedState: OneShotState {
        return .deselected
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, selected: @escaping () -> ()) -> ToolButtonV2<OneShotState> {
        ToolButtonV2<OneShotState>(selectedTool, tool: .brush) { state -> OneShotState in
            selected()
            return .deselected
        }
    }
}



struct OverlayView: View {
    
    var pixelSize: CGSize
    var image: PixelImage
    var position: CGPoint
    
    var shapeStartPosition: Point2D?
    var shapeEndPosition: Point2D?
    var translation: CGPoint
    
    private var pencilPosition: CGPoint {
        let x = round(position.x / pixelSize.width)
        let y = round(position.y / pixelSize.height)
        return CGPoint(x: (x + 0.5) * pixelSize.width, y: (y + 0.5) * pixelSize.height)
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
    
    func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
    
    var pencilGridPosition: Point2D? {
        let size = image.size
        let p = convertToInteger(position) + Point2D(x: size.width, y: size.height)/2
        
        if p.x < 0 || p.y < 0 || p.x >= size.width || p.y >= size.height {
            return nil
        }
        
        return p
    }
    
    var body: some View {
        ZStack {
            PixelBufferView(pixelSize: pixelSize, image: image)
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
    }
}

struct PixelViewV2: View {
    @EnvironmentObject var artwork: Artwork
    @State var colors: [PixelImage.RGBA] = PixelImage.RGBA.defaultColorPalette
    @State var selectedColor: PixelImage.RGBA = PixelImage.RGBA.defaultColorPalette.first ?? PixelImage.RGBA.white
    @State var statusText: String = ""
    
    var size: CGSize {
        return CGSize(width: 32 * 12, height: 32 * 12)
    }
    
    var pixelSize: CGSize {
        return CGSize(width: 12, height: 12)
    }
    
    @State var fullScreenDragEnabled: Bool = false
    @State var tool: Tools.ToolType? = nil
    @State var position: CGPoint = .zero
    @State var lastPosition: CGPoint = .zero
    @State var speed: CGFloat = 0.8
    
    @State var shapeStartPosition: Point2D?
    @State var shapeEndPosition: Point2D?
    @State var translation: CGPoint = .zero

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
                onDrag(delta)
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }

    
    var pencilGridPosition: Point2D? {
        let size = artwork.pixelImage.size
        let p = convertToInteger(position) + Point2D(x: size.width, y: size.height)/2
        
        if !isValid(p) {
            return nil
        }
        
        return p
    }
    
    func isValid(_ p: Point2D) -> Bool {
        let size = artwork.pixelImage.size
        return !(p.x < 0 || p.y < 0 || p.x >= size.width || p.y >= size.height)
    }
    
    func translatedShape(p1: Point2D, p2: Point2D) -> PixelImage {
        let p3 = convertToInteger(translation)
        let a = p1 + p3
        let b = p2 + p3
        
        if isValid(a) && isValid(b) {
            return artwork.pixelImage.drawEllipse(from: a, to: b, color: selectedColor)
        } else {
            return artwork.pixelImage
        }
    }
    
    var composedImage: PixelImage {
        if let p1 = shapeStartPosition, tool == .shape {
            // Render shape on top of the image.
            
            if let p2 = shapeEndPosition {
                return translatedShape(p1: p1, p2: p2)
            } else if let p2 = pencilGridPosition {
                return artwork.pixelImage.drawEllipse(from: p1, to: p2, color: selectedColor)
            } else {
                print("warning: could not get pencil position!")
                return artwork.pixelImage
            }
            
            // draw line in this case...
//            return image.drawLine(from: p1, to: p2, color: c)
        } else if tool == .selection, let p1 = shapeStartPosition, let p2 = shapeEndPosition {
            // Grab the pixels in the rectangle between p1 and p2, draw each one translated by p3.
            return artwork.pixelImage.moveRectangle(between: p1, and: p2, by: convertToInteger(translation))
        } else {
            return artwork.pixelImage
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            OverlayView(pixelSize: pixelSize,
                        image: composedImage,
                        position: position,
                        shapeStartPosition: shapeStartPosition,
                        shapeEndPosition: shapeEndPosition,
                        translation: translation)
                .frame(maxWidth: size.width, maxHeight: size.height)
                .gesture(drag)
                .padding()
            Spacer()
            Text(statusText)
            ZStack {
                HStack {
                    Spacer()
                    HStack {
                        VStack {
                            PencilState.pencil($tool) {
                                reset()
                                statusText = "Pencil selected."
                                if let p = pencilGridPosition {
                                    applyPencil(p)
                                }
                            }
                            ShapeState.selection($tool) {
                                reset()
                                statusText = "Shape tool."
                                if let point = pencilGridPosition {
                                    shapeStartPosition = point
                                }
                            } translating: {
                                statusText = "Translating..."
                                if shapeStartPosition != nil {
                                    translation = .zero
                                    shapeEndPosition = pencilGridPosition
                                    let p = convertToInteger(position)
                                    position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
                                }
                            } complete: {
                                statusText = "Complete."
                                if let start = shapeStartPosition, let end = shapeEndPosition {
                                    artwork.pixelImage = translatedShape(p1: start, p2: end)
                                }
                                shapeStartPosition = nil
                            }
                            ToolButton(selected, $tool, .oneshot, .undo, image: "arrow.uturn.left")
                        }
                        VStack {
                            OneShotState.create($tool) {
                                statusText = "Applied paint bucket."
                                if let p = pencilGridPosition {
                                    let oldColor = artwork.pixelImage[p]
                                    let points = artwork.pixelImage.floodSearch(at: p) { (_, c) -> Bool in c == oldColor }
                                    for point in points {
                                        artwork.pixelImage[point] = selectedColor
                                    }
                                }
                            }
                            
                            SelectionState.selection($tool) {
                                reset()
                                statusText = "Selection tool."
                                if let point = pencilGridPosition {
                                    shapeStartPosition = point
                                }
                            } translating: {
                                statusText = "Translating..."
                                if shapeStartPosition != nil {
                                    translation = .zero
                                    shapeEndPosition = pencilGridPosition
                                    let p = convertToInteger(position)
                                    position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
                                }
                            } complete: {
                                statusText = "Complete."
                                if let p2 = shapeEndPosition {
                                    if let p1 = shapeStartPosition {
                                        artwork.pixelImage = artwork.pixelImage.moveRectangle(between: p1, and: p2, by: convertToInteger(translation))
                                    }
                                    shapeEndPosition = nil
                                    shapeStartPosition = nil
                                }
                            }

                            ToolButton(selected, $tool, .oneshot, .redo, image: "arrow.uturn.right")
                        }
                    }.padding([.top, .bottom, .leading])
                    ColorPalette(colors: $colors, selectedColor: $selectedColor)
                        .padding([.top, .bottom, .trailing])
                    Spacer()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .ignoresSafeArea())
        }
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarTitle(artwork.name, displayMode: .inline)
    }
    
    
    func onDrag(_ delta: CGPoint) {
        if let p = pencilGridPosition {
            if tool == nil {
                statusText = ("(x: \(p.x), y: \(p.y))")
            }
            if tool == .pencil {
                applyPencil(p)
            }
        }
        updateTranslation(delta)
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
                                CGFloat(artwork.pixelImage.size.width - p2.x) * pixelSize.width))
        translation.y = max(CGFloat(-p1.y) * pixelSize.height,
                            min(translation.y + delta.y,
                                CGFloat(artwork.pixelImage.size.height - p2.y) * pixelSize.height))
    }
    
    func selected(_ button: ToolButton) {

    }
    
    func reset() {
        shapeStartPosition = nil
        shapeEndPosition = nil
        translation = .zero
    }
    
    func applyPencil(_ p: Point2D) {
        artwork.pixelImage[p] = selectedColor
    }

    func convertToInteger(_ p: CGPoint) -> Point2D {
        return Point2D(x: Int(round(p.x / pixelSize.width)), y: Int(round(p.y / pixelSize.height)))
    }
}

