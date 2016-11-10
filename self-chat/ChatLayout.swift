//
//  ChatLayout.swift
//  self-chat
//
//  Created by Yura Reutskiy on 06/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

protocol ChatLayoutDelegate: class {
    
    func collectionView(_ collectionView:UICollectionView, heightForItemAtIndexPath indexPath:NSIndexPath, withWidth:CGFloat) -> CGFloat
    
}

class ChatLayout: UICollectionViewLayout {

    
    weak var delegate: ChatLayoutDelegate!
    
    
    var numberOfColumns = 1
    var cellPadding: CGFloat = 0

    
    
    private var cache = [UICollectionViewLayoutAttributes]()
    
    
    private var contentHeight: CGFloat  = 0.0
    private var contentWidth: CGFloat {
        return collectionView!.bounds.width
    }

    override func prepare() {
        
        let numberOfSections = collectionView?.numberOfSections
        if numberOfSections == 0 {
            return
        }
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset = [CGFloat]()
        for column in 0 ..< numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth )
        }
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
    
        for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
            
            let indexPath = NSIndexPath(item: item, section: 0)
            
    
            let width = columnWidth - cellPadding * 2
            let photoHeight = delegate.collectionView(collectionView!, heightForItemAtIndexPath: indexPath,
                                                      withWidth:width)
            
            let height = cellPadding + photoHeight + cellPadding
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
    
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
    
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            
            column = column >= (numberOfColumns - 1) ? 0 : column + 1
        }
        
        if contentHeight < collectionView!.bounds.height {
            let inset = collectionView!.bounds.height - contentHeight
            collectionView?.contentInset = UIEdgeInsetsMake(inset, 0, 0, 0)
        } else {
            collectionView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            let offsetY = contentHeight - collectionView!.bounds.height
            collectionView?.contentOffset = CGPoint(x: 0, y: offsetY)
        }
        
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
    
}
