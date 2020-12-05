//
//  PixelBufferView.swift
//  Semixel
//
//  Created by Andrew Thompson on 31/10/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelBufferView: UIViewRepresentable {
    
    @Binding var image: PixelImage
    
    var origin: CGPoint {
        didSet {
            if !(Int(origin.x) + Int(scale) <= size.width && Int(origin.y) + Int(scale) <= size.height) {
                print("Reverting origin from: \(origin), to old value: \(oldValue)")
                origin = oldValue
            }
        }
    }
    
    var scale: CGFloat {
        didSet {
            if !(Int(origin.x) + Int(scale) <= size.width && Int(origin.y) + Int(scale) <= size.height) {
                print("Reverting origin from: \(scale), to old value: \(oldValue)")
                scale = oldValue
            }
        }
    }
    
    let size: (width: Int, height: Int)
    
    init(origin: CGPoint, scale: CGFloat, size: (width: Int, height: Int), image: Binding<PixelImage>) {
        if !(Int(origin.x) + Int(scale) <= size.width && Int(origin.y) + Int(scale) <= size.height) {
            fatalError()
        }
        self.origin = origin
        self.scale = scale
        self.size = size
        self._image = image
    }
    
    func updateUIView(_ view: BufferView, context: Context) {
        view.viewport = (Point2D(x: Int(origin.x), y: Int(origin.y)), Size2D(width: Int(scale), height: Int(scale)))
        view.img = image
    }
    
    func makeUIView(context: Context) -> BufferView {
        let view = BufferView(image: image, frame: CGRect(x: 0, y: 0, width: 128, height: 128))
        view.viewport = (Point2D(x: Int(origin.x), y: Int(origin.y)), Size2D(width: Int(scale), height: Int(scale)))
        return view
    }
    
    func makeCoordinator() -> () {
        return ()
    }
}

struct PixelImage {
    struct RGBA {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
        
        static var white: RGBA {
            return RGBA(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
    
    var buffer: [RGBA]
    private(set) var size: Size2D
    
    init(width: Int, height: Int) {
        buffer = [RGBA](repeating: .white, count: width * height)
        size = Size2D(width: width, height: height)
        
        for y in 0..<size.height {
            for x in 0..<size.width {
                
                let index = y * size.width + x
                var color = RGBA(red: 0, green: 0, blue: 0, alpha: 1)
                if index % 3 == 0 {
                    color.red = 1
                } else if index % 3 == 1 {
                    color.green = 1
                } else if index % 3 == 2 {
                    color.blue = 1
                }
                
                buffer[index] = color
            }
        }
    }
}

class BufferView: UIView {
    
    var img: PixelImage {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var viewport: (origin: Point2D, size: Size2D) {
        didSet {
            if !(viewport.origin.x >= 0
                    && viewport.origin.y >= 0
                    && img.size.width >= viewport.origin.x + viewport.size.width
                    && img.size.height >= viewport.origin.y + viewport.size.height) {
                fatalError()
            }
            setNeedsDisplay()
        }
    }
    
    init(image: PixelImage, frame: CGRect) {
        viewport = (.zero, image.size)
        img = image
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let scale = CGSize(width: frame.size.width/CGFloat(viewport.size.width),
                           height: frame.size.height/CGFloat(viewport.size.height))
        
        // Draw the buffer in the context scaling to the desired size.
        for y in 0..<viewport.size.height {
            for x in 0..<viewport.size.width {
                let rect = CGRect(x: scale.width * CGFloat(x),
                                  y: scale.height * CGFloat(y),
                                  width: scale.width,
                                  height: scale.height)
                let color = img.buffer[img.size.width * (viewport.origin.y + y) + (viewport.origin.x + x)]
                context.setFillColor(red: color.red,
                                     green: color.green,
                                     blue: color.blue,
                                     alpha: color.alpha)
                context.fill(rect)
            }
        }
    }
}
