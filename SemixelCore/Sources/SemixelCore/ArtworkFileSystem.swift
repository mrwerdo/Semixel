//
//  ArtworkFileSystem.swift
//  Semixel
//
//  Created by Andrew Thompson on 13/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

public protocol FileSystemRepresentable: Encodable {
    var id: String { get }
}

public protocol FileSystemReadable: Decodable {
    var id: String { get }
}

// Stores data on disk and prevents name clashes. Objects can be associated with multiple files.
public class ArtworkFileSystem {
    private var fileSystemMetadata: [String : Metadata] = [:]
    private var documentsUrl: URL
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var metadataUrl: URL {
        return documentsUrl.appendingPathComponent("metadata.json")
    }
    
    public enum ReadingError: Error {
        case fileIdNotPresent
        case versionTwoMetadataIsNotSingular
        case missingMetadata
        case objectNotFound
    }
    
    private struct Metadata: Codable {
        var objectId: String
        var path: String
    }
    
    public init(baseDirectory: URL) {
        documentsUrl = baseDirectory
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try Data(contentsOf: metadataUrl)
            let decoder = JSONDecoder()
            fileSystemMetadata = try decoder.decode([String : Metadata].self, from: data)
        } catch {
            print("Warning: could not read file system metadata.")
        }
    }
    
    private func hardcoreWrite<Type: FileSystemRepresentable>(object: Type, using metadata: Metadata) throws {
        let data = try encoder.encode(object)
        let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
        try data.write(to: url)
        fileSystemMetadata[object.id] = metadata
        try saveMetadata()
    }
    
    public func write<Type: FileSystemRepresentable>(object: Type) throws {
        if let metadata = fileSystemMetadata[object.id] {
            try hardcoreWrite(object: object, using: metadata)
        } else {
            let path = UUID().description + ".json"
            let metadata = Metadata(objectId: object.id, path: path)
            try hardcoreWrite(object: object, using: metadata)
        }
    }
    
    private func saveMetadata() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(fileSystemMetadata)
        try data.write(to: metadataUrl)
    }
    
    private func read<Type: FileSystemReadable>(id: String, type: Type.Type) throws -> Type {
        guard let metadata = fileSystemMetadata[id] else {
            throw ReadingError.objectNotFound
        }
        
        let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    public func read<Type: FileSystemReadable>(id: String, type: Type.Type, default: @autoclosure () -> Type) -> Type {
        do {
            return try read(id: id, type: type)
        } catch {
            return `default`()
        }
    }
    
    public func delete(id: String, savingMetadata: Bool = true) throws {
        guard let metadata = fileSystemMetadata.removeValue(forKey: id) else {
            return
        }
        let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
        try FileManager.default.removeItem(at: url)
        if savingMetadata {
            try saveMetadata()
        }
    }
    
    public func reset() throws {
        let fm = FileManager.default
        let urls = try fm.contentsOfDirectory(at: documentsUrl,
                                              includingPropertiesForKeys: nil,
                                              options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
        
        ignoreErrors {
            try foreach(urls) { url in
                try fm.removeItem(at: url)
            }
        }
        
        fileSystemMetadata = [:]
    }
}
