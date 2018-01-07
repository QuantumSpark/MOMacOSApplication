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

    var displayLayer = AVSampleBufferDisplayLayer()
    var id = -1

    var isPlaying = false

    var isConnected = false

    var isDownloading = false


    var videoDownloadSize = -1
    var currentVideoContent = NSMutableData()

    @IBOutlet weak var downloadingProgress: NSTextField!
    @IBOutlet weak var connectionStatus: NSTextField!
    @IBOutlet weak var playingStatus: NSTextField!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        let height = CGFloat(self.view.bounds.height)
        let width = CGFloat(self.view.bounds.width)
        displayLayer.bounds = CGRect(x: CGFloat(Double(height)*0.5), y: CGFloat(Double(height)*0.5 - 20), width: width*0.8, height: height*0.8)
        displayLayer.position = CGPoint(x: 0.5*width , y: 0.5*height - 20)

        displayLayer.borderWidth = 1
        displayLayer.borderColor = NSColor.blue.cgColor
        self.view.layer?.addSublayer(displayLayer)

        // Do view setup here.
    }
    @IBAction func startStreaming(_ sender: Any) {
        if !isPlaying {
            isPlaying = true
            downloadButton.isHidden = true
            self.playingStatus.stringValue = "Playing"
            let packet = Packet(type: .play, id: id)
            TCPSocketManager.sharedManager.connectedSockets[id].write(packet.serialize(), withTimeout: -1, tag: id)
        }
    }

    @IBAction func stopStreaming(_ sender: Any) {
        if isPlaying {
            isPlaying = false
            downloadButton.isHidden = false
            self.playingStatus.stringValue = "Stopped"
            let packet = Packet(type: .stop, id: id)
            TCPSocketManager.sharedManager.connectedSockets[id].write(packet.serialize(), withTimeout: -1, tag: id)
        }
    }

    @IBAction func downloadTheFile(_ sender: Any) {
        self.playingStatus.stringValue = "Telling the Ipad to Upload the Video File ..."
        let packet = Packet(type: .sendVideoFile, id: id)
        isDownloading = true

        self.downloadingProgress.isHidden = false
        TCPSocketManager.sharedManager.connectedSockets[id].write(packet.serialize(), withTimeout: -1, tag: id)

    }
    override func viewDidAppear() {
        print("Hello")
    }

    override func viewDidDisappear() {
         print("Disappear")
    }
}
