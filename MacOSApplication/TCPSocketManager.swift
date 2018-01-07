//
//  TCPSocketManager.swift
//  MacOSApplication
//
//  Created by James Park on 2018-01-04.
//  Copyright © 2018 James Park. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import AVFoundation

open class TCPSocketManager: NSObject, GCDAsyncSocketDelegate {

    private let nStartCodeLength:size_t = 4
    private let nStartCode:[UInt8] = [0x00, 0x00, 0x00, 0x01]
    private var timescale = 1000000000
    var connectedSockets = [GCDAsyncSocket]()

    var listOfTempFrame = [ [UInt8(0)], [UInt8(0)]]
    var numbOfIPads = -1

    private var numOfFrames = 0

    static let sharedManager = TCPSocketManager()

    //the socket that will be used to connect to the core app
    var socket: GCDAsyncSocket!

    var listOfItems = [CollectionViewItem]()
    var corruptedFrames = 0

    var deviceID = 0

    var newAsyncSocket:GCDAsyncSocket!

    public override init() {
        super.init()

        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)

        do {
            try socket.accept(onPort: 3000)
        } catch {
            print("Failed to connect")
        }

        let port = socket.localPort

        print("\(port)")
    }


    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        numbOfIPads-=1
        print("There are \(numbOfIPads) ipads connected")
        print("Disconnected")
        print(err)
    }

    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("Accept to new socket")

        self.connectedSockets.append(newSocket)
        listOfTempFrame.append([UInt8(0)])
        numbOfIPads+=1

        var num = 0;

        for i in 0..<listOfItems.count {
            if listOfItems[i].id == -1 {
                listOfItems[i].id = i
                num = i
                break
            }
        }

        print("There are \(numbOfIPads) ipads connected. Its id is \(num)")
        newAsyncSocket = newSocket
        let welcomMessage = "IPad is now connected to the Mac computer";
        let welcomePacket =  Packet(type: .handshake, id: num, payload: welcomMessage.data(using: .utf8)!)
         newAsyncSocket.write(welcomePacket.serialize(), withTimeout: -1, tag: num)
        newAsyncSocket.readData(withTimeout: -1, tag: num)

        // TODO get a message from IPad for connection checking
    }

    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        sock.readData(withTimeout: -1, tag: tag)
        if tag > -1 {
            let item = listOfItems[tag]
            if listOfItems[tag].isConnected {

                if  item.isDownloading && !item.isPlaying {
                    if item.videoDownloadSize > -1 {
                        item.currentVideoContent.append(data)
                        let progress = Double(100*(Double(item.currentVideoContent.length)/Double(item.videoDownloadSize)))
                        listOfItems[tag].downloadingProgress.stringValue = "\(round(progress))%"
                        if (item.currentVideoContent.length == item.videoDownloadSize) {
                            do {
                                let documents =  FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                                let writePath = documents.appendingPathComponent("Ipad\(tag).mp4")
                                try item.currentVideoContent.write(to: writePath, options: .atomic)
                                listOfItems[tag].playingStatus.stringValue = "Finished Downloading"
                                listOfItems[tag].downloadButton.stringValue = "0.0%"
                                listOfItems[tag].downloadButton.isHidden = true
                                listOfItems[tag].isDownloading = false
                                item.currentVideoContent = NSMutableData()
                                item.videoDownloadSize = -1
                                listOfItems[tag].downloadingProgress.isHidden = true
                                let confirmedPacket = Packet(type: .finishSendingVideoFile, id: tag)
                                connectedSockets[tag].write(confirmedPacket.serialize(), withTimeout: -1, tag: tag)
                                return
                            } catch let error {
                                print(error)
                                listOfItems[tag].downloadButton.stringValue = "0.0%"
                                listOfItems[tag].downloadingProgress.isHidden = true
                                listOfItems[tag].playingStatus.stringValue = "Error in Downloading. Try Again?"
                                let confirmedPacket = Packet(type: .finishSendingVideoFile, id: tag)
                                connectedSockets[tag].write(confirmedPacket.serialize(), withTimeout: -1, tag: tag)
                                item.currentVideoContent = NSMutableData()
                                item.videoDownloadSize = -1
                            }
                        }
                    } else {
                        item.videoDownloadSize = data.integer
                    }
                    return
                }

                updateDisplay(data, withTag: tag)

            }   else  {


                var p:Packet?

                do {
                    p = try Packet((data as NSData) as Data)
                } catch {
                    return
                }

                guard let packet = p else {
                    return
                }
                switch packet.packetType {
                case PacketType.handshake :
                    guard let payload = packet.payload else {
                        return
                    }
                    let connectedString = String(data: payload, encoding: String.Encoding.utf8)!
                    listOfItems[tag].isConnected = true
                    listOfItems[tag].connectionStatus.stringValue = connectedString
                default:
                    print("Hello")
                }

            }
        }
//        var packet: Packet!
//        do {
//            packet = try Packet((data as NSData) as Data)
//        } catch {
//             updateDisplay(data, withTag: tag)
//        }
//        guard let p = packet else  {
//            updateDisplay(data, withTag: tag)
//            return
//        }
//        switch p.packetType {
//            case PacketType.handshake :
//                let stringData = p.payload
//                print(String(data: stringData!, encoding: String.Encoding.utf8)!)
////            case PacketType.sendVideoData:
////                let videoData = p.payload
////                updateDisplay(videoData!, withTag: p.id)
//        default:
//            print("Hello")
//        }
    }

    public func updateDisplay(_ data: Data, withTag tag: Int) {
        let wholeData = Array(data)
        var i = 0
        while (i<=wholeData.count-1){
            if ( listOfTempFrame[tag].count>=4) {
                let tempFrameSize =  listOfTempFrame[tag].count
                if ( listOfTempFrame[tag][tempFrameSize-1] == 0xFF &&  listOfTempFrame[tag][tempFrameSize-2] == 0xFF &&  listOfTempFrame[tag][tempFrameSize-3] == 0xFF &&  listOfTempFrame[tag][tempFrameSize-4] == 0xFF){
                    print("===============================================================")
                    let frameData = (Data(bytes:  listOfTempFrame[tag]))
                    generateCMSampleBuffer(frameData, tag)
                    listOfTempFrame[tag] = [UInt8(0)]

                }else{
                    listOfTempFrame[tag].append(wholeData[i])
                }
            } else{
                listOfTempFrame[tag].append(wholeData[i])
            }
            i = i + 1
        }
    }

    private func generateCMSampleBuffer(_ elementaryStream:Data, _ tag:Int) {
        print("So far we have this many corrupted frames: \(corruptedFrames)")
        let (formatDescription, offset) = constructCMVideoDescription(from:  NSMutableData(data: elementaryStream ))
        guard formatDescription != nil, offset != nil else {
            corruptedFrames += 1
            print("OHH NOOO D: D: Corrupted Frames: so far we have this many corrupted frames: \(corruptedFrames)")
            return
        }
        let (optionalCmblockbuffer, optionalSecondOffset) = constructCMBlockBuffer(from: NSMutableData(data: elementaryStream ), with: offset!)

        guard let cmblockbuffer = optionalCmblockbuffer, let secondOffset = optionalSecondOffset else {
            corruptedFrames += 1
            print("OHH NOOO D: D: Corrupted Frames: so far we have this many corrupted frames: \(corruptedFrames)")
            return
        }
        let (optionalTimeSecond, optionalthirdOffset) = constructSeconds(from:  NSMutableData(data: elementaryStream ), with: secondOffset)

        guard let timeSecond = optionalTimeSecond, let thirdOffset = optionalthirdOffset else {
            corruptedFrames += 1
            print("OHH NOOO D: D: Corrupted Frames: so far we have this many corrupted frames: \(corruptedFrames)")
            return
        }

        let deviceID = constructID(from: NSMutableData(data: elementaryStream ), with: thirdOffset)
        let pTS = CMTime(seconds: timeSecond, preferredTimescale: CMTimeScale(self.timescale))
        var sampleSize = CMBlockBufferGetDataLength(cmblockbuffer)
        var timing = CMSampleTimingInfo(duration: CMTime(), presentationTimeStamp: pTS, decodeTimeStamp: CMTime())

        var reconstructedSampleBuffer: CMSampleBuffer?

        let statusBuffer = CMSampleBufferCreate(kCFAllocatorDefault, cmblockbuffer, true, nil, nil, formatDescription, 1, 1, &timing, 1, &sampleSize, &reconstructedSampleBuffer)

        if statusBuffer == noErr {
            print("Succeeded in making a CMSampleBuffer")
            self.numOfFrames=self.numOfFrames+1
            print("We have \(self.numOfFrames) frames")
            let attachments = CMSampleBufferGetSampleAttachmentsArray(reconstructedSampleBuffer!, true)
            let dict = CFArrayGetValueAtIndex(attachments, 0)
            let dictRef = unsafeBitCast(dict, to: CFMutableDictionary.self)

            CFDictionarySetValue(dictRef, unsafeBitCast(kCMSampleAttachmentKey_DisplayImmediately, to: UnsafeRawPointer.self), unsafeBitCast(kCFBooleanTrue, to :UnsafeRawPointer.self ))
//            print("DisplayLayer can display? \(workspace?.listOfDisplaySampleLayer[0].isReadyForMoreMediaData)")
//            workspace?.listOfDisplaySampleLayer[tag].enqueue(reconstructedSampleBuffer!)
            listOfItems[tag].displayLayer.enqueue(reconstructedSampleBuffer!)

        } else {
            print("Error: ")
        }

    }
    private func constructSeconds(from data: NSMutableData, with secondOffset : Int) -> (Double?, Int?) {
        let tmpptr = data.bytes.assumingMemoryBound(to: UInt8.self)
        let ptr = UnsafeMutablePointer<UInt8>(mutating: tmpptr)
        let idOffset = findStartCode(using: ptr, offset: secondOffset, count: data.length)
        if (idOffset == -1) {
            return (nil, nil)
        }
        let dataSize = idOffset - secondOffset - nStartCodeLength - nStartCodeLength
        let secondDataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)

        memcpy(secondDataPointer, &ptr[Int(secondOffset+4)], dataSize)

        let secondData = NSData(bytes: secondDataPointer, length: dataSize)

        let reconstructedSecondData = (secondData as Data).double


        return (reconstructedSecondData, idOffset)
    }

    private func constructID (from data: NSMutableData, with thirdOffset : Int) -> Int {
        let tmpptr = data.bytes.assumingMemoryBound(to: UInt8.self)
        let ptr = UnsafeMutablePointer<UInt8>(mutating: tmpptr)
        let dataSize = data.length - thirdOffset - nStartCodeLength
        let deviceIDPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)

        memcpy(deviceIDPointer, &ptr[Int(thirdOffset+4)], dataSize)


        let deviceIDData = NSData(bytes: deviceIDPointer, length: 1)
        print("The data for deviceName \(deviceIDData)")
        return (deviceIDData as Data).integer
    }



    private func constructCMVideoDescription(from data: NSMutableData) -> (CMFormatDescription?, Int?) {
        var formatDesc:CMFormatDescription?

        let naluData = UnsafeMutablePointer<UInt8>(mutating: data.bytes.assumingMemoryBound(to: UInt8.self))
        let ptr = UnsafeMutablePointer<UInt8>(mutating: naluData)

        let secondStartCodeIndex = findStartCode(using: ptr, offset: 0, count: data.length)
        if (secondStartCodeIndex == -1) {
            return (nil, nil)
        }
        if secondStartCodeIndex > 256 {
            return (nil, nil)
        }
        let spsSize = UInt8(secondStartCodeIndex)

        let thirdStartCodeIndex = findStartCode(using: ptr, offset: Int(spsSize),count: data.length)
        var ppsSize = UInt8()
        if thirdStartCodeIndex == -1 {
            ppsSize = UInt8(data.length - Int(spsSize))
        } else {
            ppsSize = UInt8(Int(thirdStartCodeIndex) - Int(spsSize))
        }

        let sps = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(spsSize) - 4)
        let pps = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(ppsSize) - 4)
        // copy in the actual sps and pps values, again ignoring the 4 byte header

        memcpy(sps, &ptr[4] , Int(spsSize) - 4)
        memcpy(pps, &ptr[Int(spsSize)+4], Int(ppsSize) - 4)

        let spsPointer = UnsafePointer<UInt8>(sps)
        let ppsPointer = UnsafePointer<UInt8>(pps)

        // now we set our H264 parameters
        let parameterSetArray = [spsPointer, ppsPointer]

        let parameterSetPointers = UnsafePointer<UnsafePointer<UInt8>>(parameterSetArray)
        let sizeParamArray = [Int(spsSize - 4), Int(ppsSize - 4)]


        let parameterSetSizes = UnsafePointer<Int>(sizeParamArray)
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            kCFAllocatorDefault,
            2,
            parameterSetPointers,
            parameterSetSizes,
            4,
            &formatDesc
        )

        if status == noErr {
            print("CMVideoFormatDescription has been successfully created")
        } else {
            print("Failed to create CMVideoFormatDescription")
            return (nil,Int(ppsSize + spsSize))
        }

        return (formatDesc , Int(ppsSize + spsSize))
    }
    private func constructCMBlockBuffer (from elementaryStream: NSMutableData, with offset: Int) -> (CMBlockBuffer?, Int?) {
        var cmblockBuffer: CMBlockBuffer?
        let tmpptr = elementaryStream.bytes.assumingMemoryBound(to: UInt8.self)
        let ptr = UnsafeMutablePointer<UInt8>(mutating: tmpptr)

        let timeCodeIndex = findStartCode(using: ptr, offset: offset, count: elementaryStream.length)

        if ( timeCodeIndex == -1 ) {
            return (nil, nil)
        }

        let dataSize = timeCodeIndex - offset - nStartCodeLength

        let frameData = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)

        memcpy(frameData, &ptr[Int(offset+4)], dataSize)

        let status = CMBlockBufferCreateWithMemoryBlock(nil, frameData,  // memoryBlock to hold buffered data
            dataSize,  // block length of the mem block in bytes.
            kCFAllocatorNull, nil,
            0, // offsetToData
            dataSize,   // dataLength of relevant bytes, starting at offsetToData
            0, &cmblockBuffer);

        if status == noErr {
            print("CMBlockBuffer has been successfully created")
        } else {
            print("Failed to create CMBlockBuffer")
        }
        return (cmblockBuffer!, timeCodeIndex)
    }

    private func findStartCode(using dataPointer: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) -> Int {
        for i in offset + 4..<count {
            if dataPointer[i] == 0x00 && dataPointer[i + 1] == 0x00 && dataPointer[i + 2] == 0x00 && dataPointer[i + 3] == 0x01 {
                return i
            }
        }
        return -1
    }
}
