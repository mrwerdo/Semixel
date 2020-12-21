//
//  CollectionView.swift
//  Semixel
//
//  Created by Andrew Thompson on 17/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI
import UIKit

struct CollectionView: UIViewControllerRepresentable {
    
    var colors: [SemanticColor]
    @Binding var selectedColor: SemanticColor
    var addCallback: (() -> ())?
    
    class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        var layout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: 26, height: 26)
            layout.minimumInteritemSpacing = 4
            layout.minimumLineSpacing = 4
            layout.scrollDirection = .horizontal
            layout.sectionInset.right = 8
            return layout
        }()
        
        var addCallback: (() -> ())?
        var selectedColor: Binding<SemanticColor>?
        var colors: [SemanticColor] = []
        lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        var pageControl = UIPageControl()
        
        let numberOfColumns: Int = 3
        let numberOfRows: Int = 4
        
        @objc
        func changePage(sender: UIPageControl) {
            let path = IndexPath(row: 0, section: sender.currentPage)
            collectionView.scrollToItem(at: path, at: .init(), animated: true)
        }
        
        func color(_ section: Int, row: Int) -> SemanticColor? {
            let index = section * numberOfColumns * numberOfRows + row
            if index < colors.count {
                return colors[index]
            }
            return nil
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            let count = colors.count + 1
            let quotient = count / (numberOfColumns * numberOfRows)
            let remainder = count % (numberOfColumns * numberOfRows)
            let number =  remainder > 0 ? quotient + 1 : quotient
            pageControl.numberOfPages = number
            return number
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return numberOfRows * numberOfColumns
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            if let semanticColor = color(indexPath.section, row: indexPath.row) {
                let view = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
                if let cell = view as? Cell {
                    cell.color = semanticColor.color
                    cell.isSelected = semanticColor == selectedColor?.wrappedValue
                }
                return view
            } else if indexPath.section * numberOfRows * numberOfColumns + indexPath.row == colors.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath) as! AddCell
                cell.callback = addCallback
                return cell
            } else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let color = colors[indexPath.row]
            selectedColor?.wrappedValue = color
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            pageControl.currentPage = (Int(scrollView.contentOffset.x) / Int(scrollView.frame.width))
        }
        
        override func loadView() {
            let view = UIView()
            
            let pc = pageControl
            pc.translatesAutoresizingMaskIntoConstraints = false
            pc.addTarget(self, action: #selector(changePage(sender:)), for: .valueChanged)
            pc.allowsContinuousInteraction = true
            pc.hidesForSinglePage = false
            pc.backgroundStyle = .automatic
            
            let cv = collectionView
            
            cv.dataSource = self
            cv.delegate = self
            cv.collectionViewLayout = layout
            cv.register(Cell.self, forCellWithReuseIdentifier: "cell")
            cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "empty")
            cv.register(AddCell.self, forCellWithReuseIdentifier: "add")
            cv.reloadData()
            cv.isScrollEnabled = true
            cv.isPagingEnabled = true
            cv.showsHorizontalScrollIndicator = false
            
            cv.isOpaque = false
            cv.backgroundColor = nil
            cv.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(cv)
            view.addSubview(pc)
            
            let constraints: [NSLayoutConstraint] = [
                pc.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pc.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pc.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
                pc.topAnchor.constraint(equalTo: cv.bottomAnchor, constant: 2),
                cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                cv.topAnchor.constraint(equalTo: view.topAnchor)
            ]
            
            constraints.forEach { $0.isActive = true }

            self.view = view
        }
    }
    
    func makeUIViewController(context: Context) -> ViewController {

        let vc = ViewController()
        vc.selectedColor = _selectedColor
        vc.colors = colors
        vc.addCallback = addCallback
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        uiViewController.selectedColor = _selectedColor
        uiViewController.colors = colors
        uiViewController.addCallback = addCallback
        uiViewController.collectionView.reloadData()
    }

}

private class AddCell: UICollectionViewCell {
    
    private var buttonView = UIButton(type: .system)
    var callback: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    @objc private func selected(_ sender: UIButton) {
        callback?()
    }
    
    private func setup() {
        buttonView.setTitle("+", for: .normal)
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.addTarget(self, action: #selector(selected(_:)), for: .primaryActionTriggered)
        
        contentView.addSubview(buttonView)
        
        buttonView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            .isActive = true
        buttonView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            .isActive = true
        buttonView.widthAnchor.constraint(equalTo: contentView.widthAnchor)
            .isActive = true
        buttonView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
            .isActive = true
        
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.isOpaque = true
        contentView.backgroundColor = UIColor.systemGray3
    }
}

private class Cell: UICollectionViewCell {
    var color: RGBA = .clear {
        didSet {
            update()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.alpha = 0.6
            } else {
                contentView.alpha = 1.0
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            borderView.isHidden = !isSelected
        }
    }
    
    private var borderView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        update()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        update()
    }
    
    private func setup() {
        contentView.backgroundColor = UIColor(red: color.red,
                                              green: color.green,
                                              blue: color.blue,
                                              alpha: color.alpha)
        contentView.layer.cornerRadius = 8
        contentView.isOpaque = true
        
        borderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(borderView)
        borderView.isOpaque = false
        
        borderView.layer.borderColor = UIColor.tertiaryLabel.cgColor
        let borderWidth: CGFloat = 0
        borderView.layer.borderWidth = 4
        borderView.layer.cornerRadius = 8
        borderView.backgroundColor = nil
        borderView.isOpaque = false
        
        borderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: borderWidth)
            .isActive = true
        borderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -borderWidth)
            .isActive = true
        borderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: borderWidth)
            .isActive = true
        borderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -borderWidth)
            .isActive = true
        borderView.isHidden = true
    }
    
    private func update() {
        contentView.backgroundColor = UIColor(red: color.red,
                                            green: color.green,
                                            blue: color.blue,
                                            alpha: color.alpha)
    }
}
