//
//  BubbleCollectionViewCell.swift
//  self-chat
//
//  Created by Yura Reutskiy on 05/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

class BubbleCollectionViewCell: UICollectionViewCell {
    
    enum CellRounedType {
        case first
        case middle
        case last
    }

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var bubbleMarginLeftConstraint: NSLayoutConstraint!
    var rounedType: CellRounedType = .middle
    
    override func prepareForReuse() {
    }
    
    func roundCell() {
        let radius: CGFloat = 12

        switch rounedType {
            case .first:
                let subLayer = UIView(frame: CGRect.init(x: imageView.frame.width / 2, y: imageView.frame.height / 2, width: imageView.frame.width / 2, height: imageView.frame.height / 2))
                subLayer.layer.cornerRadius = 4
                subLayer.backgroundColor = imageView.backgroundColor
                imageView.addSubview(subLayer)
                imageView.sendSubview(toBack: subLayer)
                //imageView.roundCorner(corners: .bottomRight, radius: radius)
            case .last:
                let subLayer = UIView(frame: CGRect.init(x: 18, y: 0, width: 18, height: imageView.frame.height / 2))
                subLayer.layer.cornerRadius = 4
                subLayer.backgroundColor = imageView.backgroundColor
                imageView.addSubview(subLayer)
                imageView.sendSubview(toBack: subLayer)
                //imageView.roundCorner(corners: .topRight, radius: radius)
            default:
                let subLayer = UIView(frame: CGRect.init(x: imageView.frame.width / 2, y: 0, width: imageView.frame.width / 2, height: imageView.frame.height))
                subLayer.layer.cornerRadius = 4
                subLayer.backgroundColor = imageView.backgroundColor
                imageView.addSubview(subLayer)
                imageView.sendSubview(toBack: subLayer)
                //imageView.roundCorner(corners: [.bottomRight, .topRight], radius: radius)
        }
    }
    
    
}

extension UIView {
    func roundCorner(corners: UIRectCorner, radius: CGFloat) {
        let cornerSize = CGSize.init(width: radius, height: radius)
        let secondCornerSize = CGSize.init(width: radius, height: radius)
        
        var maskLayer = CAShapeLayer(layer: self.layer)
        let secondMaskLayer = CAShapeLayer(layer: self.layer)
        
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.allCorners], cornerRadii: cornerSize).cgPath
        var secondRect:CGRect = CGRect.zero
        let halfWidth = self.bounds.width / 2
        let halfHeight = self.bounds.height / 2
        switch corners {
        case UIRectCorner.topLeft:
            secondRect = CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight)
            break
        case UIRectCorner.topRight:
            secondRect = CGRect(x: halfWidth, y: 0, width: halfWidth, height: halfHeight)
            break
        case UIRectCorner.bottomRight:
            secondRect = CGRect(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight)
            break
        case UIRectCorner.bottomLeft:
            secondRect = CGRect(x: 0, y: halfHeight, width: halfWidth, height: halfHeight)
            break
        case [.bottomRight, .topRight]:
            secondRect = CGRect(x: halfWidth, y: 0, width: halfWidth, height: self.bounds.height)
            break
        default: break
            
        }
        let secondPath = UIBezierPath(roundedRect: secondRect, byRoundingCorners: [.allCorners], cornerRadii: secondCornerSize).cgPath
        maskLayer = CAShapeLayer.init()
        maskLayer.path = maskPath;
        secondMaskLayer.path = secondPath
        maskLayer.addSublayer(secondMaskLayer)
        self.layer.mask = maskLayer;
        
    }
}
