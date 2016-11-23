//
//  BubbleImageView.swift
//  self-chat
//
//  Created by Yura Reutskiy on 22/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

enum RoundCorner {
    case leftUp, leftDown, rightUp, rightDown
}

class BubbleImageView: UIView {
    
    var roundedCorners: [RoundCorner] = [.leftUp, .leftDown, .rightUp, .rightDown]
    
    override func draw(_ rect: CGRect) {
        
        // first remove all layers...
        if let sublayers = layer.sublayers {
            for layer in sublayers {
                if layer.isKind(of: CAShapeLayer.self) {
                    layer.removeFromSuperlayer()
                }
            }
        }
        
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.move(to: CGPoint(x: 10, y: 0))
        // Left Up corner
        context?.addArc(tangent1End: CGPoint(x: 0, y: 0),
                        tangent2End: CGPoint(x: 0, y: 10),
                        radius: 10)
        context?.addLine(to: CGPoint.init(x: 0, y: rect.size.height - 10))
        // Left Down corner
        context?.addArc(tangent1End: CGPoint(x: 0, y: rect.size.height),
                        tangent2End: CGPoint(x: 10, y: rect.size.height),
                        radius: 10)
        context?.addLine(to: CGPoint.init(x: rect.size.width - 10, y: rect.size.height))
        // Right Down corner
        context?.addArc(tangent1End: CGPoint(x: rect.size.width, y: rect.size.height),
                        tangent2End: CGPoint(x: rect.size.width, y: rect.size.height - 10),
                        radius: 10)
        context?.addLine(to: CGPoint.init(x: rect.size.width, y: 10))
        // Right Up corner
        context?.addArc(tangent1End: CGPoint(x: rect.size.width, y: 0),
                        tangent2End: CGPoint(x: rect.size.width - 10, y: 0),
                        radius: 3)
        context?.addLine(to: CGPoint.init(x: 10, y: 0))
        var backColor = UIColor.init(red: 12/255, green: 133/255, blue: 254/255, alpha: 1)
        if tag == 2 {
            backColor = UIColor.init(red: 214/255, green: 214/255, blue: 214/255, alpha: 1)
        }
        context?.setFillColor(backColor.cgColor)
        context?.fillPath()
        context?.strokePath()
        
        //let circlePath =
        let circle = CAShapeLayer()
        circle.path = context?.path
        circle.fillColor = backgroundColor?.cgColor
        layer.addSublayer(circle)
        
        //blah.fillColor = someColor.CGColor
        //layer.addSublayer(blah)
    }
}
