//
//  Contents.swift
//  libwad
//
//  Created by Noah Pistilli on 2021-12-08.
//

import Foundation
import CryptoSwift

public struct Content: Codable {
    public var contentRecord: ContentRecord
    public var rawData: Data
}


extension WAD {
    public mutating func LoadData(data: Data) {
        let contentRecords = self.TMD.ContentRecords
        var contents: [Content] = []
        pointer += getPadding(size: pointer)
        
        for content in contentRecords {
            var paddedSize = content.Size.bigEndian
            let leftover = paddedSize % 16
            if leftover != 0 {
                paddedSize += 16 - leftover
            }
                    
            contents.append(Content(contentRecord: content, rawData: readData(data, length: Int(paddedSize), at: pointer)))
            
            pointer += Int(paddedSize) + getPadding(size: Int(paddedSize))
        }
        
        self.Contents = contents
    }
    
    /// Returns the contents padded
    public func GetData() -> Data {
        var data: Data = Data()
        
        for content in self.Contents {
            data.append(pad(data: content.rawData))
        }
        
        return data
    }
}

extension Content {
    public mutating func DecryptData(titleKey: [uint8]) throws {
        let content = self.contentRecord
        
        // Create the IV based on the content index
        var iv: [uint8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        iv[0] = uint8(content.Index.bigEndian >> 8)
        iv[1] = uint8(content.Index.bigEndian & 0xFF)
        
        let decrypter = try AES(key: titleKey, blockMode: CBC(iv: iv))
        let decryptedData = try decrypter.decrypt(self.rawData.bytes)

        let hash = decryptedData.sha1()

        if hash != content.Hash {
            print("[libwad]: Content \(content.ID.bigEndian) did not match the hash in the TMD!")
            throw Errors.mismatchingSHA1
        }
        
        self.rawData = Data(bytes: decryptedData, count: Int(content.Size.bigEndian))
    }
    
    public mutating func EncryptData(titleKey: [uint8]) throws {
        var content = self.contentRecord
        
        // Create the IV based on the content index
        var iv: [uint8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        iv[0] = uint8(content.Index.bigEndian >> 8)
        iv[1] = uint8(content.Index.bigEndian & 0xFF)
        
        let encrpyter = try AES(key: titleKey, blockMode: CBC(iv: iv))
        let encryptedData = try encrpyter.encrypt(self.rawData.bytes)

        let hash = encryptedData.sha1()

        content.Hash = hash
        content.Size = uint64(encryptedData.count)
        self.rawData = Data(bytes: encryptedData, count: Int(content.Size.bigEndian))
    }
}
