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

class BubbleImageView: UIImageView {
    
    static var rightAngleDegrees: CGFloat = 3
    static var roundAngleDegrees: CGFloat = 15
    
    var message: Message?
    
    override func layoutIfNeeded() {
        print("layoutIfNeeded")
        super.layoutIfNeeded()
    }
    
    override var frame: CGRect {
        didSet {
            print("frame didSet")
        }
    }
    
    override func layoutSubviews() {
        print("layoutSubviews")
        roundedCorners(depenceOnMessage: message)
    }
    
    var roundedCorners: [RoundCorner] = [.leftUp, .leftDown, .rightUp, .rightDown]
    
    override func draw(_ rect: CGRect) {
        /*
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
                        radius: roundedCorners.contains(RoundCorner.leftUp) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees)
        context?.addLine(to: CGPoint.init(x: 0, y: rect.size.height - 10))
        // Left Down corner
        context?.addArc(tangent1End: CGPoint(x: 0, y: rect.size.height),
                        tangent2End: CGPoint(x: 10, y: rect.size.height),
                        radius: roundedCorners.contains(RoundCorner.leftDown) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees)
        context?.addLine(to: CGPoint.init(x: rect.size.width - 10, y: rect.size.height))
        // Right Down corner
        context?.addArc(tangent1End: CGPoint(x: rect.size.width, y: rect.size.height),
                        tangent2End: CGPoint(x: rect.size.width, y: rect.size.height - 10),
                        radius: roundedCorners.contains(RoundCorner.rightDown) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees)
        context?.addLine(to: CGPoint.init(x: rect.size.width, y: 10))
        // Right Up corner
        context?.addArc(tangent1End: CGPoint(x: rect.size.width, y: 0),
                        tangent2End: CGPoint(x: rect.size.width - 10, y: 0),
                        radius: roundedCorners.contains(RoundCorner.rightUp) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees)
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
        
        */
 
 
    }
    
    
    func roundedCorners(depenceOnMessage message: Message?) {
        if message == nil {
            return
        }
        self.message = message

        setCornersArray(forMessageInCell: message!)
        let newLayer = CAShapeLayer()
        newLayer.path = createBezierPath(insideInRect: frame).cgPath
        layer.mask = newLayer
    }
    

    func setCornersArray(forMessageInCell message: Message) {
        if message.rondedType == .alone {
            roundedCorners = [.leftUp, .leftDown, .rightUp, .rightDown]
            return
        }
        if message.sender == .income {
            switch message.rondedType {
                case .first:
                    roundedCorners = [.leftUp, .rightUp, .rightDown]
                case .middle:
                    roundedCorners = [.rightUp, .rightDown]
                case .last:
                    roundedCorners = [.leftDown, .rightUp, .rightDown]
                default:
                    roundedCorners = [.leftUp, .leftDown, .rightUp, .rightDown]
            }
        } else {
            switch message.rondedType {
                case .first:
                    roundedCorners = [.leftUp, .leftDown, .rightUp]
                case .middle:
                    roundedCorners = [.leftDown, .leftUp]
                case .last:
                    roundedCorners = [.leftDown, .leftUp, .rightDown]
                default:
                    roundedCorners = [.leftUp, .leftDown, .rightUp, .rightDown]
            }
        }
    }
    
    
    func createBezierPath(insideInRect rect: CGRect) -> UIBezierPath {
        
        layer.mask = nil
        
        let leftUpRadius = roundedCorners.contains(.leftUp) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees
        let leftDownRadius = roundedCorners.contains(.leftDown) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees
        let rightDownRadius = roundedCorners.contains(.rightDown) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees
        let rightUpRadius = roundedCorners.contains(.rightUp) ? BubbleImageView.roundAngleDegrees : BubbleImageView.rightAngleDegrees
        
        // create a new path
        let path = UIBezierPath()
        
        // Left up
        path.move(to: CGPoint(x: 0, y: leftUpRadius))
        path.addArc(withCenter: CGPoint.init(x: leftUpRadius, y: leftUpRadius),
                    radius: leftUpRadius,
                    startAngle: CGFloat(3 * M_PI_2),
                    endAngle: CGFloat(M_PI),
                    clockwise: false)
        
        // Left down
        path.addLine(to: CGPoint.init(x: 0, y: rect.height - leftDownRadius))
        path.addArc(withCenter: CGPoint.init(x: leftDownRadius, y: rect.height - leftDownRadius),
                    radius: leftDownRadius,
                    startAngle: CGFloat(M_PI),
                    endAngle: CGFloat(M_PI_2),
                    clockwise: false)
        
        // Right down
        path.addLine(to: CGPoint.init(x: rect.width - rightDownRadius, y: rect.height))
        path.addArc(withCenter: CGPoint.init(x: rect.width - rightDownRadius, y: rect.height - rightDownRadius),
                    radius: rightDownRadius,
                    startAngle: CGFloat(M_PI_2),
                    endAngle: 0,
                    clockwise: false)
        
        // Right up
        path.addLine(to: CGPoint.init(x: rect.width, y: rightUpRadius))
        path.addArc(withCenter: CGPoint.init(x: rect.width - rightUpRadius, y: rightUpRadius),
                    radius: rightUpRadius,
                    startAngle: 0,
                    endAngle: CGFloat(3 * M_PI_2),
                    clockwise: false)
        
        
        // End of path to up left
        path.addLine(to: CGPoint.init(x: leftUpRadius, y: 0))
        path.close() // draws the final line to close the path
        
        return path
    }
    
}















