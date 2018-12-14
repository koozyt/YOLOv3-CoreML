import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox
import Kinetic

class ViewController: UIViewController {
  @IBOutlet weak var videoPreview: UIView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var debugImageView: UIImageView!

    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var topbarImageView: UIImageView!
    let yolo = YOLO()

  var videoCapture: VideoCapture!
  var request: VNCoreMLRequest!
  var startTimes: [CFTimeInterval] = []

  var boundingBoxes = [BoundingBox]()
  var colors: [UIColor] = []

  let ciContext = CIContext()
  var resizedPixelBuffer: CVPixelBuffer?

  var framesDone = 0
  var frameCapturingStartTime = CACurrentMediaTime()
  let semaphore = DispatchSemaphore(value: 2)

    let overlay:UIImageView = UIImageView()
    let closebutton:UIButton = UIButton()
    var classIndexs: [Int] = []
    var isTracking:Bool = true
    
  override func viewDidLoad() {
    super.viewDidLoad()

    isTracking = true;
    timeLabel.text = ""

    loadCircleImages();
    setUpBoundingBoxes()
    setUpCoreImage()
    setUpVision()
    setUpCamera()

    resultsView.isHidden = true
    frameCapturingStartTime = CACurrentMediaTime()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print(#function)
  }

  // MARK: - Initialization

  func setUpBoundingBoxes() {
    for _ in 0..<YOLO.maxBoundingBoxes {
      boundingBoxes.append(BoundingBox())
        
    }

    // Make colors for the bounding boxes. There is one color for each class,
    // 80 classes in total.
    for r: CGFloat in [0.2, 0.4, 0.6, 0.8, 1.0] {
      for g: CGFloat in [0.3, 0.7, 0.6, 0.8] {
        for b: CGFloat in [0.4, 0.8, 0.6, 1.0] {
          let color = UIColor(red: r, green: g, blue: b, alpha: 1)
          colors.append(color)
        }
      }
    }
  }

  func setUpCoreImage() {
    let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight,
                                     kCVPixelFormatType_32BGRA, nil,
                                     &resizedPixelBuffer)
    if status != kCVReturnSuccess {
      print("Error: could not create resized pixel buffer", status)
    }
  }

  func setUpVision() {
    guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
      print("Error: could not create Vision model")
      return
    }

    request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)

    // NOTE: If you choose another crop/scale option, then you must also
    // change how the BoundingBox objects get scaled when they are drawn.
    // Currently they assume the full input image is used.
    request.imageCropAndScaleOption = .scaleFill
  }

  func setUpCamera() {
    videoCapture = VideoCapture()
    videoCapture.delegate = self
    videoCapture.fps = 50
    videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.hd1280x720) { success in
      if success {
        // Add the video preview into the UI.
        if let previewLayer = self.videoCapture.previewLayer {
          self.videoPreview.layer.addSublayer(previewLayer)
          self.resizePreviewLayer()
        }

        // Add the bounding box layers to the UI, on top of the video preview.
        for box in self.boundingBoxes {
          box.addToLayer(self.videoPreview.layer)
            box.addToView(self.videoPreview)
            box.subscribeTouchEvent(touchEvent: { (index) in
                
                //  wakoの場合オーバーレイを実行する
                if( index == 0){
                    self.isTracking = false
                    self.videoPreview.addSubview(self.overlay)
                    self.videoPreview.addSubview(self.closebutton)
                    self.transitionStartAnim(duration: 0.5)

                    for i in 0..<self.boundingBoxes.count
                    {
                        self.boundingBoxes[i].close()
                    }
                }
            })
            /*
            box.subscribeTouchEvent {_ in (index)
                self.videoPreview.addSubview(self.overlay)
                self.videoPreview.addSubview(self.closebutton)
                self.transitionStartAnim(duration: 0.5)
            }*/
        }
        
        let width = self.view.frame.width
        let height = CGFloat((self.view.frame.width / 9) * 16) // 9:16比率
        
        
        let x =  0
        let y = (self.view.frame.height - height ) / 2
        self.overlay.frame = CGRect(x: CGFloat(x),
                                    y: y,
                                    width: width,
                                    height: height);
        let image = UIImage(named:"wako_bg")
        self.overlay.image = image
        self.overlay.alpha = 0.0;
        
        //  クローズボタン
        self.closebutton.frame = CGRect(x: width - ( self.view.frame.width / 10) * 1.5,
                                        y: y+( self.view.frame.width / 10),// ( self.view.frame.width / 10) * 1.5,
            width: width / 10,
            height: width / 10);
        let normal = UIImage(named:"wako_bt_close")
        self.closebutton.setImage(normal, for: UIControlState.normal);
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.closeBtnClick(sender:)))
        self.closebutton.addGestureRecognizer(gesture);
        


        //  レイヤーによる画像表示の方法
        /*
        let ovalShapeLayer = CAShapeLayer()
        ovalShapeLayer.strokeColor = UIColor.blue.cgColor  // 輪郭は青
        ovalShapeLayer.fillColor = UIColor.clear.cgColor  // 塗りはクリア
        ovalShapeLayer.lineWidth = 1.0
        ovalShapeLayer.path = UIBezierPath(ovalIn: CGRect(x:30, y:130, width:50, height:50)).cgPath
        ovalShapeLayer.frame = CGRect(x: 0,
                                      y: self.videoPreview.frame.height - self.videoPreview.frame.width,
                                      width: self.videoPreview.frame.width,
                                      height: self.videoPreview.frame.width);
        let image = UIImage(named:"taxidriver")
        ovalShapeLayer.contents = image?.cgImage
        self.videoPreview.layer.addSublayer(ovalShapeLayer)
        */
        
        
        
        
        //self.videoPreview.layer.addSublayer(myButton.layer)
        
        
        // ボタンをViewに追加する.
        


        // Once everything is set up, we can start capturing live video.
        self.videoCapture.start()
      }
    }
    
   
    

  }

    
    /*
     
     ボタンのアクション時に設定したメソッド.
     
     */
    /*
    @objc func btnClick(btn: UIButton) {
        print("btn clicked")
      //  self.denilo?.removeFromSuperview()
    }*/
    
  // MARK: - UI stuff

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    resizePreviewLayer()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func resizePreviewLayer() {
    videoCapture.previewLayer?.frame = videoPreview.bounds
  }

  // MARK: - Doing inference

  func predict(image: UIImage) {
    if let pixelBuffer = image.pixelBuffer(width: YOLO.inputWidth, height: YOLO.inputHeight) {
      predict(pixelBuffer: pixelBuffer)
    }
  }

  func predict(pixelBuffer: CVPixelBuffer) {
    // Measure how long it takes to predict a single video frame.
    let startTime = CACurrentMediaTime()

    // Resize the input with Core Image to 416x416.
    guard let resizedPixelBuffer = resizedPixelBuffer else { return }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let sx = CGFloat(YOLO.inputWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
    let sy = CGFloat(YOLO.inputHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
    let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
    let scaledImage = ciImage.transformed(by: scaleTransform)
    ciContext.render(scaledImage, to: resizedPixelBuffer)

    // This is an alternative way to resize the image (using vImage):
    //if let resizedPixelBuffer = resizePixelBuffer(pixelBuffer,
    //                                              width: YOLO.inputWidth,
    //                                              height: YOLO.inputHeight)

    // Resize the input to 416x416 and give it to our model.
    if let boundingBoxes = try? yolo.predict(image: resizedPixelBuffer) {
      let elapsed = CACurrentMediaTime() - startTime
      showOnMainThread(boundingBoxes, elapsed)
    }
  }

  func predictUsingVision(pixelBuffer: CVPixelBuffer) {
    // Measure how long it takes to predict a single video frame. Note that
    // predict() can be called on the next frame while the previous one is
    // still being processed. Hence the need to queue up the start times.
    startTimes.append(CACurrentMediaTime())

    // Vision will automatically resize the input image.
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
    try? handler.perform([request])
  }

  func visionRequestDidComplete(request: VNRequest, error: Error?) {
    if let observations = request.results as? [VNCoreMLFeatureValueObservation],
       let features = observations.first?.featureValue.multiArrayValue {

        let boundingBoxes = yolo.computeBoundingBoxes(features: [features, features, features])
      let elapsed = CACurrentMediaTime() - startTimes.remove(at: 0)
      showOnMainThread(boundingBoxes, elapsed)
    }
  }

  func showOnMainThread(_ boundingBoxes: [YOLO.Prediction], _ elapsed: CFTimeInterval) {
    DispatchQueue.main.async {
      // For debugging, to make sure the resized CVPixelBuffer is correct.
      //var debugImage: CGImage?
      //VTCreateCGImageFromCVPixelBuffer(resizedPixelBuffer, nil, &debugImage)
      //self.debugImageView.image = UIImage(cgImage: debugImage!)

        if(self.isTracking){
            self.show(predictions: boundingBoxes)
        }
      let fps = self.measureFPS()
      self.timeLabel.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)

      self.semaphore.signal()
    }
  }

  func measureFPS() -> Double {
    // Measure how many frames were actually delivered per second.
    framesDone += 1
    let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
    let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
    if frameCapturingElapsed > 1 {
      framesDone = 0
      frameCapturingStartTime = CACurrentMediaTime()
    }
    return currentFPSDelivered
  }

    func show(predictions: [YOLO.Prediction]) {
        var hideIndexs = [0,1,2,3]
        print("---------------")
        for i in 0..<boundingBoxes.count
        {
            if i < predictions.count
            {
                let prediction = predictions[i]

                let width = view.bounds.width
                let height = width * 4 / 3
                let scaleX = width / CGFloat(YOLO.inputWidth)
                let scaleY = height / CGFloat(YOLO.inputHeight)
                let top = (view.bounds.height - height) / 2

                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.y += top
                rect.size.width *= scaleX
                rect.size.height *= scaleY
            
                //  トラッキングしているindexを取得、格納
                hideIndexs.remove(at: prediction.classIndex)
                
                let indexNo = classIndexs.index(of:prediction.classIndex)
                            
                var classIndex = 0
                if indexNo != nil {
                    classIndex = classIndexs[indexNo!]
                }else{
                
                    classIndexs.append(prediction.classIndex)
                    classIndex = prediction.classIndex
                }
                
                print("classIndex : \(classIndex)")
                
                
                boundingBoxes[classIndex].show(frame: rect, image: circleImage[classIndex], index:prediction.classIndex)
            }
        }
        
        for classIndex in hideIndexs
        {
            boundingBoxes[classIndex].hide()
        }
    }
    
    func loadCircleImages(){
        for imgName in circleImageFileNames{
            circleImage.append(  UIImage(named: imgName)!)
            
        }
    }
    //  クローズボタンタップ時の処理
    @objc func closeBtnClick(sender: UITapGestureRecognizer){
        self.transitionCloseAnim(duration: 0.5)
        self.isTracking = true;
    }
    
    //  遷移開始時のアニメーション
    func transitionStartAnim( duration: CGFloat){
        self.overlay.tween().to( Alpha(1.0)).duration(TimeInterval(duration)).play()
        self.closebutton.tween().to( Alpha(1.0)).duration(TimeInterval(duration)).play()
        
        self.topbarImageView.tween().to( Alpha(0.0)).duration(TimeInterval(duration)).play()
    }
    
    //  元画面遷移時のアニメーション
    func transitionCloseAnim( duration: CGFloat){
        
        self.overlay.tween().to( Alpha(0.0)).duration(TimeInterval(duration)).on(.completed) {
            (tween) -> Void in
            self.overlay.removeFromSuperview();
            }.play()
        
        self.closebutton.tween().to( Alpha(0.0)).duration(TimeInterval(duration)).on(.completed) {
            (tween) -> Void in
            self.closebutton.removeFromSuperview();
            }.play()
        
        self.topbarImageView.tween().to( Alpha(1.0)).duration(TimeInterval(duration)).play()
    }
}

extension ViewController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
    // For debugging.
    //predict(image: UIImage(named: "dog416")!); return

    semaphore.wait()

    if let pixelBuffer = pixelBuffer {
      // For better throughput, perform the prediction on a background queue
      // instead of on the VideoCapture queue. We use the semaphore to block
      // the capture queue and drop frames when Core ML can't keep up.
      DispatchQueue.global().async {
        self.predict(pixelBuffer: pixelBuffer)
        //self.predictUsingVision(pixelBuffer: pixelBuffer)
      }
    }
  }
}
