//
//  AirBrushImageView.swift
//  AirBrushImageView
//
//  Created by Kurt Jensen on 10/4/16.
//  Copyright © 2016 Arbor Apps. All rights reserved.
//

import UIKit

class AirBrushImageView: UIImageView {

    static let radius: CGFloat = 80
    
    var brushView: UIView? {
        return superview // this could be superview, iboutlet, or anything.
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = true // uiimageview default is false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        blurPoint(point: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        blurPoint(point: point)
    }
    
    private func blurPoint(point: CGPoint) {
        // blur the point by blurring a cropped image with gaussian filter
        guard let brushView = brushView else {
            return
        }
        let rect = CGRect(x: point.x-(AirBrushImageView.radius/2), y: point.y-(AirBrushImageView.radius/2), width: AirBrushImageView.radius, height: AirBrushImageView.radius)
        guard let snapshot = brushView.snapshot(of: rect) else {
            return
        }
        guard let blurredImage = snapshot.gaussianBlur() else {
            return
        }
        let blurImageView = UIImageView(image: blurredImage)
        blurImageView.frame = rect
        addSubview(blurImageView)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // snap shot the view and save, removing subviews so we don't use too many resources.
        guard let brushView = brushView else {
            return
        }
        guard let snapshot = brushView.snapshot() else {
            return
        }
        self.image = snapshot
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
    
}

extension UIImage {
    
    func gaussianBlur(blurRadius: CGFloat? = 10) -> UIImage? {
        let context = CIContext(options: nil)
        let imageToBlur = CIImage(image: self)
        guard let blurfilter = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }
        blurfilter.setValue(imageToBlur, forKey: "inputImage")
        blurfilter.setValue(blurRadius, forKey: "inputRadius")
        let resultImage = blurfilter.value(forKey: "outputImage") as! CIImage
        guard let cgImage = context.createCGImage(resultImage, from: resultImage.extent) else {
            return nil
        }
        let blurredImage = UIImage(cgImage: cgImage)
        return blurredImage
    }
    
}

extension UIView {
    
    func snapshot(of rect: CGRect? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = viewImage, let rect = rect else {
            return viewImage
        }
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
    
}
