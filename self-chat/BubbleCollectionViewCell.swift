//
//  BubbleCollectionViewCell.swift
//  self-chat
//
//  Created by Yura Reutskiy on 05/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit




class BubbleCollectionViewCell: UICollectionViewCell {


    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: BubbleImageView!
    @IBOutlet weak var bubbleMarginLeftConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        imageView.layer.mask = nil
        print("prepareForReuse")
    }

    
    
}
