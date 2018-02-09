//
//  ControllView.swift
//  SonyController
//
//  Created by Alexander Griswold on 1/14/18.
//  Copyright © 2018 com.example. All rights reserved.
//

import UIKit

class ControlView: UIView, CameraControllerDelegate {
    
    var connectCamera: UIButton = {
        let button = UIButton()
        button.setTitle("Connect Camera", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }()
    
    var startLiveView: UIButton = {
        let button = UIButton()
        button.setTitle("Start Live View", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }()
    
    var takePicture: UIButton = {
        let button = UIButton()
        button.setTitle("Take Picture", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }()
    
    var stopCont: UIButton = {
        let button = UIButton()
        button.setTitle("Stop Cont", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }()
    
    
    var getEvent: UIButton = {
        let button = UIButton()
        button.setTitle("Get Event", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }()
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    var timer: Timer?
    
    
    
    var cameraController = CameraController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        self.frame = CGRect(x: 0, y: 0, width: 1366, height: 1024)
        self.backgroundColor = UIColor.white
        self.addSubview(connectCamera)
        self.addSubview(startLiveView)
        self.addSubview(takePicture)
        self.addSubview(imageView)
        self.addSubview(stopCont)
        self.addSubview(getEvent)
        self.connectCamera.addTarget(self, action: #selector(ControlView.tappedConnect), for: .touchUpInside)
        self.startLiveView.addTarget(self, action: #selector(ControlView.tappedStartLiveView), for: .touchUpInside)
        self.takePicture.addTarget(self, action: #selector(ControlView.tappedTakePicture), for: .touchUpInside)
        self.stopCont.addTarget(self, action: #selector(ControlView.tappedStopCont), for: .touchUpInside)
        
        self.getEvent.addTarget(self, action: #selector(ControlView.pressedGetEvent), for: .touchUpInside)
        
        cameraController.delegate = self

    }
    
    func imageDidDownload(image: UIImage) {
        self.imageView.image = image
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedConnect() {
        cameraController.connectCamera()
    }
    
    @objc func tappedStartLiveView() {
        /*
        cameraController.startLiveView()
 */
        cameraController.setContinuousShooting()
        cameraController.setContShootingSpeed()
    }
    
    @objc func tappedTakePicture() {
        /*
        cameraController.stopLiveView()
        cameraController.takePicture()
 */
        cameraController.startCont()
    
    }
    
    @objc func tappedStopCont() {
        
        
        print("Stop called")
        cameraController.httpPost(method: "stopContShooting", params: [], version: "1.0", id: 1)
    }
    
    @objc func pressedGetEvent() {
        cameraController.getEvent()
    }
    
    func shootingDidStart() {
        
        
        var when = DispatchTime.now() + 2.0 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            self.tappedStopCont()
        }
    }
   
    
    override func layoutSubviews() {
        connectCamera.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        startLiveView.frame = CGRect(x: 0, y: 100, width: 200, height: 100)
        takePicture.frame = CGRect(x: 0, y: 200, width: 200, height: 100)
        stopCont.frame = CGRect(x: 0, y: 300, width: 200, height: 100)
        getEvent.frame = CGRect(x: 0, y: 400, width: 200, height: 100)
        imageView.frame = CGRect(x: 0, y: 500, width: 300, height: 200)
    }
    
}
