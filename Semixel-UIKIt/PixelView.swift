//
//  PixelView.swift
//  Semixel-UIKIt
//
//  Created by Andrew Thompson on 7/12/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import UIKit
import SemixelCore

class PixelView: UIView {
    
    private(set) var grid: GridView = GridView()
    private var imageView: UIImageView = UIImageView()
    private(set) var cursor: UIImageView = UIImageView(image: UIImage(systemName: "pencil"))
    
    public var image: PixelImage<RGBA> = PixelImage(size: .zero, buffer: [])
    {
        didSet {
            if let cgImage = image.convertToCGImage() {
                imageView.image = UIImage(cgImage: cgImage)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.minificationFilter = .nearest
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.addSubview(grid)
        addSubview(imageView)

        cursor.translatesAutoresizingMaskIntoConstraints = true
        cursor.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin,
                                   .flexibleLeftMargin, .flexibleRightMargin]
        cursor.frame.size = CGSize(width: 20, height: 20)
        cursor.tintColor = .white
        addSubview(cursor)
        
        let drag = UIPanGestureRecognizer(target: self, action: #selector(PixelView.cursorMoved(_:)))
        addGestureRecognizer(drag)
    }
    
    @objc
    private func cursorMoved(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: self)
            cursor.center.x += translation.x
            cursor.center.y += translation.y
            limitCursorToBounds()
            sender.setTranslation(.zero, in: self)
        default:
            break
        }
    }
    
    private func limitCursorToBounds() {
        let size = cursor.bounds.size
        let rect = imageView.bounds.inset(by: UIEdgeInsets(top: size.height/2, left: size.width/2, bottom: size.height/2, right: size.width/2))
        
        cursor.center.x = max(rect.minX, min(cursor.center.x, rect.maxX))
        cursor.center.y = max(rect.minY, min(cursor.center.y, rect.maxY))
    }
    
}
