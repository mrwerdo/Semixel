//
//  ViewController.swift
//  Semixel-UIKIt
//
//  Created by Andrew Thompson on 7/12/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import UIKit
import SemixelCore

extension RGBA {
    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pixelView: PixelView = PixelView()
    var colorPalette: UICollectionView!
    
    var colors: [RGBA] = [
        "655a7c","ab92bf","afc1d6","cef9f2","d6ca98",
        "ff6f59","254441","43aa8b","b2b09b","ef3054",
        "130303","2d080a","7c3626","f5853f","ffcdbc",
        "2f1847","624763","c62e65","f9b3d1","d63af9",
        "3891a6","4c5b5c","fde74c","db5461","e3655b",
        "8acdea","746d75","8c4843","9e643c","ede6f2",
        "eaeaea","cbc5ea","73628a","313d5a","183642"
    ].compactMap({ RGBA(hex: $0) })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pixelView.grid.lineWidth = 1
        pixelView.grid.color = .lightGray
        if let image = UIImage(named: "Coal 4") {
            pixelView.image = PixelImage<RGBA>(uiImage: image)
        }
        pixelView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pixelView.widthAnchor.constraint(equalTo: pixelView.heightAnchor)
        ])
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 35, height: 45)
        layout.sectionInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        layout.minimumInteritemSpacing = 4
        
        colorPalette = UICollectionView(frame: .zero, collectionViewLayout: layout)
        colorPalette.backgroundColor = .systemGray4
        colorPalette.translatesAutoresizingMaskIntoConstraints = false
        colorPalette.isScrollEnabled = false
        view.addSubview(colorPalette)
        NSLayoutConstraint.activate([
            colorPalette.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            colorPalette.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colorPalette.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colorPalette.heightAnchor.constraint(equalToConstant: view.frame.height/3)
        ])
        
        colorPalette.register(ColorPickerViewCell.self, forCellWithReuseIdentifier: "cell")
        colorPalette.delegate = self
        colorPalette.dataSource = self
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        container.addSubview(pixelView)
        NSLayoutConstraint.activate([
            pixelView.leadingAnchor.constraint(equalToSystemSpacingAfter: container.leadingAnchor, multiplier: 2),
            container.trailingAnchor.constraint(equalToSystemSpacingAfter: pixelView.trailingAnchor, multiplier: 2),
            pixelView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pixelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: colorPalette.topAnchor)
        ])
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = colors[indexPath.item].uiColor
        cell.contentView.layer.cornerRadius = 6
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.layer.borderColor = CGColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
            cell.contentView.layer.borderWidth = 4.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = colors[indexPath.item].uiColor.withAlphaComponent(0.5)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = colors[indexPath.item].uiColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.layer.borderColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            cell.contentView.layer.borderWidth = 0.0
        }
    }
}

extension UIView {
    func center(in view: UIView) {
        let constraints = [
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func setSizeConstraints(_ size: CGSize) {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }
}
