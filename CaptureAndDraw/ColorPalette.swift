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
    func colorPalette(colorPalette: ColorPalette, didChooseColor color: UIColor)
}

class ColorPalette: UIView {

    weak var delegate: ColorPaletteDelegate?
    var selectedColor: UIColor = UIColor.blackColor()
    
    private let colorList: [UIColor] = [UIColor.blackColor(), UIColor.darkGrayColor(), UIColor.grayColor(), UIColor.lightGrayColor(), UIColor.whiteColor(), UIColor.cyanColor(), UIColor.blueColor(), UIColor.purpleColor(), UIColor.magentaColor(), UIColor.redColor(), UIColor.orangeColor(), UIColor.yellowColor(), UIColor.greenColor(), UIColor.brownColor()]
    
    private var collectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        
        let interItemPadding: CGFloat = 20.0
        
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: self.bounds.height, height: self.bounds.height)
        flowLayout.minimumLineSpacing = interItemPadding
        flowLayout.scrollDirection = .Horizontal
        
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: flowLayout)
        collectionView.contentInset.left = interItemPadding/2
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(PaletteCell.self, forCellWithReuseIdentifier: "PaletteCell")
        self.addSubview(collectionView)
    }
    
}

extension ColorPalette: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PaletteCell", forIndexPath: indexPath) as! PaletteCell
        cell.color = colorList[indexPath.row]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let selectedColor = colorList[indexPath.row]
        self.selectedColor = selectedColor
        self.delegate?.colorPalette(self, didChooseColor: selectedColor)
    }
}

class PaletteCell: UICollectionViewCell {
    
    private var colorButton: RoundColorButton!
    
    var color: UIColor = UIColor.clearColor() {
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
    
    private func initialize() {
        let cellCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let diameter = min(self.bounds.width, self.bounds.height)
        colorButton = RoundColorButton(center: cellCenter, diameter: diameter, color: UIColor.clearColor())
        colorButton.enabled = false
        self.addSubview(colorButton)
    }
}

