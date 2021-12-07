//
//  GridView.swift
//  Semixel-UIKIt
//
//  Created by Andrew Thompson on 7/12/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import UIKit

class GridView: UIView {
    var cellSize: CGSize = CGSize(width: 8, height: 8) {
        didSet { setNeedsDisplay() }
    }
    
    var color: UIColor = .gray {
        didSet { setNeedsDisplay() }
    }
    
    var lineWidth: CGFloat = 1.0 {
        didSet { updateWidthAndHeightConstraints() }
    }
    
    private var widthConstraint = NSLayoutConstraint()
    private var heightConstraint = NSLayoutConstraint()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func updateWidthAndHeightConstraints() {
        widthConstraint.constant = lineWidth
        heightConstraint.constant = lineWidth
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let width = Int(bounds.width / cellSize.width)
        let height = Int(bounds.height / cellSize.height)
        
        let offset = lineWidth / 2
        
        for y in 0...width {
            context.move(to: CGPoint(x: 0, y: offset + cellSize.height * CGFloat(y)))
            context.addLine(to: CGPoint(x: bounds.width, y: offset + cellSize.height * CGFloat(y)))
        }
        
        for x in 0...height {
            context.move(to: CGPoint(x: offset + cellSize.width * CGFloat(x), y: 0))
            context.addLine(to: CGPoint(x: offset + cellSize.width * CGFloat(x), y: bounds.height))
        }
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.strokePath()
    }
    
    override func didMoveToSuperview() {
        if let superview = superview {
            widthConstraint = widthAnchor.constraint(equalTo: superview.widthAnchor, constant: lineWidth)
            heightConstraint = heightAnchor.constraint(equalTo: superview.heightAnchor, constant: lineWidth)

            NSLayoutConstraint.activate([
                superview.centerXAnchor.constraint(equalTo: centerXAnchor),
                superview.centerYAnchor.constraint(equalTo: centerYAnchor),
                widthConstraint,
                heightConstraint
            ])
        }
    }
}
