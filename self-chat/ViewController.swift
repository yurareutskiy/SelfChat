//
//  ViewController.swift
//  self-chat
//
//  Created by Yura Reutskiy on 03/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var inputBottomContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var inputTextView: UITextView!
    
    @IBOutlet var actionButtons: [UIButton]!
    let placeHolderText = "Ваше сообщение..."
    var isAddditionViewOpen = false
    
    // Camera's view and buttons
    var cameraView: UIView?
    var expandButton: UIButton?
    var switchButton: UIButton?
    var takeShotButton: UIButton?
    
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
        inputTextView.text = ""
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
            if self.isAddditionViewOpen {
                self.inputBottomContainerConstraint.constant = 0
                self.cameraView!.frame.origin.y = self.view.frame.size.height
            } else {
                self.inputBottomContainerConstraint.constant = self.cameraViewHeight
                self.cameraView!.frame.origin.y -= self.cameraViewHeight
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: { (finished) in
            self.isAddditionViewOpen = !self.isAddditionViewOpen
        })
        
    }
    
    
    

}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
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
}

