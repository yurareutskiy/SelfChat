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

    
    
    private var cache = [[UICollectionViewLayoutAttributes]]()
    private var headersCache = [UICollectionViewLayoutAttributes]()
    
    
    private var contentHeight: CGFloat  = 0.0
    private var headerHeight: CGFloat = 30
    private var contentWidth: CGFloat {
        return collectionView!.bounds.width
    }

    override func prepare() {
    
        cache.removeAll()
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
    
        for section in 0 ..< collectionView!.numberOfSections {
            let headerAttributes = UICollectionViewLayoutAttributes.init(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath.init(item: 0, section: section))
            headerAttributes.frame = CGRect(x: 0, y: yOffset[column], width: collectionView!.bounds.width, height: 30)
            headersCache.append(headerAttributes)
            var sectionAttributesArray = [UICollectionViewLayoutAttributes]()
            yOffset[column] = yOffset[column] + headerHeight
            for item in 0 ..< collectionView!.numberOfItems(inSection: section) {
                
                let indexPath = NSIndexPath(item: item, section: section)
                
                
                let width = columnWidth - cellPadding * 2
                let photoHeight = delegate.collectionView(collectionView!, heightForItemAtIndexPath: indexPath,
                                                          withWidth:width)
                
                let height = cellPadding + photoHeight + cellPadding
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
                attributes.frame = insetFrame
                sectionAttributesArray.append(attributes)
                
                
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height
                
                column = column >= (numberOfColumns - 1) ? 0 : column + 1
            }
        
            cache.append(sectionAttributesArray)
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
        
        for sectionItem in cache {
            for sectionAttributes in headersCache {
                if sectionAttributes.frame.intersects(rect) {
                    layoutAttributes.append(sectionAttributes)
                    break
                }
            }
            for attributes in sectionItem {
                if attributes.frame.intersects(rect) {
                    layoutAttributes.append(attributes)
                }
            }
        }
        return layoutAttributes
    }
    
    override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return headersCache[elementIndexPath.section]
    }
    
    override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return headersCache[elementIndexPath.section]
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return headersCache[indexPath.section]
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.section][indexPath.item]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return headersCache[indexPath.section]
    }
    
    
}
