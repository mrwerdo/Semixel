//
//  ArtworkFileSystem.swift
//  Semixel
//
//  Created by Andrew Thompson on 13/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

protocol FileSystemRepresentable: Encodable {
    associatedtype FileId: CaseIterable, RawRepresentable where FileId.RawValue == String
    var id: String { get }
    func encode(for fileId: FileId) throws -> Data
}

extension FileSystemRepresentable {
    func encodeAllFiles() throws -> [(fileName: String, data: Data)] {
        return try FileId.allCases.map({ fileId -> (fileName: String, data: Data) in
            return (fileId.rawValue, try self.encode(for: fileId))
        })
    }
}

protocol FileSystemReadable: Decodable {
    associatedtype FileId: Hashable, RawRepresentable where FileId.RawValue == String
    init(parts: [FileId: Data]) throws
    static var requiredKeys: Set<FileId> { get }
}

extension FileSystemReadable where FileId: CaseIterable {
    static var requiredKeys: Set<FileId> {
        Set(FileId.allCases)
    }
}

// Stores data on disk and prevents name clashes. Objects can be associated with multiple files.
class ArtworkFileSystem {
    private var fileSystemMetadata: [String : [Metadata]] = [:]
    private var documentsUrl: URL
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var metadataUrl: URL {
        return documentsUrl.appendingPathComponent("metadata.json")
    }
    
    enum ReadingError: Error {
        case fileIdNotPresent
        case versionTwoMetadataIsNotSingular
        case missingMetadata
    }
    
    struct Metadata: Codable {
        enum Keys: String, CodingKey {
            case objectId
            case fileId
            case path
            case version
        }
        
        var objectId: String
        var fileId: String?
        var path: String
        var version: Version
        
        init(objectId: String, path: String) {
            self.objectId = objectId
            self.fileId = nil
            self.path = path
            self.version = Version.current
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(objectId, forKey: .objectId)
            try container.encodeIfPresent(fileId, forKey: .fileId)
            try container.encode(path, forKey: .path)
            try container.encode(version, forKey: .version)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            objectId = try container.decode(String.self, forKey: .objectId)
            fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
            path = try container.decode(String.self, forKey: .path)
            version = try container.decodeIfPresent(Version.self, forKey: .version) ?? Version(0, 0, 1)
        }
    }
    
    init(baseDirectory: URL) {
        documentsUrl = baseDirectory
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try Data(contentsOf: metadataUrl)
            let decoder = JSONDecoder()
            fileSystemMetadata = try decoder.decode([String : [Metadata]].self, from: data)
        } catch {
            print("Warning: could not read file system metadata.")
        }
    }
    
    private func hardcoreWrite<Type: FileSystemRepresentable>(object: Type, using metadata: Metadata) throws {
        let data = try encoder.encode(object)
        let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
        try data.write(to: url)
        fileSystemMetadata[object.id] = [metadata]
        try saveMetadata()
    }
    
    func write<Type: FileSystemRepresentable>(object: Type) throws {
        if let files = fileSystemMetadata[object.id] {
            guard let metadata = files.first else {
                throw ReadingError.missingMetadata
            }
            
            switch metadata.version {
            case Version(0, 0, 1):
                try delete(id: object.id, savingMetadata: false)
                let newMetadata = Metadata(objectId: metadata.objectId, path: metadata.path)
                try hardcoreWrite(object: object, using: newMetadata)
            default:
                if files.count > 1 {
                    throw ReadingError.versionTwoMetadataIsNotSingular
                }
                try hardcoreWrite(object: object, using: metadata)
            }
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
    
    private func readFirstVersion<Type: FileSystemReadable>(id: String, type: Type.Type) throws -> Type {
        guard let files = fileSystemMetadata[id] else {
            throw LoadingError(description: "Object not found for id: \(id), type: \(Type.self)")
        }
        var parts: [Type.FileId : Data] = [:]
        for metadata in files {
            
            guard let fileId = metadata.fileId else {
                throw ReadingError.fileIdNotPresent
            }
            
            let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
            let data = try Data(contentsOf: url)
            if let fileId = Type.FileId(rawValue: fileId) {
                parts[fileId] = data
            } else {
                print("Warning: could not construct fileId from \(fileId) for \(Type.self)")
            }
        }
        
        if Type.requiredKeys.isStrictSuperset(of: parts.keys) {
            let missingKeys = Type.requiredKeys.subtracting(parts.keys).map { $0.rawValue }.joined(separator: ", ")
            throw LoadingError(description: "Could not initialize type \(Type.self) because the following keys were missing: \(missingKeys)")
        } else {
            return try Type(parts: parts)
        }
    }
    
    private func read<Type: FileSystemReadable>(id: String, type: Type.Type) throws -> Type {
        guard let files = fileSystemMetadata[id] else {
            throw LoadingError(description: "Object not found for id: \(id), type: \(Type.self)")
        }
        
        guard let metadata = files.first else {
            throw ReadingError.missingMetadata
        }
        
        switch metadata.version {
        case Version(0, 0, 1):
            return try readFirstVersion(id: id, type: type)
        default:
            if files.count > 1 {
                throw ReadingError.versionTwoMetadataIsNotSingular
            }
            let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        }
    }
    
    func read<Type: FileSystemReadable>(id: String, type: Type.Type, default: @autoclosure () -> Type) -> Type {
        do {
            return try read(id: id, type: type)
        } catch {
            return `default`()
        }
    }
    
    func delete(id: String, savingMetadata: Bool = true) throws {
        guard let files = fileSystemMetadata.removeValue(forKey: id) else {
            return
        }
        for file in files {
            let url = URL(fileURLWithPath: file.path, relativeTo: documentsUrl)
            try FileManager.default.removeItem(at: url)
        }
        if savingMetadata {
            try saveMetadata()
        }
    }
    
    func reset() throws {
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
