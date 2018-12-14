import Foundation
import UIKit
import Kinetic

class BoundingBox {
    let shapeLayer: CAShapeLayer
    let textLayer: CATextLayer
    let circleImageView:UIImageView
    var closure = {(index:Int) -> Void in};
    
    var classIndex:Int
    enum AnimationType {
        case hide
        case showanim
        case show
        case hideanim
    }
    

    var animType:AnimationType
    
    init() {
        shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.isHidden = true
        
        textLayer = CATextLayer()
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.isHidden = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 14
        textLayer.font = UIFont(name: "Avenir", size: textLayer.fontSize)
        textLayer.alignmentMode = kCAAlignmentCenter
        
        classIndex = 0;
        
        animType = AnimationType.hide;
        circleImageView = UIImageView()
        circleImageView.isUserInteractionEnabled = true
        circleImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.objectClick(sender:))))
    }

    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
        
        //parent.addSublayer(circleImageView.layer)
        //parent.addSublayer(touchView)
    }
    
    func addToView(_ view: UIView) {
        view.addSubview(circleImageView)
    }

    //
    func show(frame: CGRect, label: String, color: UIColor) {
        CATransaction.setDisableActions(true)

        let path = UIBezierPath(rect: frame)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.isHidden = false

        textLayer.string = label
        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false

        let attributes = [
          NSAttributedStringKey.font: textLayer.font as Any
        ]

        let textRect = label.boundingRect(with: CGSize(width: 400, height: 100),
                                          options: .truncatesLastVisibleLine,
                                          attributes: attributes, context: nil)
        let textSize = CGSize(width: textRect.width + 12, height: textRect.height)
        let textOrigin = CGPoint(x: frame.origin.x - 2, y: frame.origin.y - textSize.height)
        textLayer.frame = CGRect(origin: textOrigin, size: textSize)
        
        //  イメージビューの情報を入力
        circleImageView.frame = frame
        
    }
    
    func show(frame: CGRect, image: UIImage, index : Int) {
    
        CATransaction.setDisableActions(true)
        
        var rect =  frame
        if( frame.width > frame.height)
        {
            rect.size.height = rect.size.width
        }else{
            rect.size.width = rect.size.height
        }
        
        classIndex = index;
        //  イメージビューの情報を入力
        circleImageView.frame = rect
        
        circleImageView.isHidden = false
        
        if animType == AnimationType.hide
        {
            circleImageView.alpha = 0.0
            circleImageView.image = image
            animType = AnimationType.showanim
            circleImageView.tween().to( Alpha(1.0), Scale(2.0)).duration(0.2).on(.completed)
            { (tween) -> Void in
                self.animType = AnimationType.show
            }.play()
        }
        //circleImageView.tween().to( Alpha(0.0), Scale(0.0)).duration(TimeInterval(0.0)).play()
        
        
        
    }

    func hide() {
        
        if animType != AnimationType.show{
            return ;
        }
        
        animType = AnimationType.hideanim
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.circleImageView.tween().to( Alpha(0.0), Scale(0.0)).duration(0.5).on(.completed, observer: { (tween) in
                self.circleImageView.isHidden = true;
                self.animType = AnimationType.hide
            }).play()
            
        }
        

        
//        shapeLayer.isHidden = true
//        textLayer.isHidden = true
//        circleImageView.isHidden = true;
    }
    
    func close(){
        self.circleImageView.isHidden = true;
    }
    
    
    
    /// Viewタップ時の挙動
    ///
    /// - Parameter btn: ボタン
    @objc func objectClick(sender: UITapGestureRecognizer){
        
        closure(classIndex)
    }
    
    func subscribeTouchEvent( touchEvent:@escaping (Int) ->()){
        closure = touchEvent
    }
}
