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
    var centered: Bool
    
    var size: CGSize {
        return CGSize(width: CGFloat(image.size.width) * pixelSize.width,
                      height: CGFloat(image.size.height) * pixelSize.height)
    }
    
    init(pixelSize: CGSize, image: PixelImage<RGBA>, centered: Bool = false) {
        self.pixelSize = pixelSize
        self.image = image
        self.centered = centered
    }
    
    func updateUIView(_ view: BufferView, context: Context) {
        view.image = image
        view.pixelSize = pixelSize
        view.centered = centered
    }
    
    func makeUIView(context: Context) -> BufferView {
        return BufferView(image: image, pixelSize: pixelSize, centered: centered, frame: CGRect(origin: .zero, size: pixelSize))
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
    
    var centered: Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(image: PixelImage<RGBA>, pixelSize: CGSize, centered: Bool, frame: CGRect) {
        self.image = image
        self.pixelSize = pixelSize
        self.centered = centered
        super.init(frame: frame)
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw the buffer in the context scaling to the desired size.
        let fsize = CGSize(width: floor(pixelSize.width), height: floor(pixelSize.height))
        let error = pixelSize - fsize
        
        // The algorithm here keeps track of pixel misplacement and adjusts the size of the
        // rectangles accordingly to prevent gaps in between the rectangles.
        
        var origin = CGPoint(x: 0, y: 0)
        if image.size.width > image.size.height && centered {
            origin.y = pixelSize.height * CGFloat(image.size.width - image.size.height) / 2
        } else if image.size.height > image.size.width && centered {
            origin.x = pixelSize.width * CGFloat(image.size.height - image.size.width) / 2
        }
        
        var yp: CGFloat = origin.y
        var yerror: CGFloat = 0
        for y in 0..<image.size.height {
            var xp: CGFloat = origin.x
            var xerror: CGFloat = 0
            for x in 0..<image.size.width {
                
                var rect = CGRect(x: xp,
                                  y: yp,
                                  width: fsize.width,
                                  height: fsize.height)
                
                xerror += error.width
                xp += fsize.width
                
                if xerror > 1 {
                    rect.size.width += floor(xerror)
                    xp += floor(xerror)
                    xerror -= floor(xerror)
                }
                
                if yerror + error.height > 1 {
                    rect.size.height += floor(yerror + error.height)
                }
                
                let color = image.buffer[image.size.width * y + x]
                context.setFillColor(red: color.red,
                                     green: color.green,
                                     blue: color.blue,
                                     alpha: color.alpha)
                context.fill(rect)
            }
            
            yp += fsize.height
            yerror += error.height
            
            if yerror > 1 {
                yp += floor(yerror)
                yerror -= floor(yerror)
            }
        }
    }
}
