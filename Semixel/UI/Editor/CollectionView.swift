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
    @EnvironmentObject
    var colorPalette: ColorPalette
    
    var add: (() -> ())?
    
    func makeUIViewController(context: Context) -> CollectionViewController {
        return CollectionViewController(colorPalette: colorPalette)
    }
    
    func updateUIViewController(_ uiViewController: CollectionViewController, context: Context) {
        uiViewController.colorPalette = colorPalette
    }
}

class CollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    var colorPalette: ColorPalette {
        didSet {
            if oldValue !== colorPalette {
                cancellable?.cancel()
                cancellable2?.cancel()
                
                cancellable = colorPalette.$colors
                    .receive(on: RunLoop.main)
                    .sink(receiveValue: updateColors(_:))
                cancellable2 = colorPalette.$selectedIndex
                    .receive(on: RunLoop.main)
                    .sink(receiveValue: updateSelection(_:))
            }
        }
    }

    var colors: [RGBA] {
        colorPalette.colors.map { $0.color }
    }
    
    var cancellable: AnyCancellable? = nil
    var cancellable2: AnyCancellable? = nil
    var dataSource: UICollectionViewDiffableDataSource<Int, Int>!
    
    let collectionView: UICollectionView
    let pageControl: UIPageControl
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancellable?.cancel()
        cancellable2?.cancel()
        cancellable = nil
        cancellable2 = nil
    }
    
    init(direction: UICollectionView.ScrollDirection = .horizontal, colorPalette: ColorPalette) {
        self.colorPalette = colorPalette
        
        let layout: UICollectionViewFlowLayout = Self.createLayout()
        layout.scrollDirection = direction
        
        collectionView = Self.createCollectionView(layout: layout)
        pageControl = Self.createPageControl()
        
        super.init(nibName: nil, bundle: nil)
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: cellProvider)
        
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        
        pageControl.addTarget(self, action: #selector(changePage(sender:)), for: .valueChanged)
        
        cancellable = colorPalette.$colors
            .receive(on: RunLoop.main)
            .sink(receiveValue: updateColors(_:))
        cancellable2 = colorPalette.$selectedIndex
            .receive(on: RunLoop.main)
            .sink(receiveValue: updateSelection(_:))
    }
    
    private func cellProvider(_ collectionView: UICollectionView, _ indexPath: IndexPath, _ identifier: Int) -> UICollectionViewCell? {
        if identifier == -1 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath) as! AddCell
        } else {
            let semanticColor = colors[indexPath.row]
            let view = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            if let cell = view as? Cell {
                cell.color = semanticColor
            }
            return view
        }
    }
    
    private func updateColors(_ newValue: [IdentifiableColor]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(colorPalette.colors.map { $0.id })
        snapshot.appendItems([-1])
        dataSource.apply(snapshot, animatingDifferences: false)
        updateSelection(colorPalette.selectedIndex)
    }
    
    private func updateSelection(_ newValue: ColorIdentifier) {
        if let index = self.colorPalette.colors.firstIndex(where: { $0.id == newValue }) {
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
        }
    }
    
    @objc
    func changePage(sender: UIPageControl) {
//        let path = IndexPath(row: 0, section: sender.currentPage)
//        collectionView.scrollToItem(at: path, at: [.top, .left], animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        if colors.indices.contains(index) {
            colorPalette.selectedIndex = colorPalette.colors[index].id
        } else if index == colorPalette.colors.count {
            colorPalette.add(colorPalette.currentColor.wrappedValue, updateSelection: true)
            collectionView.deselectItem(at: indexPath, animated: true)
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
        pc.numberOfPages = 1
        pc.sizeToFit()
        pc.isHidden = true
        return pc
    }
    
    static func createCollectionView(layout: UICollectionViewFlowLayout) -> UICollectionView {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(Cell.self, forCellWithReuseIdentifier: "cell")
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
    
    private var buttonView = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        buttonView.text = "+"
        buttonView.textAlignment = .center
        buttonView.sizeToFit()
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        
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
