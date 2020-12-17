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

class SemanticColor: Equatable {
    var label: String
    var color: PixelImage.RGBA
    
    init(label: String, color: PixelImage.RGBA) {
        self.label = label
        self.color = color
    }
    
    static func ==(lhs: SemanticColor, rhs: SemanticColor) -> Bool {
        return lhs.label == rhs.label && lhs.color == rhs.color
    }
}

extension SemanticColor {
    var cgColor: CGColor {
        get {
            return CGColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        }
        set {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if UIColor(cgColor: newValue).getRed(&r, green: &g, blue: &b, alpha: &a) {
                color = PixelImage.RGBA(red: r, green: g, blue: b, alpha: a)
            }
        }
    }
}

struct ColorPalette: View {
    @Binding var colors: [SemanticColor]
    @Binding var selectedColor: SemanticColor
    
    @State var isAddingNewColor = false
    
    func addCallback() {
        print("Adding new color...")
    }
    
    var body: some View {
        VStack {
            ColorPicker("", selection: $selectedColor.cgColor, supportsOpacity: true)
            CollectionView(colors: colors, selectedColor: $selectedColor, addCallback: addCallback)
        }
        .padding([.top], 12)
        .padding([.leading, .trailing], 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.secondarySystemFill)))
    }
}


protocol ToolButtonState: Equatable {
    associatedtype Icon: View
    var image: Icon { get }
    var isSelected: Bool { get }
    
    static var deselected: Self { get }
    static var tool: ToolType { get }
}

struct ToolButtonV2<State: ToolButtonState>: View {
    var tool: ToolType
    @Binding var selectedTool: ToolType?
    var transition: (State) -> State
    @SwiftUI.State var state: State = .deselected
    
    init(_ selectedTool: Binding<ToolType?>, tool: ToolType, transition: @escaping (State) -> State) {
        self._selectedTool = selectedTool
        self.tool = tool
        self.transition = transition
    }
    
    private func update() {
        if tool != selectedTool {
            state = State.deselected
        }
        let nextState = transition(state)
        state = nextState
        selectedTool = state == State.deselected ? nil : tool
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

protocol BinaryState: ToolButtonState {
    static var selected: Self { get }
    static var deselected: Self { get }
}

extension BinaryState {
    var image: some View {
        return Image(systemName: "pencil.tip").font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self == .selected
    }

    static func create(_ selectedTool: Binding<ToolType?>, _ draw: @escaping () -> ()) -> ToolButtonV2<Self> {
        return ToolButtonV2<Self>(selectedTool, tool: .pencil) { (state) -> Self in
            switch state {
            case .selected:
                return .deselected
            case .deselected:
                draw()
                return .selected
            default:
                fatalError("BinaryState can have only two states.")
            }
        }
    }
}

enum PencilState: BinaryState {
    case deselected
    case selected
    static var tool: ToolType {
        return .pencil
    }
}

protocol TerneryState: ToolButtonState {
    static var deselected: Self { get }
    static var resizing: Self { get }
    static var translating: Self { get }
}

extension TerneryState {
    var image: some View {
        return Image(systemName: Self.tool.iconName).font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return self != .deselected
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, resizing: @escaping () -> (), translating: @escaping () -> (), complete: @escaping () -> ()) -> ToolButtonV2<Self> {
        return ToolButtonV2<Self>(selectedTool, tool: Self.tool) { state -> Self in
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
            default:
                fatalError("TerneryState should not have more than three cases.")
            }
        }
    }
}

enum SelectionState: TerneryState {
    case deselected
    case resizing
    case translating
    
    static var tool: ToolType { return .selection }
}

enum ShapeState: TerneryState {
    case deselected
    case resizing
    case translating
    
    static var tool: ToolType { return .shape }
}

protocol OneShotState: ToolButtonState { }

extension OneShotState {
    var image: some View {
        return Image(systemName: Self.tool.iconName).font(Font.system(size: 24))
    }
    
    var isSelected: Bool {
        return false
    }
    
    static func create(_ selectedTool: Binding<ToolType?>, selected: @escaping () -> ()) -> ToolButtonV2<Self> {
        ToolButtonV2<Self>(selectedTool, tool: Self.tool) { state -> Self in
            selected()
            return state
        }
    }
}

struct PaintBucketState: OneShotState {
    static var tool: ToolType {
        return .brush
    }
    
    static var deselected: PaintBucketState {
        return PaintBucketState()
    }
}

struct UndoState: OneShotState {
    static var tool: ToolType {
        return .undo
    }
    
    static var deselected: UndoState {
        return UndoState()
    }
}

struct RedoState: OneShotState {
    static var tool: ToolType {
        return .redo
    }
    
    static var deselected: RedoState {
        return RedoState()
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
    @State var colors: [SemanticColor] = PixelImage.RGBA
        .defaultColorPalette
        .enumerated()
        .map {
            SemanticColor(label: "\($0)", color: $1)
        }
    
    var selectedColor: PixelImage.RGBA {
        return selectedObject.color
    }
    
    @State var selectedObject = SemanticColor(label: "0", color: PixelImage.RGBA.defaultColorPalette.first ?? PixelImage.RGBA.white)
    @State var statusText: String = ""
    
    var size: CGSize {
        return CGSize(width: 32 * 12, height: 32 * 12)
    }
    
    var pixelSize: CGSize {
        return CGSize(width: 12, height: 12)
    }
    
    @State var fullScreenDragEnabled: Bool = false
    @State var tool: ToolType? = nil
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
                            PencilState.create($tool) {
                                reset()
                                statusText = "Pencil selected."
                                if let p = pencilGridPosition {
                                    applyPencil(p)
                                }
                            }
                            ShapeState.create($tool,
                                              resizing: resizing(statusText: "Shape tool."),
                                              translating: translating,
                                              complete: completed { (p1, p2, offset) in
                                    artwork.pixelImage = translatedShape(p1: p1, p2: p2)
                            })
                            UndoState.create($tool) {
                                statusText = "Undone"
                            }
                        }
                        VStack {
                            PaintBucketState.create($tool) {
                                statusText = "Applied paint bucket."
                                if let p = pencilGridPosition {
                                    let oldColor = artwork.pixelImage[p]
                                    let points = artwork.pixelImage.floodSearch(at: p) { (_, c) -> Bool in c == oldColor }
                                    for point in points {
                                        artwork.pixelImage[point] = selectedColor
                                    }
                                }
                            }
                            
                            SelectionState.create($tool,
                                                  resizing: resizing(statusText: "Selection tool."),
                                                  translating: translating,
                                                  complete: completed { (p1, p2, offset) in
                                                    artwork.pixelImage = artwork.pixelImage.moveRectangle(between: p1,
                                                                                                          and: p2,
                                                                                                          by: offset)
                                                  })
                            RedoState.create($tool) {
                                statusText = "Redone"
                            }
                        }
                    }.padding([.top, .bottom, .leading])
                    ColorPalette(colors: $colors, selectedColor: $selectedObject)
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
    
    func resizing(statusText: String) -> () -> () {
        return {
            reset()
            self.statusText = statusText
            if let point = pencilGridPosition {
                shapeStartPosition = point
            }
        }
    }
    
    func translating() {
        statusText = "Translating..."
        if shapeStartPosition != nil {
            translation = .zero
            shapeEndPosition = pencilGridPosition
            let p = convertToInteger(position)
            position = CGPoint(x: CGFloat(p.x) * pixelSize.height, y: CGFloat(p.y) * pixelSize.height)
        }
    }
    
    func completed(callback: @escaping (_ p1: Point2D, _ p2: Point2D, _ offset: Point2D) -> ()) -> () -> () {
        return {
            statusText = "Complete."
            if let p2 = shapeEndPosition {
                if let p1 = shapeStartPosition {
                    callback(p1, p2, convertToInteger(translation))
                }
                shapeEndPosition = nil
                shapeStartPosition = nil
            }
        }
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

