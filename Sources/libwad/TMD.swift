//
//  TMD.swift
//  libwad
//
//  Created by Noah Pistilli on 2021-12-08.
//

import Foundation

public struct TMD: Codable {
    public var SignatureType: uint32
    public var Signature: [uint8]
    public var Padding: [uint8]
    public var Issuer: [uint8]
    public var FileVersion: uint8
    public var CACRLVersion: uint8
    public var SignerCRLVersion: uint8
    public var IsvWii: uint8
    public var SystemVersionHigh: uint32
    public var SystemVersionLow: uint32
    public var TitleID: [uint8]
    public var TitleType: uint32
    public var GroupID: uint16
    public var Unknown: uint16
    public var Region: uint16
    public var Ratings: [uint8]
    public var Reserved: [uint8]
    public var IPCMask: [uint8]
    public var Reserved2: [uint8]
    public var AccessRightsFlags: uint32
    public var TitleVersion: uint16
    public var NumberOfContents: uint16
    public var BootIndex: uint16
    public var Padding2: uint16
    public var ContentRecords: [ContentRecord]
    
    init(data: Data) {
        self.SignatureType = readUint32(data, at: pointer)
        pointer += 4
        self.Signature = readBytes(data, length: 256, at: pointer)
        pointer += 256
        self.Padding = readBytes(data, length: 60, at: pointer)
        pointer += 60
        self.Issuer = readBytes(data, length: 64, at: pointer)
        pointer += 64
        self.FileVersion = readByte(data, at: pointer)
        pointer += 1
        self.CACRLVersion = readByte(data, at: pointer)
        pointer += 1
        self.SignerCRLVersion = readByte(data, at: pointer)
        pointer += 1
        self.IsvWii = readByte(data, at: pointer)
        pointer += 1
        self.SystemVersionHigh = readUint32(data, at: pointer)
        pointer += 4
        self.SystemVersionLow = readUint32(data, at: pointer)
        pointer += 4
        self.TitleID = readBytes(data, length: 8, at: pointer)
        pointer += 8
        self.TitleType = readUint32(data, at: pointer)
        pointer += 4
        self.GroupID = readUint16(data, at: pointer)
        pointer += 2
        self.Unknown = readUint16(data, at: pointer)
        pointer += 2
        self.Region = readUint16(data, at: pointer)
        pointer += 2
        self.Ratings = readBytes(data, length: 16, at: pointer)
        pointer += 16
        self.Reserved = readBytes(data, length: 12, at: pointer)
        pointer += 12
        self.IPCMask = readBytes(data, length: 12, at: pointer)
        pointer += 12
        self.Reserved2 = readBytes(data, length: 18, at: pointer)
        pointer += 18
        self.AccessRightsFlags = readUint32(data, at: pointer)
        pointer += 4
        self.TitleVersion = readUint16(data, at: pointer)
        pointer += 2
        self.NumberOfContents = readUint16(data, at: pointer)
        pointer += 2
        self.BootIndex = readUint16(data, at: pointer)
        pointer += 2
        self.Padding2 = readUint16(data, at: pointer)
        pointer += 2
        
        // Now read the ContentRecord table
        var array: [ContentRecord] = []
        
        for _ in 1...self.NumberOfContents.bigEndian {
            // Raw pointer issues with u64 led to this
            let sizeArray = readBytes(data, length: 8, at: pointer+8)
            let sizeRawData = Data(bytes: sizeArray, count: 8)
            let size = uint64(littleEndian: sizeRawData.withUnsafeBytes { $0.pointee })

            array.append(
                ContentRecord(
                    ID: readUint32(data, at: pointer),
                    Index: readUint16(data, at: pointer+4),
                    ContentType: readUint16(data, at: pointer+6),
                    Size: size,
                    Hash: readBytes(data, length: 20, at: pointer+16)
                )
            )
            pointer += 36
        }
        
        self.ContentRecords = array
    }
}

public struct ContentRecord: Codable {
    public var ID: uint32
    public var Index: uint16
    public var ContentType: uint16
    public var Size: uint64
    public var Hash: [uint8]
}

extension WAD {
    /// Returns the TMD data in Data
    public func GetTMD() -> Data {
        let tmd = self.TMD
        
        var dataArray: [uint8] = []
        
        dataArray += withUnsafeBytes(of: tmd.SignatureType) { Array($0) }
        dataArray += tmd.Signature
        dataArray += tmd.Padding
        dataArray += tmd.Issuer
        dataArray.append(tmd.FileVersion)
        dataArray.append(tmd.CACRLVersion)
        dataArray.append(tmd.SignerCRLVersion)
        dataArray.append(tmd.IsvWii)
        dataArray += withUnsafeBytes(of: tmd.SystemVersionHigh) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.SystemVersionLow) { Array($0) }
        dataArray += tmd.TitleID
        dataArray += withUnsafeBytes(of: tmd.TitleType) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.GroupID) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.Unknown) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.Region) { Array($0) }
        dataArray += tmd.Ratings
        dataArray += tmd.Reserved
        dataArray += tmd.IPCMask
        dataArray += tmd.Reserved2
        dataArray += withUnsafeBytes(of: tmd.AccessRightsFlags) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.TitleVersion) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.NumberOfContents) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.BootIndex) { Array($0) }
        dataArray += withUnsafeBytes(of: tmd.Padding2) { Array($0) }
        
        for record in tmd.ContentRecords {
            dataArray += withUnsafeBytes(of: record.ID) { Array($0) }
            dataArray += withUnsafeBytes(of: record.Index) { Array($0) }
            dataArray += withUnsafeBytes(of: record.ContentType) { Array($0) }
            dataArray += withUnsafeBytes(of: record.Size) { Array($0) }
            dataArray += record.Hash
        }
        
        return Data(bytes: &dataArray, count: dataArray.count)
    }
    
    /// Loads a TMD into the WAD struct. Useful for replacing preexisting TMD's in WAD's
    public mutating func LoadTMD(data: Data) {
        // Store current pointer
        let currentPointer = pointer
        pointer = 0
        
        self.TMD = libwad.TMD(data: data)
        
        // Restore pointer
        pointer = currentPointer
    }
}
