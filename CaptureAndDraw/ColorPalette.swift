//
//  ColorPalette.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

@objc
protocol ColorPaletteDelegate {
    func colorPalette(_ colorPalette: ColorPalette, didChooseColor color: UIColor)
}

class ColorPalette: UIView {

    weak var delegate: ColorPaletteDelegate?
    var selectedColor: UIColor = UIColor.black
    
    fileprivate let colorList: [UIColor] = [UIColor.black, UIColor.darkGray, UIColor.gray, UIColor.lightGray, UIColor.white, UIColor.cyan, UIColor.blue, UIColor.purple, UIColor.magenta, UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.brown]
    
    fileprivate var collectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        
        let interItemPadding: CGFloat = 20.0
        
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: self.bounds.height, height: self.bounds.height)
        flowLayout.minimumLineSpacing = interItemPadding
        flowLayout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: flowLayout)
        collectionView.contentInset.left = interItemPadding/2
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PaletteCell.self, forCellWithReuseIdentifier: "PaletteCell")
        self.addSubview(collectionView)
    }
    
}

extension ColorPalette: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PaletteCell", for: indexPath) as! PaletteCell
        cell.color = colorList[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedColor = colorList[indexPath.row]
        self.selectedColor = selectedColor
        self.delegate?.colorPalette(self, didChooseColor: selectedColor)
    }
}

class PaletteCell: UICollectionViewCell {
    
    fileprivate var colorButton: RoundColorButton!
    
    var color: UIColor = UIColor.clear {
        didSet {
            colorButton.color = color
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        let cellCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let diameter = min(self.bounds.width, self.bounds.height)
        colorButton = RoundColorButton(center: cellCenter, diameter: diameter, color: UIColor.clear)
        colorButton.isEnabled = false
        self.addSubview(colorButton)
    }
}

