//
//  DataIPad.swift
//  MacOSApplication
//
//  Created by James Park on 2018-01-07.
//  Copyright © 2018 James Park. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import AVFoundation


class DataIPad {

    var id = -1
    var displayLayer =  AVSampleBufferDisplayLayer()
    var isPlaying = false
    var isConnected = false
    var isDownloading = false {
        didSet {

        }
    }


    var videoDownloadSize = -1
    var currentVideoContent = NSMutableData()
    var downloadingProgress = 0

    var socket:GCDAsyncSocket!

    init(){
        
    }

    weak var collectionViewItem:CollectionViewItem!

    func updateDownloadingProgress(with percentage: Double) {
        guard let item = collectionViewItem else {
            return
        }

        collectionViewItem?.downloadingProgress.stringValue = "\(round(percentage))%"
    }
}
