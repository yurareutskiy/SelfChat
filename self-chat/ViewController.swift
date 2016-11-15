//
//  ViewController.swift
//  self-chat
//
//  Created by Yura Reutskiy on 03/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MapKit
import CoreLocation


class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var inputBottomContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var inputTextView: UITextView!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var messageArray: [Message] = []
    
    // Array of messages divided by date
    var sourceArray: [String: [Message]] = [:]
    var keysArray: [String] = []

    
    
    @IBOutlet var actionButtons: [UIButton]!
    let placeHolderText = "Ваше сообщение..."
    var isAddditionViewOpen: Bool {
        get {
            return isCameraViewOpen || isGalleryOpens
        }
    }
    // CollectionView
    var maxBubbleWidth: CGFloat = 0
    let interactor = Interactor()

    
    // Camera's view and buttons
    var cameraView: UIView?
    var expandButton: UIButton?
    var switchButton: UIButton?
    var takeShotButton: UIButton?
    var isCameraViewOpen = false
    let capturePhoto = AVCapturePhotoOutput()
    
    // Location
    var locationManager: CLLocationManager = CLLocationManager()
    var isLocationActive = false
    
    // Gallery
    var galleryView: UIView?
    var isGalleryOpens = false
    let galleryHeight: CGFloat = 140
    var allPhotos: PHFetchResult<PHAsset>!
    var scrollPhotosView: UIScrollView?
    let imageManager = PHCachingImageManager()
    let thumbnailSize = CGSize(width: 80 * UIScreen.main.scale, height: 80 * UIScreen.main.scale)
    let picker = UIImagePickerController()
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue : DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    var currentFrame:CIImage!
    var done = false
    var isCameraExpanded = false
    let cameraViewHeight: CGFloat = 284
    let widthTakingButton: CGFloat = 55

    // MARK: - Parent's methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated(_:)), name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)

        collectionView.delegate = self
        collectionView.dataSource = self
        if let layout = collectionView?.collectionViewLayout as? ChatLayout {
            layout.delegate = self
            collectionView.register(UINib.init(nibName: "HeaderCollectionReusableView", bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        }
        
        loadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        maxBubbleWidth = view.bounds.width - 70 - 12

        // Set tap recognizer for hidding keyboard
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapOnScreen(_:)))
        contentContainerView.addGestureRecognizer(tapRecognizer)
        inputTextView.delegate = self
        
        // set placeholder
        if inputTextView.text == "" {
            inputTextView.text = placeHolderText
            inputTextView.textColor = UIColor.lightGray
        } else {
            inputTextView.textColor = UIColor.black
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return isCameraExpanded
    }

    // MARK: - Load datas
    
    func loadData() {
        
        ServerTask().loadAllMessages { (result) in
            if result == nil {
                return
            }
            self.messageArray.removeAll()
            if let data = result?["result"] as? [Dictionary<String, Any>] {
                for var item in data {
                    var message: Message
                    switch item["type"] as! String {
                    case "text":
                        message = Message(messageText: item["text"] as! String)
                        message.type = .text
                        break
                    case "image":
                        message = Message(urlImage: item["image"] as! String)
                        break
                    case "location":
                        message = Message(urlImage: item["image"] as! String)
                        message.type = .location
                        message.latitude = item["latitude"] as! String?
                        message.longittude = item["longittude"] as! String?
                        break
                    default:
                        print("invalid type")
                        continue
                    }
                    message.parse(dateFromString: item["date"] as! String)
                    switch item["sender"] as? String {
                        case "income"?:
                            message.sender = .income
                        default:
                            message.sender = .outcome
                            break
                    }
                    self.messageArray.append(message)
                    
                    let dateKey = message.getDateString()
                    if self.sourceArray.keys.contains(dateKey) == false {
                        self.sourceArray[dateKey] = []
                        self.keysArray.append(dateKey)
                    }
                    self.sourceArray[dateKey]?.append(message)

                    
                }
                print(self.sourceArray)
                DispatchQueue.main.async(execute: {
                    self.collectionView.reloadData()
                    
                })
            }
        }
    }
    
    
    func didTapOnScreen(_ sender: Any) {
        self.view.endEditing(true)
        switch true {
            case isCameraViewOpen:
                togglePhotoView(withAnimation: true, complition: nil)
            case isGalleryOpens:
                toggleGalleryView(withAnimation: true, complition: nil)
            default: break;
        }
    }
    
    // MARK: - UIDeviceOrientationDidChange
    
    func rotated(_ notification: Notification) {
        //collectionView.collectionViewLayout.prepare()
        //view.layoutIfNeeded()
        print(view.frame.width)
    }
    
    // MARK: - UIKeyboardNotifacation
    
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let offsetHeight = keyboardSize.size.height

            func liftView(withChecking finished: Bool) {
                if finished == false {
                    return
                }
                inputBottomContainerConstraint.constant = offsetHeight - 45
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    self.collectionView.collectionViewLayout.prepare()
                }, completion: { isFinished in
                    self.collectionView.layoutIfNeeded()
                })
            }
            
            switch true {
                case isCameraViewOpen:
                    togglePhotoView(withAnimation: false, complition: liftView)
                case isGalleryOpens:
                    toggleGalleryView(withAnimation: false, complition: liftView)
                default:
                    liftView(withChecking: true)
            }
        }
    }
    

    
    func keyboardWillHide(_ notification: Notification) {
        inputBottomContainerConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.collectionView.collectionViewLayout.prepare()
        }, completion: nil)
    }

    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let targetString = (textView.text as NSString).replacingCharacters(in: range, with: text)
        if range.location == 0 && text != "" {
            sendButton.isEnabled = true
        } else if range.location == 0 && text == "" {
            sendButton.isEnabled = false
        }
        if targetString.replacingOccurrences(of: " ", with: "") != "" {
            sendButton.isEnabled = true
        } else if targetString.replacingOccurrences(of: " ", with: "") == "" {
            sendButton.isEnabled = false
        }

        
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        textView.textColor = UIColor.black
        
        if textView.text == placeHolderText {
            textView.text = ""
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeHolderText
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let fixedHeight = textView.frame.size.height
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let offset = newSize.height - fixedHeight
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        textView.frame = newFrame;
        inputContainerHeightConstraint.constant += offset
        view.layoutIfNeeded()
    }
    
    func sendToServer(_ message: Message) {
        if message.getDateString() != messageArray.last?.getDateString() {
            keysArray.append(message.getDateString())
            sourceArray.updateValue([message], forKey: keysArray.last!)
        } else {
            sourceArray[keysArray.last!]?.append(message)
        }
        messageArray.append(message)
        if messageArray.count == 1 {
            collectionView.reloadData()
        } else {
            let indexPath = IndexPath.init(item: sourceArray[keysArray.last!]!.count - 1, section: keysArray.count - 1)
            self.collectionView.insertItems(at: [indexPath])
        }
 
        do {
            let json = try JSONSerialization.data(withJSONObject: message.serialize(), options: JSONSerialization.WritingOptions.prettyPrinted)
            ServerTask().sendMessage(stringData: json, callback: { (isSend, resultId) in
                if isSend {
                    if message.sender == .outcome {
                        let reply = AutoReplier.init(message).commonReply()
                        if reply != nil {
                            DispatchQueue.main.async(execute: {
                                self.sendToServer(reply!)
                            })
                            
                        }
                    }
                    print("message is send")
                    if message.type != .text {
                        ServerTask().sendPhoto(data: message.image!, messageId: resultId!, callback: { (isFinished) in
                            if isFinished {
                                print("image was upload")
                            }
                        })
                    }
                    
                } else {
                    print("message sending is failure")
                }
            })
        } catch {
            print("deserialize is failure")
        }
        

        
    }
    
    // MARK: - Outlet Actions
    
    @IBAction func sendMessageAction(_ sender: Any) {
        print("User send: \(inputTextView.text)")
        let message = Message(messageText: inputTextView.text)
        inputTextView.text = ""
        textViewDidChange(inputTextView)
        sendButton.isEnabled = false
        sendToServer(message)
    }
    
    @IBAction func photoAction(_ sender: Any) {
        
        // check if camera view is not exist then create it
        if cameraView == nil {
            cameraView = UIView(frame: CGRect(x: 0.0, y: view.frame.size.height, width: view.frame.size.width, height: cameraViewHeight))

            cameraView!.backgroundColor = UIColor.black
            setupAVCapture()
            view.addSubview(cameraView!)
        }
        if !done {
            session.startRunning()
        }
        if isGalleryOpens == true {
            toggleGalleryView(withAnimation: true, complition: { (finished) in
                if finished == true {
                    self.togglePhotoView(withAnimation: true, complition: nil)
                }
            })
        } else {
            togglePhotoView(withAnimation: true, complition: nil)
        }
        
        
    }
    
    func togglePhotoView(withAnimation isAnimate:Bool, complition: ((Bool) -> Void)? = nil) {
        func toggle() {
            if self.isCameraViewOpen {
                self.inputBottomContainerConstraint.constant = 0
                self.cameraView!.frame.origin.y = self.view.frame.size.height
            } else {
                self.inputBottomContainerConstraint.constant = self.cameraViewHeight
                self.cameraView!.frame.origin.y -= self.cameraViewHeight
            }
            self.view.layoutIfNeeded()
            self.collectionView.collectionViewLayout.prepare()
            self.isCameraViewOpen = !self.isCameraViewOpen
        }
        if isAnimate == true {
            UIView.animate(withDuration: isAnimate == true ? 0.3 : 0, delay: 0, options: .curveEaseInOut, animations: {
                toggle()
            }, completion: { (finished) in
                if complition != nil {
                    complition!(finished)
                }
            })
        } else {
            toggle()
            if complition != nil {
                complition!(true)
            }
        }
        
    }
    
    @IBAction func sendLocation(_ sender: Any) {
        
        
        // For use in foreground
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            isLocationActive = true
        }
    }
    
    @IBAction func galleryAction(_ sender: Any) {
        if galleryView == nil {
            galleryView = UIView(frame: CGRect(x: 0.0, y: view.frame.size.height, width: view.frame.size.width, height: galleryHeight))
            
            
            
            let galleryButton = UIButton(frame: CGRect(x: 0, y: 90, width: view.frame.width, height: 54))
            galleryButton.setTitle("Выбрать фото из галереи", for: .normal)
            galleryButton.backgroundColor = UIColor.white
            galleryButton.setTitleColor(UIColor.init(red: 12/255, green: 133/255, blue: 254/255, alpha: 1) , for: .normal)
            galleryButton.titleLabel?.font = UIFont(name: "pfagorasanspro-light", size: 18)
            galleryButton.addTarget(self, action: #selector(galleryPickerOpen(_ :)), for: .touchUpInside)
            let topButtonBorder = UIView(frame: galleryButton.frame)
            topButtonBorder.frame.size.height = 0.5
            topButtonBorder.backgroundColor = UIColor.lightGray
            galleryView?.addSubview(topButtonBorder)
            galleryView?.addSubview(galleryButton)
            
            view.addSubview(galleryView!)

            loadPhotos()
        }
        if isCameraViewOpen == true {
            togglePhotoView(withAnimation: true, complition: { (finished) in
                if finished == true {
                    self.toggleGalleryView(withAnimation: true, complition: nil)
                }
            })
        } else {
            toggleGalleryView(withAnimation: true, complition: nil)
        }
        

    }

    func toggleGalleryView(withAnimation isAnimate:Bool, complition: ((Bool) -> Void)? = nil) {
        func toggle() {
            if self.isGalleryOpens {
                self.inputBottomContainerConstraint.constant = 0
                self.galleryView!.frame.origin.y = self.view.frame.size.height
            } else {
                self.inputBottomContainerConstraint.constant = self.galleryHeight
                self.galleryView!.frame.origin.y -= self.galleryHeight
            }
            self.isGalleryOpens = !self.isGalleryOpens
            self.view.layoutIfNeeded()
            self.collectionView.collectionViewLayout.prepare()
        }
        if isAnimate == true {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                toggle()
            }, completion: { (finished) in
                if self.isGalleryOpens == false {
                    self.scrollPhotosView = nil
                }
                if complition != nil {
                    complition!(finished)
                }
            })
        } else {
            toggle()
            if isGalleryOpens == false {
                scrollPhotosView = nil
            }
            if complition != nil {
                complition!(true)
            }
        }
        

    }
    
    func loadPhotos() {
        
        if scrollPhotosView == nil {
            scrollPhotosView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 90))
            scrollPhotosView?.alwaysBounceVertical = false
            scrollPhotosView?.showsHorizontalScrollIndicator = false
            scrollPhotosView?.backgroundColor = UIColor(colorLiteralRed: 250/255, green: 250/255, blue: 250/255, alpha: 1)
            galleryView?.addSubview(scrollPhotosView!)
        }
        
        // Create a PHFetchResult object for each section in the table view.
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotosOptions.fetchLimit = 20
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        PHPhotoLibrary.shared().register(self)
        
        if allPhotos.count == 0 {
            return
        }
        
        for counter in 0...(allPhotos.count - 1) {
            let asset = allPhotos.object(at: counter)
            imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { (image, _) in
                let rect = CGRect(x: counter * 85 + 5, y: 5, width: 80, height: 80)
                let imageButton = UIButton(frame: rect)
                let imageView = UIImageView(frame: imageButton.bounds)
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageButton.addSubview(imageView)
                imageButton.tag = counter
                imageButton.addTarget(self, action: #selector(self.imageDidPickup(_ :)), for: .touchUpInside)
                self.scrollPhotosView?.contentSize = CGSize(width: (counter + 1) * 90, height: 90)
                self.scrollPhotosView?.addSubview(imageButton)
            })
        }
    }
    
    func imageDidPickup(_ sender: UIButton) {
        let asset = allPhotos.object(at: sender.tag)
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil, resultHandler: { (image, _) in
            let dataImage = UIImageJPEGRepresentation(image!, 1)!
            let message = Message(messageImage: dataImage)
            self.sendToServer(message)
        
        })
    }

}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSessionPreset352x288;
        
        
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInMicrophone, .builtInDuoCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified).devices
        // Loop through all the capture devices on this phone
        for device in devices! {
            // Make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the front camera
                if((device as AnyObject).position == AVCaptureDevicePosition.front) {
                    captureDevice = device
                    if captureDevice != nil {
                        beginSession();
                        done = true;
                        break;
                    }
                }
            }
        }
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            err = error
            deviceInput = nil
        };
        if err != nil {
            print("error: \(err?.localizedDescription)");
        }
        if self.session.canAddInput(deviceInput){
            self.session.addInput(deviceInput);
        }
        
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        self.videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue);
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput);
        }
        
        if session.canAddOutput(self.capturePhoto) {
            session.addOutput(self.capturePhoto)
        }
        
        self.videoDataOutput.connection(withMediaType: AVMediaTypeVideo).isEnabled = true;
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        let rootLayer: CALayer = self.cameraView!.layer;
        rootLayer.masksToBounds = true;
        self.previewLayer.frame = rootLayer.bounds;
        self.cameraView!.layer.addSublayer(self.previewLayer);
        
        switchButton = UIButton(frame: CGRect(x: view.frame.size.width - (24 + 46), y: 213, width: 46, height: 46))
        switchButton?.setImage(#imageLiteral(resourceName: "switch"), for: .normal)
        switchButton?.addTarget(self, action: #selector(switchCameraType(_:)), for: .touchUpInside)
        cameraView?.addSubview(switchButton!)
        
        expandButton = UIButton(frame: CGRect(x: 24, y: 213, width: 46, height: 46))
        expandButton?.setImage(#imageLiteral(resourceName: "fullscreen"), for: .normal)
        expandButton?.addTarget(self, action: #selector(expandCameraView(_:)), for: .touchUpInside)
        cameraView?.addSubview(expandButton!)
        
        takeShotButton = UIButton(frame: CGRect(x: (view.frame.width / 2) - (widthTakingButton / 2), y: cameraView!.frame.height - (20 + widthTakingButton), width: widthTakingButton, height: widthTakingButton))
        takeShotButton?.addTarget(self, action: #selector(takeCapture(_ :)), for: .touchUpInside)
        takeShotButton?.setTitle("Отпр.", for: .normal)
        takeShotButton?.titleLabel?.font = UIFont(name: "pfagorasanspro-light", size: 15)
        takeShotButton?.setTitleColor(UIColor.white, for: .normal)
        takeShotButton?.layer.borderColor = UIColor.white.cgColor
        takeShotButton?.layer.borderWidth = 2
        takeShotButton?.layer.cornerRadius = widthTakingButton / 2
        cameraView?.addSubview(takeShotButton!)

        
        session.startRunning()
        
    }
    
    func cameraButtonsLayoutUpdate() {
        var newRect = CGRect(x: view.frame.size.width - (24 + 46), y: cameraView!.frame.height - (25 + 46), width: 46, height: 46)
        switchButton?.frame = newRect
        newRect.origin.x = 24
        expandButton?.frame = newRect
        
        let takingButtonRect = CGRect(x: (view.frame.width / 2) - (widthTakingButton / 2), y: cameraView!.frame.height - (20 + widthTakingButton), width: widthTakingButton, height: widthTakingButton)
        takeShotButton?.frame = takingButtonRect
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        currentFrame =   self.convertImageFromCMSampleBufferRef(sampleBuffer: sampleBuffer);
        
        
    }
    
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
        done = false;
    }
    
    func convertImageFromCMSampleBufferRef(sampleBuffer:CMSampleBuffer) -> CIImage{
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!;
        let ciImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        return ciImage;
    }
    
    func switchCameraType(_ sender: UIButton) {
        //Change camera source

        //Indicate that some changes will be made to the session
        session.beginConfiguration()
        
        //Remove existing input
        let currentCameraInput:AVCaptureInput = session.inputs.first as! AVCaptureInput
        session.removeInput(currentCameraInput)
        
        //Get new input
        var newCamera:AVCaptureDevice! = nil
        if let input = currentCameraInput as? AVCaptureDeviceInput {
            if input.device.position == .back {
                newCamera = cameraWithPosition(position: .front)
            } else {
                newCamera = cameraWithPosition(position: .back)
            }
        }
        
        //Add input to session
        var err: NSError?
        var newVideoInput: AVCaptureDeviceInput!
        do {
            newVideoInput = try AVCaptureDeviceInput(device: newCamera)
        } catch let err1 as NSError {
            err = err1
            newVideoInput = nil
        }
        
        if newVideoInput == nil || err != nil {
            print("Error creating capture device input: \(err!.localizedDescription)")
        } else {
            session.addInput(newVideoInput)
        }
        
        //Commit all the configuration changes at once
        session.commitConfiguration()

    }
    
    // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInMicrophone, .builtInDuoCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified).devices
        for device in devices! {
            let device = device 
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    func expandCameraView(_ sender: UIButton) {
        if isCameraExpanded == false {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.inputBottomContainerConstraint.constant = self.view.frame.size.height
                self.view.layoutIfNeeded()
                var cameraFrame = self.cameraView?.frame
                cameraFrame?.origin.y = 0
                cameraFrame?.size.height = self.view.frame.height
                self.cameraView?.frame = cameraFrame!
                self.previewLayer.frame = cameraFrame!
                self.cameraButtonsLayoutUpdate()
            }, completion: { (isComplete) in
                self.expandButton?.setImage(#imageLiteral(resourceName: "fullscreen_close"), for: .normal)
                self.setNeedsStatusBarAppearanceUpdate()
            })
        } else {
            var cameraFrame = self.cameraView?.frame
            cameraFrame?.origin.y = self.view.frame.height - self.cameraViewHeight
            cameraFrame?.size.height = self.cameraViewHeight
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.inputBottomContainerConstraint.constant = self.cameraViewHeight
                self.view.layoutIfNeeded()
                self.cameraView?.frame = cameraFrame!
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        self.previewLayer.frame = cameraFrame!
                        self.previewLayer.frame.origin.y = 0
                    })
                }, completion: nil)
                self.cameraButtonsLayoutUpdate()
            }, completion: { (isComplete) in
                self.expandButton?.setImage(#imageLiteral(resourceName: "fullscreen"), for: .normal)
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
        isCameraExpanded = !isCameraExpanded
    }
    
    func takeCapture(_ sender: UIButton) {
        // Make virtually camera
        let settings = AVCapturePhotoSettings()
        settings.isAutoStillImageStabilizationEnabled = true // enable stabilization for photo
        self.capturePhoto.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        animateCapturing()
    }
    
    func animateCapturing() {
        // Make disolving and effect of camera
        UIView.animate(withDuration: 0.08, delay: 0, options: .curveEaseIn, animations: {
            self.cameraView?.alpha = 0
        }, completion: { (finished) in
            if finished == true {
                UIView.animate(withDuration: 0.08, delay: 0, options: .curveEaseOut, animations: {
                    self.cameraView?.alpha = 1
                }, completion: nil)
            }
        })
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        // Snap capture from photo stream
        if let sampleBuffer = photoSampleBuffer {
            let previewBuffer = previewPhotoSampleBuffer
            let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
            let image = UIImage(data: dataImage!)
            let message = Message(messageImage: dataImage!)
            sendToServer(message)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil) // Save to user gallery
            
        } else {
            
        }
    }
    
}

// MARK: PHPhotoLibraryChangeObserver
extension ViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check each of the three top-level fetches for changes.
            
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result.
                allPhotos = changeDetails.fetchResultAfterChanges
                scrollPhotosView = nil
                loadPhotos()
                // (The table row for this one doesn't need updating, it always says "All Photos".)
            }

        }
    }
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, ChatLayoutDelegate {
    
// MARK: - UICollectionView

    func layoutCollectionView() -> UICollectionViewLayout {
        return collectionView.collectionViewLayout
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return keysArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sourceArray[keysArray[section]]!.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let messageDayArray = sourceArray[keysArray[indexPath.section]]
        let message = messageDayArray![indexPath.row]
        
        var ientifier = "outcome"
        if message.sender == .income {
            ientifier = "income"
        }
        
        let cell: BubbleCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ientifier, for: indexPath) as! BubbleCollectionViewCell
        
        if indexPath.row == 0 && messageDayArray!.count > 1 {
            cell.rounedType = .first
        } else if indexPath.row == messageDayArray!.count - 1 && messageDayArray!.count > 1 {
            cell.rounedType = .last
        } else {
            cell.rounedType = .middle
        }
        if message.type == .text {
            cell.textLabel.isHidden = false
            cell.textLabel.text = message.text
            cell.imageView.image = nil
            cell.actionButton.isEnabled = false
        } else {
            let image = UIImage(data: message.image!)
            cell.textLabel.isHidden = true
            cell.imageView.image = image
            cell.actionButton.isEnabled = true
            cell.actionButton.tag = messageArray.index(of: message)!
            cell.actionButton.addTarget(self, action: #selector(showAttachment(fromCellButon:)), for: .touchUpInside)
            cell.imageView.contentMode = .scaleAspectFill
            var bubbleHeight = image!.size.height
            var bubbleWidth = image!.size.width
            if image!.size.width > maxBubbleWidth {
                bubbleHeight = (bubbleHeight * maxBubbleWidth) / image!.size.width
                bubbleWidth = maxBubbleWidth
            }
            cell.imageView.frame.size.width = bubbleWidth
            cell.imageView.frame.size.height = bubbleHeight
            
        }
        
        cell.imageView.layer.cornerRadius = 20
        cell.imageView.clipsToBounds = true
        //cell.roundCell()

        
        return cell
    }
    

    func collectionView(_ collectionView:UICollectionView, heightForItemAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        
        // Calculate height of every message bubble
        // Also Trump already calculates height of wall
        
        let textPadding = CGFloat(4) // Margin between text label and bubbles border on LEFT and RIGHT
        let margin = CGFloat(12) // Margin between text label and bubbles border on TOP and BOTTOM
        let messageDayArray = sourceArray[keysArray[indexPath.section]]
        let message = messageDayArray![indexPath.row]
        var contentHeight: CGFloat = 0
        let maximumWidth = collectionView.bounds.width - 100 //

        if message.type == .text {
            // Calculate height of message label with this font
            // Font here is thing in which size actually has matter
            let font = UIFont(name: "pfagorasanspro-light", size: 16)!
            let rect = NSString(string: message.text!).boundingRect(with: CGSize(width: maximumWidth - 24, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
            contentHeight = textPadding * 2 + ceil(rect.height) // Append padding of top and bottom to text height
            
        } else {
            let image: UIImage = UIImage(data: message.image!)!
            let heightInPoints = image.size.height
            let heightInPixels = heightInPoints * image.scale
            
            let widthInPoints = image.size.width
            let widthInPixels = widthInPoints * image.scale
            
            if widthInPixels <= maxBubbleWidth { // Check if bubble width more then maximum, then we calculate with aaspect ratio
                contentHeight = heightInPixels
            } else {
                contentHeight = (maxBubbleWidth * heightInPixels) / widthInPixels
            }
        }
        
        return contentHeight + (2 * margin)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as! HeaderCollectionReusableView
        supplementaryView.dateLabel.text = keysArray[indexPath.section]
        return supplementaryView
    }
    
    
    func showAttachment(fromCellButon button: UIButton) {
        let message = messageArray[button.tag]
        if message.type == .image {
            performSegue(withIdentifier: "image", sender: message)
        } else if message.type == .location {
            let lat = message.latitude
            let long = message.longittude
            let baseUrl : String = "comgooglemaps://?center=" + lat! + "," + long! + "&zoom=14&views=traffic"
            //let name : String = message.text!
            
            //let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            let finalUrl = baseUrl //+ encodedName!
            
            let url = URL(string: finalUrl)
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    


}

extension ViewController: CLLocationManagerDelegate {
    // Takes a snapshot and calls back with the generated UIImage
    func takeSnapshot(byLocation location: CLLocation, withCallback: @escaping (UIImage?, NSError?) -> ()) {
        let options = MKMapSnapshotOptions()
        let span = MKCoordinateSpanMake(0.005, 0.005)
        options.region = MKCoordinateRegion(center: location.coordinate, span: span)
        options.size = CGSize(width: 200, height: 200)
        options.scale = UIScreen.main.scale
        
        // Create virtually map and screenshot it (also virtually)
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error as NSError?)
                return
            }
            
            withCallback(self.pinPhoto(forSnapshot: snapshot!, location: location.coordinate), nil)
        }
    }
    
    // Location delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        // Check accuracy of our location
        if location!.verticalAccuracy < Double(100) && isLocationActive == true {
            // Disable flag for ignoring input location
            isLocationActive = false
            locationManager.stopUpdatingLocation()
            // Just take snapshot of our location
            takeSnapshot(byLocation: location!, withCallback: { (image, error) in
                let message = Message(messageImage: UIImagePNGRepresentation(image!)!)
                message.latitude = String(location!.coordinate.latitude)
                message.longittude = String(location!.coordinate.longitude)
                message.type = .location
                self.sendToServer(message)
            })
        }
        
    }
    
    // Add to map image pin in the center
    func pinPhoto(forSnapshot snapshot: MKMapSnapshot, location: CLLocationCoordinate2D) -> UIImage {
        let pin = MKPinAnnotationView.init(annotation: nil, reuseIdentifier: "")
        let pinImage = pin.image
        
        let image = snapshot.image
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: CGPoint.zero)
        
        let point = snapshot.point(for: location)
        pinImage?.draw(at: CGPoint(x: point.x, y: point.y - (pinImage?.size.height)!))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage!
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Open picker
    func galleryPickerOpen(_ sender: Any) {
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(picker, animated: true, completion: nil)
    }
    
    // Close picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Image have choosen
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismiss(animated:true, completion: nil)
        
        // Check if image has wrong rotation
        if image.imageOrientation != .up {
            var degrees: CGFloat = 0
            switch image.imageOrientation {
                case .down: degrees = 180
                case .left: degrees = 270
                case .right: degrees = 90
                default: break
            }
            image = imageRotatedByDegrees(oldImage: image, deg: degrees)
        }
        let message = Message(messageImage: UIImagePNGRepresentation(image)!)
        sendToServer(message)
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat(M_PI / 180))
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat(M_PI / 180)))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        if degrees == 180 {
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        } else {
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.height, height: oldImage.size.width))
        }
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension ViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor //.hasStarted ? interactor : nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? ModalImageViewController {
            let image = UIImage(data: (sender as! Message).image!)
            destinationViewController.image = image
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
    }
    
}









