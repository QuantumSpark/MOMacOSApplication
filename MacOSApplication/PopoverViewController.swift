//
//  PopoverViewController.swift
//  MacOSApplication
//
//  Created by James Park on 2018-02-04.
//  Copyright © 2018 James Park. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController {

    var dataIpad: DataIPad?
    var id: Int?
    @IBAction func zoomIn(_ sender: Any) {
        let packet = Packet(type: .zoomIn, id: self.id!)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: self.id!)
    }
    

    @IBOutlet weak var cameraExposure: NSSlider!
    
    @IBAction func cameraExposure(_ sender: Any) {
        let packet = Packet(type: .changeExposure, id: self.id!, payload: NSData(bytes: &cameraExposure.floatValue, length: MemoryLayout<Float>.size) as Data)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: self.id!)
    }
    @IBAction func zoomOut(_ sender: Any) {
        let packet = Packet(type: .zoomOut, id: id!)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: id!)
    }
    
    @IBOutlet weak var redBalance: NSSlider!
    
    @IBOutlet weak var greenBalance: NSSlider!
    
    @IBOutlet weak var blueBalance: NSSlider!
    
    
    var initialRedBalance =  Float(1)
    var initialBlueBalance = Float(1)
    var intialGreenBalance = Float(1)
    

    @IBAction func changeRedBalance(_ sender: Any) {
        let packet = Packet(type: .redGain, id: id!, payload: NSData(bytes: &redBalance.floatValue, length: MemoryLayout<Float>.size) as Data)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: id!)
    }
    
    @IBAction func changeGreenBalance(_ sender: Any) {
        let packet = Packet(type: .greenGain, id: id!, payload: NSData(bytes: &greenBalance.floatValue, length: MemoryLayout<Float>.size) as Data)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: id!)
    }
    
    @IBAction func changeBlueBalance(_ sender: Any) {
        let packet = Packet(type: .blueGain, id: id!, payload: NSData(bytes: &blueBalance.floatValue, length: MemoryLayout<Float>.size) as Data)
        dataIpad?.socket.write(packet.serialize(), withTimeout: -1, tag: id!)
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
        
        
        redBalance.floatValue = initialRedBalance
        blueBalance.floatValue = initialBlueBalance
        greenBalance.floatValue = intialGreenBalance
    }
    
}
