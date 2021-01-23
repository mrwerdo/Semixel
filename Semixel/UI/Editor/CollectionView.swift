//
//  CollectionView.swift
//  Semixel
//
//  Created by Andrew Thompson on 17/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

struct CollectionView: UIViewControllerRepresentable {
    @ObservedObject
    var colorPalette: ColorPalette
    
    @Binding
    var selectedColor: IdentifiableColor
    
    var add: (() -> ())?
    
    func makeUIViewController(context: Context) -> CollectionViewController {
        let vc = CollectionViewController(colorPalette: colorPalette, selectedColor: $selectedColor)
        vc.addCallback = add
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CollectionViewController, context: Context) {
        uiViewController.colorPalette = colorPalette
        uiViewController.addCallback = add
        uiViewController.collectionView.reloadData()
    }
}

class CollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var addCallback: (() -> ())?
    
    @Binding
    var selectedColor: IdentifiableColor
    
    @ObservedObject
    var colorPalette: ColorPalette {
        didSet {
            cancellable?.cancel()
            cancellable = colorPalette.$colors.sink { (newColors) in
                self.colors = newColors
            }
        }
    }
    
    var colors: [IdentifiableColor] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var cancellable: AnyCancellable? = nil
    
    let collectionView: UICollectionView
    let pageControl: UIPageControl
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(direction: UICollectionView.ScrollDirection = .horizontal, colorPalette: ColorPalette, selectedColor: Binding<IdentifiableColor>) {
        self._selectedColor = selectedColor
        self.colorPalette = colorPalette
        self.colors = colorPalette.colors
        
        let layout: UICollectionViewFlowLayout = Self.createLayout()
        layout.scrollDirection = direction
        collectionView = Self.createCollectionView(layout: layout)
        
        pageControl = Self.createPageControl()
        
        super.init(nibName: nil, bundle: nil)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        pageControl.addTarget(self, action: #selector(changePage(sender:)), for: .valueChanged)
                
        cancellable = colorPalette.$colors.sink { (newColors) in
            self.colors = newColors
        }
    }
    
    let numberOfColumns: Int = 3
    let numberOfRows: Int = 4
    
    @objc
    func changePage(sender: UIPageControl) {
//        if let indexPath = collectionView.indexPathsForSelectedItems?.first {
            let path = IndexPath(row: 0, section: sender.currentPage)
            collectionView.scrollToItem(at: path, at: [.top, .left], animated: true)
//        }
    }
    
    func color(_ section: Int, row: Int) -> IdentifiableColor? {
        let index = section * numberOfColumns * numberOfRows + row
        if index < colorPalette.colors.count {
            return colorPalette.colors[index]
        }
        return nil
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let count = colorPalette.colors.count + 1
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
                cell.isSelected = selectedColor.id == semanticColor.id
            }
            return view
        } else if indexPath.section * numberOfRows * numberOfColumns + indexPath.row == colorPalette.colors.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath) as! AddCell
            cell.callback = addCallback
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.section * numberOfRows * numberOfColumns + indexPath.row
        if colorPalette.colors.indices.contains(index) {
            let color = colorPalette.colors[index]
            selectedColor = color
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = (Int(scrollView.contentOffset.x) / Int(scrollView.frame.width))
    }
    
    override func loadView() {
        let view = UIView()
        
        let pc = pageControl
        let cv = collectionView
        
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

extension CollectionViewController {
    static func createPageControl() -> UIPageControl {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.allowsContinuousInteraction = true
        pc.hidesForSinglePage = false
        pc.backgroundStyle = .automatic
        return pc
    }
    
    static func createCollectionView(layout: UICollectionViewFlowLayout) -> UICollectionView {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(Cell.self, forCellWithReuseIdentifier: "cell")
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "empty")
        cv.register(AddCell.self, forCellWithReuseIdentifier: "add")
        cv.isScrollEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.isOpaque = false
        cv.backgroundColor = nil
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }
    
    static func createLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 32, height: 32)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset.right = 8
        return layout
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
        
        buttonView.constrainToSuperView()
        
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.isOpaque = true
        contentView.backgroundColor = UIColor.systemGray3
    }
}

private class Cell: UICollectionViewCell {
    var color: RGBA = .clear {
        didSet {
            contentView.backgroundColor = UIColor(red: color.red,
                                                  green: color.green,
                                                  blue: color.blue,
                                                  alpha: color.alpha)
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
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
        
        borderView.layer.borderColor = UIColor.secondaryLabel.cgColor
        borderView.layer.borderWidth = 4
        borderView.layer.cornerRadius = 8
        borderView.backgroundColor = nil
        borderView.isOpaque = false
        borderView.isHidden = true
        borderView.constrainToSuperView()
    }
}

extension UIView {
    func constrainToSuperView(constant: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        
        let constraints = [
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: constant),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -constant),
            topAnchor.constraint(equalTo: superview.topAnchor, constant: constant),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -constant)
        ]
    
        constraints.forEach { $0.isActive = true }
    }
}
