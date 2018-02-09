//
//  ViewController.swift
//  SonyController
//
//  Created by Alexander Griswold on 1/14/18.
//  Copyright © 2018 com.example. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let controlView = ControlView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(controlView)
        
        //hide the navigation bar
        self.navigationController?.navigationBar.isHidden = true
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //hides the status bar from the app
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

