// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

import Foundation

/// Determines the type of a packet.
public struct PacketType: RawRepresentable, Equatable {
    public var rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// First packet sent when a connection is made.
    public static let handshake = PacketType(rawValue: 0)

    /// Packet sent periodically for video data
    public static let sendVideoData = PacketType(rawValue: 1)

    /// Packet sent to stop
    public static let play = PacketType(rawValue: 2)

    public static let stop = PacketType(rawValue: 3)

    public static let sendVideoFile = PacketType(rawValue: 4)

    public static let finishSendingVideoFile = PacketType(rawValue: 5)

    public static let changeExposure = PacketType(rawValue:6)
    
    public static let zoomIn = PacketType(rawValue: 7)
    
    public static let zoomOut = PacketType(rawValue: 8)

    public static func == (lhs: PacketType, rhs: PacketType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

/// Possible errors encountered when serializing/deserializing a `Packet`.
public enum PacketSerializationError: Error {
    case notEnoughData
}

/// Communication packet.
public struct Packet: Equatable {
    /// The size of a packet with no payload.
    public static let basePacketSize = MemoryLayout<UInt32>.size + MemoryLayout<PacketType>.size + MemoryLayout<Int32>.size

    /// The packet type.
    public var packetType: PacketType

    /// The packet identifier.
    public var id = -1

    /// Payload data.
    public var payload: Data?

    /// Creates a `Packet` with a specifc packet type, identifier and optional payload data.
    public init(type: PacketType, id: Int, payload: Data? = nil) {
        self.packetType = type
        self.id = id
        self.payload = payload
    }

    /// Serializes the packet.
    public func serialize() -> Data {
        let payloadSize = payload?.count ?? 0
        let packetSize = UInt32(Packet.basePacketSize + payloadSize)
        var packetData = Data(capacity: Int(packetSize))

        // The first element in the packet data needs to be the packet size to know if we have enought data to build the packet.
        packetData.append(packetSize)
        packetData.append(packetType.rawValue)
        packetData.append(Int32(id))

        if let d = payload, d.count > 0 {
            packetData.append(d)
        }
        return packetData
    }

    /// Deserializes a packet.
    public init(_ packetData: Data) throws {
        var index = 0

        let packetSize = packetData.extract(UInt32.self, at: index)
        if packetData.count < Int(packetSize) {
            throw PacketSerializationError.notEnoughData
        }
        index += MemoryLayout.size(ofValue: packetSize)

        packetType = PacketType(rawValue: packetData.extract(PacketType.RawValue.self, at: index))
        index += MemoryLayout.size(ofValue: packetType)

        id = Int(packetData.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size

        let payloadSize = Int(packetSize) - Packet.basePacketSize
        if payloadSize > 0 {
            payload = packetData.subdata(in: packetData.startIndex.advanced(by: index) ..< packetData.startIndex.advanced(by: index + payloadSize))
        }
    }

    public var description: String {
        return "Packet: \(packetType), \(id), \(payload == nil ? "No Data" : "\(payload!.count) bytes of payload")"
    }
}

public func == (lhs: Packet, rhs: Packet) -> Bool {
    return lhs.packetType == rhs.packetType && lhs.id == rhs.id
}

extension Data {
    /// Extracts a specific type from raw data.
    ///
    /// - Parameters:
    ///   - type: the stored type
    ///   - offset: the offset in bytes
    /// - Returns: the stored valye
    public func extract<T>(_ type: T.Type, at offset: Int) -> T {
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> T in
            pointer.advanced(by: offset).withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
    }

    /// Appends a specific value as raw data.
    ///
    /// - Parameter value: the value to append
    public mutating func append<T>(_ value: T) {
        var varValue = value
        withUnsafePointer(to: &varValue) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                append($0, count: MemoryLayout<T>.size)
            }
        }
    }
}

