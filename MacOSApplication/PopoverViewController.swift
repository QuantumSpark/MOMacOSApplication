//
//  PopoverViewController.swift
//  MacOSApplication
//
//  Created by James Park on 2018-02-04.
//  Copyright © 2018 James Park. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController {

    @IBAction func zoomIn(_ sender: Any) {
        
    }
    

    @IBOutlet weak var cameraExposure: NSSlider!
    
    @IBAction func cameraExposure(_ sender: Any) {
    }
    @IBAction func zoomOut(_ sender: Any) {
    }
    
    @IBOutlet weak var redBalance: NSSlider!
    
    @IBOutlet weak var greenBalance: NSSlider!
    
    @IBOutlet weak var blueBalance: NSSlider!
    
    @IBAction func changeRedBalance(_ sender: Any) {
    }
    
    @IBAction func changeGreenBalance(_ sender: Any) {
    }
    
    @IBAction func changeBlueBalance(_ sender: Any) {
    }
    
    var test = "Hello"
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraExposure.maxValue = 1;
        cameraExposure.minValue = 0;
        redBalance.maxValue = 4;
        redBalance.minValue = 1;
        greenBalance.maxValue = 4;
        greenBalance.minValue = 1;
        blueBalance.maxValue = 4;
        blueBalance.minValue = 1;
    }
    
}
