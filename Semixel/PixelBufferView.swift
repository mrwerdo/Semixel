//
//  PixelBufferView.swift
//  Semixel
//
//  Created by Andrew Thompson on 31/10/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelBufferView: UIViewRepresentable {
    
    var pixelSize: CGSize
    var image: PixelImage<RGBA>
        
    var size: CGSize {
        return CGSize(width: CGFloat(image.size.width) * pixelSize.width,
                      height: CGFloat(image.size.height) * pixelSize.height)
    }
    
    init(pixelSize: CGSize, image: PixelImage<RGBA>) {
        self.pixelSize = pixelSize
        self.image = image
    }
    
    func updateUIView(_ view: BufferView, context: Context) {
        view.image = image
        view.pixelSize = pixelSize
    }
    
    func makeUIView(context: Context) -> BufferView {
        return BufferView(image: image, pixelSize: pixelSize, frame: CGRect(origin: .zero, size: pixelSize))
    }
    
    func makeCoordinator() -> () {
        return ()
    }
}

class BufferView: UIView {
    
    var pixelSize: CGSize {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var image: PixelImage<RGBA> {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(image: PixelImage<RGBA>, pixelSize: CGSize, frame: CGRect) {
        self.image = image
        self.pixelSize = pixelSize
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw the buffer in the context scaling to the desired size.
        for y in 0..<image.size.height {
            for x in 0..<image.size.width {
                let rect = CGRect(x: pixelSize.width * CGFloat(x),
                                  y: pixelSize.height * CGFloat(y),
                                  width: pixelSize.width,
                                  height: pixelSize.height)
                let color = image.buffer[image.size.width * y + x]
                context.setFillColor(red: color.red,
                                     green: color.green,
                                     blue: color.blue,
                                     alpha: color.alpha)
                context.fill(rect)
            }
        }
    }
}
