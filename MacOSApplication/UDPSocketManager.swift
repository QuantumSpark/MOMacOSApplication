import Foundation
import CocoaAsyncSocket

open class UDPSocketManager: NSObject, GCDAsyncUdpSocketDelegate {
    static let masterPort = UInt16(10101)
    static let peripheralPort = UInt16(11111)
    static let masterHost = "10.0.0.116"
    static let broadcastHost = "10.0.255.255"

    //255.255.0.0 (DHCP subnet mask)
    //10.0.0.2 (router network)
    static let sharedManager = UDPSocketManager()

    let maxDeviceID = 28

    var bound = false

    //the socket that will be used to connect to the core app
    var socket: GCDAsyncUdpSocket!

    open lazy var deviceID: Int = 20

    public override init() {
        super.init()

        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        socket.setIPv4Enabled(true)
        socket.setIPv6Enabled(false)
        open()

        let packet = Packet(type: .handshake, id: deviceID)
        socket.send(packet.serialize() as Data, toHost: UDPSocketManager.masterHost, port: UDPSocketManager.masterPort, withTimeout: -1, tag: 0)
    }

    open func close() {
        socket.close()
        bound = false
    }

    open func open() {
        if !bound {
            do {
                try socket.enableBroadcast(true)
                try socket.bind(toPort: UDPSocketManager.peripheralPort)
                try socket.beginReceiving()
                print("Connected to UDP host")
            } catch {
                print("could not open socket")
                return
            }
            bound = true

        }
    }

    open func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var packet: Packet!
        do {
            packet = try Packet((data as NSData) as Data)
        } catch {
            return
        }
        if let data = packet.payload {
            print(data.count)
        }

//        switch packet.packetType {
//            case .play:
//                print("ISPLAYING")
//                TCPSocketManager.sharedManager.listOfItems[packet.id].isPlaying = true
//            case .stop:
//                TCPSocketManager.sharedManager.listOfItems[packet.id].isPlaying = false
//                print("ISSTOPING")
//            default:
//                print("nothing")
//
//        }


    }

    open func broadcastPacket(_ packet: Packet) {
        socket.send(packet.serialize(), toHost: UDPSocketManager.broadcastHost, port: UDPSocketManager.peripheralPort, withTimeout: -1, tag: 0)
    }
}

