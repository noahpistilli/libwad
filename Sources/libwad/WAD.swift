//
//  WAD.swift
//  libwad
//
//  Created by Noah Pistilli on 2021-12-07.
//

import Foundation

/// Variable that stores our position in the file
internal var pointer = 32

/// Describes the binary structure of a WAD file
public struct WAD: Codable {
    public var Header: WADHeader
    public var CertificateChain: Data
    public var CertificateRevocationList: Data
    public var Ticket: Ticket
    public var TMD: TMD
    public var Contents: [Content]
    public var Meta: Data
}

/// Struct of the WADHeader
public struct WADHeader: Codable {
    let HeaderSize: u32
    let WADType: u32
    let CertificateSize: u32
    let CRLSize: u32
    let TicketSize: u32
    let TMDSize: u32
    let DataSize: u32
    let MetaSize: u32
}

/// Reads data from the WAD and returns the WAD object
/// - parameter data: Data object to read from
public func LoadWAD(data: Data) throws -> WAD {
    let header = readWadHeader(data)
    
    // The header must be 32 bytes
    if header.HeaderSize.bigEndian != 32 {
        throw Errors.mismatchingHeaderSize
    }
    
    // Sanity check
    if header.CertificateSize.bigEndian + header.CRLSize.bigEndian + header.TicketSize.bigEndian + header.TMDSize.bigEndian + header.DataSize.bigEndian + header.MetaSize.bigEndian > data.count {
        throw Errors.incorrectFileSize
    }
    
    // Certificate is next
    pointer += getPadding(size: pointer)
    
    let cert = readData(data, length: Int(header.CertificateSize.bigEndian), at: pointer)
    
    pointer += Int(header.CertificateSize.bigEndian)
    pointer += getPadding(size: pointer)
    
    // Read CRL
    let crl = readData(data, length: Int(header.CRLSize.bigEndian), at: pointer)
    
    pointer += Int(header.CRLSize.bigEndian)
    pointer += getPadding(size: pointer)
    
    // Read ticket
    let ticket = try Ticket(data: data)
    
    pointer += getPadding(size: pointer)
    
    // Read title metadata
    let tmd = TMD(data: data)
    
    // Create WAD struct
    var wad = WAD(Header: header, CertificateChain: cert, CertificateRevocationList: crl, Ticket: ticket, TMD: tmd, Contents: [], Meta: Data())
    
    // Read the contents.
    wad.LoadData(data: data)
    
    // Finally, read the meta at the end.
    wad.Meta = readData(data, length: Int(header.MetaSize.bigEndian), at: pointer)
        

    return wad
}


func readWadHeader(_ data: Data) -> WADHeader {
    return WADHeader(
        HeaderSize: readUint32(data, at: 0),
        WADType: readUint32(data, at: 4),
        CertificateSize: readUint32(data, at: 8),
        CRLSize: readUint32(data, at: 12),
        TicketSize: readUint32(data, at: 16),
        TMDSize: readUint32(data, at: 20),
        DataSize: readUint32(data, at: 24),
        MetaSize: readUint32(data, at: 28)
    )
}

extension WAD {
    public func GetHeader() -> Data {
        let header = self.Header
        var byteArray: [byte] = []
        
        byteArray += withUnsafeBytes(of: header.HeaderSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.WADType.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.CertificateSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.CRLSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.TicketSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.TMDSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.DataSize.bigEndian) { Array($0) }
        byteArray += withUnsafeBytes(of: header.MetaSize.bigEndian) { Array($0) }
        
        return Data(bytes: &byteArray, count: byteArray.count)
    }
    
    public mutating func GetWAD(wadType: WADType) throws -> Data {
        let ticket = try self.GetTicket()
        
        // Here is a good time to update our TMD
        for (i, content) in self.Contents.enumerated() {
            self.TMD.ContentRecords[i].Size = content.contentRecord.Size
            self.TMD.ContentRecords[i].Hash = content.contentRecord.Hash
        }
        
        // Now we can get our updated TMD
        let tmd = self.GetTMD()
        
        let contents = self.GetData()
        
        // Create our header
        let header = WADHeader(
            HeaderSize: 32,
            WADType: wadType.rawValue,
            CertificateSize: u32(self.CertificateChain.count),
            CRLSize: u32(self.CertificateRevocationList.count),
            TicketSize: u32(ticket.count),
            TMDSize: u32(tmd.count),
            DataSize: u32(contents.count),
            MetaSize: u32(self.Meta.count)
        )
        
        self.Header = header
        let headerContents = self.GetHeader()
        
        // We can now append our data to an array then to Data
        var wad: [byte] = []
        
        wad += pad(data: headerContents).bytes
        wad += pad(data: self.CertificateChain).bytes
        wad += pad(data: ticket).bytes
        wad += pad(data: tmd).bytes
        wad += pad(data: contents).bytes
        wad += pad(data: self.Meta).bytes
        
        return Data(bytes: &wad, count: wad.count)
    }
}
