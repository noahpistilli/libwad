//
//  Helpers.swift
//  libwad
//
//  Created by Noah Pistilli on 2021-12-07.
//

import Foundation

public enum WADType: UInt32 {
    case WADTypeCommon = 0x49730000
    case WADTypeBoot = 0x69620000
    case WADTypeUnknown = 0x426b000
}

enum Errors: Error {
    case mismatchingSHA1
    case mismatchingHeaderSize
    case incorrectFileSize
}


/// Reads multiple bytes from a specified offset in data and returns them in a UInt8 array
/// - parameter data: Data object to read from
/// - parameter length: Amount of data to be read
/// - parameter position: Offset to data
func readBytes(_ data: Data, length: Int, at position: Int) -> [uint8] {
    let NSrange = NSRange(location: position, length: length)
    let range = Range(NSrange)!

    let bytes = data.subdata(in: range)

    return [uint8](bytes)
}

/// Reads a single byte from a specified offset in data
/// - parameter data: Data object to read from
/// - parameter position: Offset to data
func readByte(_ data: Data, at position: Int) -> uint8 {
    let dataType = data.withUnsafeBytes { $0.load(fromByteOffset: position, as: uint8.self) }
    
    return dataType
}

/// Reads 2 bytes from a specified offset in data
/// - parameter data: Data object to read from
/// - parameter position: Offset to data
func readUint16(_ data: Data, at position: Int) -> uint16 {
    let dataType = data.withUnsafeBytes { $0.load(fromByteOffset: position, as: uint16.self) }
    
    return dataType
}

/// Reads 4 bytes from a specified offset in data
/// - parameter data: Data object to read from
/// - parameter position: Offset to data
func readUint32(_ data: Data, at position: Int) -> uint32 {
    let dataType = data.withUnsafeBytes { $0.load(fromByteOffset: position, as: uint32.self)}
    
    return dataType
}

/// Reads 8 bytes from a specified offset in data
/// - parameter data: Data object to read from
/// - parameter position: Offset to data
func readUint64(_ data: Data, at position: Int) -> uint64 {
    let dataType = data.withUnsafeBytes { $0.load(fromByteOffset: position, as: uint64.self)}
    
    return dataType
}

/// Reads data from a specific offset in data and returns it as a Data object
/// - parameter data: Data object to read from
/// - parameter length: Amount of data to be read
/// - parameter position: Offset to data
func readData(_ data: Data, length: Int, at position: Int) -> Data {
    let NSrange = NSRange(location: position, length: length)
    let range = Range(NSrange)!

    let bytes = data.subdata(in: range)

    return bytes
}

/// Returns the passed size padded to the nearest 0x40/64-byte boundary
func getPadding(size: Int) -> Int {
    if size == 0 {
        return 0
    }
    
    // We can calculate padding from the remainder.
    let leftover = size % 64
    if leftover == 0 {
        return 0
    } else {
        return 64 - leftover
    }
    
}

func pad(data: Data) -> Data {
    var paddedData = data
    let paddedSize = getPadding(size: data.count)
    
    for _ in paddedData.count..<paddedSize+paddedData.count {
        paddedData.append(0)
    }
    
    return paddedData
}
