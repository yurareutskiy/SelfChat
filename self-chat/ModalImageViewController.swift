//
//  ModalImageViewController.swift
//  self-chat
//
//  Created by Yura Reutskiy on 13/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

class ModalImageViewController: UIViewController {

    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showHelperCircle()
    }
    
    func setUI() {
        view.backgroundColor = UIColor.black
        
        imageView?.contentMode = .scaleAspectFit
        imageView?.backgroundColor = UIColor.clear
        imageView.image = image!
        view.addSubview(imageView!)
        
        let closeButton = UIButton(frame: CGRect.init(x: 20, y: 30, width: 20, height: 20))
        closeButton.setBackgroundImage(UIImage.init(named: "cancel"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: view.bounds.width, height: 64))
        headerView.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.2)
        
        headerView.addSubview(closeButton)
        
        //view.addSubview(headerView)
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    var interactor:Interactor? = nil
    
    @IBAction func close(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        
        let percentThreshold:CGFloat = 30.3
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        if translation.y < 0 {
            return
        }
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 100.0)
        let progress = CGFloat(downwardMovementPercent)
        guard let interactor = interactor else { return }
        print(sender.state.rawValue)
        switch sender.state {
        case .began:
            interactor.hasStarted = true
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
            if progress > 0.25 {
                dismiss(animated: true, completion: nil)
            } else {
                view.alpha = 1 - progress * 2
                var rect = view.frame
                rect.origin.y = translation.y
                view.frame = rect
            }
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 1
                var rect = self.view.frame
                rect.origin.y = 0
                self.view.frame = rect
            })
        default:
            break
        }

    }
    
    func showHelperCircle(){
        let center = CGPoint(x: view.bounds.width / 2 - 15, y: 100)
        let small = CGSize(width: 30, height: 30)
        let circle = UIView(frame: CGRect(origin: center, size: small))
        circle.layer.cornerRadius = circle.frame.width/2
        circle.backgroundColor = UIColor.white
        circle.layer.shadowOpacity = 0.8
        circle.layer.shadowOffset = CGSize.zero
        view.addSubview(circle)
        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            options: [],
            animations: {
                circle.frame.origin.y += 200
                circle.layer.opacity = 0
        },
            completion: { _ in
                circle.removeFromSuperview()
        }
        )
    }
    



}
