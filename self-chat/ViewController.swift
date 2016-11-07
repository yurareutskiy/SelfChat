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

    
    
    @IBOutlet var actionButtons: [UIButton]!
    let placeHolderText = "Ваше сообщение..."
    var isAddditionViewOpen: Bool {
        get {
            return isCameraViewOpen || isGalleryOpens
        }
    }
    
    // Camera's view and buttons
    var cameraView: UIView?
    var expandButton: UIButton?
    var switchButton: UIButton?
    var takeShotButton: UIButton?
    var isCameraViewOpen = false
    let capturePhoto = AVCapturePhotoOutput()
    
    // Location
    var locationManager: CLLocationManager
    
    // Gallery
    var galleryView: UIView?
    var isGalleryOpens = false
    let galleryHeight: CGFloat = 140
    var allPhotos: PHFetchResult<PHAsset>!
    var scrollPhotosView: UIScrollView?
    let imageManager = PHCachingImageManager()
    let thumbnailSize = CGSize(width: 80 * UIScreen.main.scale, height: 80 * UIScreen.main.scale)
    
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


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)

        collectionView.delegate = self
        collectionView.dataSource = self
        if let layout = collectionView?.collectionViewLayout as? ChatLayout {
            layout.delegate = self
        }
    }

    override func viewDidAppear(_ animated: Bool) {
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

    
    func didTapOnScreen(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    // MARK: - UIKeyboardNotifacation
    
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let offsetHeight = keyboardSize.size.height
            inputBottomContainerConstraint.constant += offsetHeight - 46
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        inputBottomContainerConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location == 0 && text != "" {
            sendButton.isEnabled = true
        } else if range.location == 0 && text == "" {
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
    
    // MARK: - Outlet Actions
    
    @IBAction func sendMessageAction(_ sender: Any) {
        print("User send: \(inputTextView.text)")
        let message = Message(messageText: inputTextView.text)
        inputTextView.text = ""
        textViewDidChange(inputTextView)
        messageArray.append(message)
        collectionView.reloadData()
        
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
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            if self.isCameraViewOpen {
                self.inputBottomContainerConstraint.constant = 0
                self.cameraView!.frame.origin.y = self.view.frame.size.height
            } else {
                self.inputBottomContainerConstraint.constant = self.cameraViewHeight
                self.cameraView!.frame.origin.y -= self.cameraViewHeight
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: { (finished) in
            self.isCameraViewOpen = !self.isCameraViewOpen
        })
        
    }
    
    @IBAction func sendLocation(_ sender: Any) {
        let locationManager = CLLocationManager()
        // Ask for Authorisation from the User.
        locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func galleryAction(_ sender: Any) {
        if galleryView == nil {
            galleryView = UIView(frame: CGRect(x: 0.0, y: view.frame.size.height, width: view.frame.size.width, height: galleryHeight))
            
            
            
            let galleryButton = UIButton(frame: CGRect(x: 0, y: 90, width: view.frame.width, height: 54))
            galleryButton.setTitle("Выбрать фото из галереи", for: .normal)
            galleryButton.setTitleColor(UIColor.blue, for: .normal)
            galleryButton.addTarget(self, action: #selector(galleryPickerOpen(_ :)), for: .touchUpInside)
            let topButtonBorder = UIView(frame: galleryButton.frame)
            topButtonBorder.frame.size.height = 0.5
            topButtonBorder.backgroundColor = UIColor.lightGray
            galleryView?.addSubview(topButtonBorder)
            galleryView?.addSubview(galleryButton)
            
            view.addSubview(galleryView!)

            loadPhotos()
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            if self.isGalleryOpens {
                self.inputBottomContainerConstraint.constant = 0
                self.galleryView!.frame.origin.y = self.view.frame.size.height
            } else {
                self.inputBottomContainerConstraint.constant = self.galleryHeight
                self.galleryView!.frame.origin.y -= self.galleryHeight
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: { (finished) in
            self.isGalleryOpens = !self.isGalleryOpens
        })
    }
    
    func galleryPickerOpen(_ sender: Any) {
        
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
        
        self.videoDataOutput = AVCaptureVideoDataOutput();
        self.videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        self.videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        self.videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue);
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput);
        }
        
        if session.canAddOutput(self.capturePhoto) {
            session.addOutput(self.capturePhoto)
        }
        
        /*[
            AVVideoCodecKey  : AVVideoCodecJPEG,
            AVVideoQualityKey: 0.9
        ]*/
        
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
        
        let settings = AVCapturePhotoSettings()
        settings.isAutoStillImageStabilizationEnabled = true
        //settings.isHighResolutionPhotoEnabled = true
        self.capturePhoto.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer {
            let previewBuffer = previewPhotoSampleBuffer
            let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
            let image = UIImage(data: dataImage!)
            let message = Message(messageImage: dataImage!)
            messageArray.append(message)
            collectionView.reloadData()
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
            
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
            
            // Update the cached fetch results, and reload the table sections to match.
            //...
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, ChatLayoutDelegate {
    

    func layoutCollectionView() -> UICollectionViewLayout {
        var layout = collectionView.collectionViewLayout
        
        return layout
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BubbleCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BubbleCollectionViewCell
        

        let message = messageArray[indexPath.row]
        if message.type == .text {
            cell.textLabel.isHidden = false
            cell.textLabel.text = message.text
            cell.imageView.image = nil
        } else if message.type == .image {
            cell.textLabel.isHidden = true
            cell.imageView.image = UIImage(data: message.image!)
        }
        
        cell.imageView.layer.cornerRadius = 15
        cell.imageView.clipsToBounds = true
        
        return cell
    }
    

    func collectionView(_ collectionView:UICollectionView, heightForItemAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        
        
        let textPadding = CGFloat(4)
        let textMargin = CGFloat(12)
        let message = messageArray[indexPath.item]
        var contentHeight: CGFloat = 0
        let maximumWidth = collectionView.bounds.width - 70 - 32

        if message.type == .text {
            let font = UIFont(name: "pfagorasanspro-light", size: 16)!
            let rect = NSString(string: message.text!).boundingRect(with: CGSize(width: maximumWidth, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
            contentHeight = rect.height
        } else if message.type == .image {
            let image: UIImage = UIImage(data: message.image!)!
            let heightInPoints = image.size.height
            let heightInPixels = heightInPoints * image.scale
            
            let widthInPoints = image.size.width
            let widthInPixels = widthInPoints * image.scale
            
            if widthInPixels <= collectionView.bounds.width / 2 {
                contentHeight = heightInPixels
            } else {
                contentHeight = ((collectionView.bounds.width / 2) / widthInPixels) * heightInPixels
            }
        }
        
        let height = textMargin * 2 + textPadding * 2 + ceil(contentHeight)
        
        return height
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
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error as NSError?)
                return
            }
            
            withCallback(snapshot!.image, nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var locValue:CLLocationCoordinate2D = manager.location!.coordinate
        let location = locations.first
        if location!.verticalAccuracy < Double(100) {
            takeSnapshot(byLocation: location!, withCallback: { (image, error) in
                let message = Message(messageImage: UIImagePNGRepresentation(image!)!)
                self.messageArray.append(message)
                self.collectionView.reloadData()
            })
            locationManager.stopUpdatingLocation()
        }
        
    }
}










