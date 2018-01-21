//
//  CollectionViewItem.swift
//  MacOSApplication
//
//  Created by James Park on 2018-01-02.
//  Copyright © 2018 James Park. All rights reserved.
//

import Cocoa
import AVFoundation

class CollectionViewItem: NSCollectionViewItem {
    var hasDisplayLayer = false

    var displayLayer = AVSampleBufferDisplayLayer()
    var id = -1 {
        didSet{
            connectionStatus.stringValue = "\(id)"
        }
    }


    weak var dataIPad: DataIPad! {
        didSet {
            self.displayLayer.removeFromSuperlayer()
            self.displayLayer = dataIPad.displayLayer
            self.addDisplayLayer()
            dataIPad.collectionViewItem = self
        }
    }


    @IBOutlet weak var downloadingProgress: NSTextField!
    @IBOutlet weak var connectionStatus: NSTextField!
    @IBOutlet weak var playingStatus: NSTextField!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var cameraExposure: NSSlider!
    
    @IBAction func changeExposure(_ sender: Any) {
        let packet = Packet(type: .changeExposure, id: id, payload: NSData(bytes: &cameraExposure.floatValue, length: MemoryLayout<Float>.size) as Data)
        dataIPad.socket.write(packet.serialize(), withTimeout: -1, tag: id)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDisplayLayer()
        cameraExposure.maxValue = 1;
        cameraExposure.minValue = 0;
    }

    func addDisplayLayer() {
        view.wantsLayer = true
        let height = CGFloat(self.view.bounds.height)
        let width = CGFloat(self.view.bounds.width)
        displayLayer.bounds = CGRect(x: CGFloat(Double(height)*0.5), y: CGFloat(Double(height)*0.5 - 20), width: width*0.8, height: height*0.8)
        displayLayer.position = CGPoint(x: 0.5*width , y: 0.5*height - 20)

        displayLayer.borderWidth = 1
        displayLayer.borderColor = NSColor.blue.cgColor
        self.view.layer?.addSublayer(displayLayer)
        hasDisplayLayer = true
    }

    @IBAction func startStreaming(_ sender: Any) {
        startStreaming()
    }

    @IBAction func stopStreaming(_ sender: Any) {
        stopStreaming()
    }

    @IBAction func zoomIn(_ sender: Any) {
        let packet = Packet(type: .zoomIn, id: id)
        dataIPad.socket.write(packet.serialize(), withTimeout: -1, tag: id)
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        let packet = Packet(type: .zoomOut, id: id)
        dataIPad.socket.write(packet.serialize(), withTimeout: -1, tag: id)
    }
    func startStreaming(){
        guard let ipadInfo = dataIPad, ipadInfo.isConnected else {
            return
        }

        if !dataIPad.isPlaying {
            dataIPad.isPlaying = true
            downloadButton.isHidden = true
            self.playingStatus.stringValue = "Playing"
            let packet = Packet(type: .play, id: id)
            ipadInfo.socket.write(packet.serialize(), withTimeout: -1, tag: id)
        }
    }

    func stopStreaming() {

        guard let ipadInfo = dataIPad, ipadInfo.isConnected else {
            return
        }
        if dataIPad.isPlaying {
            dataIPad.isPlaying = false
            downloadButton.isHidden = false
            self.playingStatus.stringValue = "Stopped"
            let packet = Packet(type: .stop, id: id)
            ipadInfo.socket.write(packet.serialize(), withTimeout: -1, tag: id)
        }
    }

    @IBAction func downloadTheFile(_ sender: Any) {
        self.playingStatus.stringValue = "Telling the Ipad to Upload the Video File ..."
        let packet = Packet(type: .sendVideoFile, id: id)
        dataIPad.isDownloading = true

        self.downloadingProgress.isHidden = false
        dataIPad.socket.write(packet.serialize(), withTimeout: -1, tag: id)

    }
    
    
    override func viewDidAppear() {
        startStreaming()
    }

    override func viewDidDisappear() {
        stopStreaming()

    }
}
