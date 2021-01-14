//
//  ArtworkFileSystem.swift
//  Semixel
//
//  Created by Andrew Thompson on 13/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

protocol FileSystemRepresentable {
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

protocol FileSystemReadable {
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
    
    private var metadataUrl: URL {
        return documentsUrl.appendingPathComponent("metadata.json")
    }
    
    struct Metadata: Codable {
        var objectId: String
        var fileId: String
        var path: String
    }
    
    init(baseDirectory: URL) {
        documentsUrl = baseDirectory
        do {
            let data = try Data(contentsOf: metadataUrl)
            let decoder = JSONDecoder()
            fileSystemMetadata = try decoder.decode([String : [Metadata]].self, from: data)
        } catch {
            print("Warning: could not read file system metadata.")
        }
    }
    
    func write<Type: FileSystemRepresentable>(object: Type) throws {
        let files = try object.encodeAllFiles()
        var metadatas = [Metadata]()
        for (name, data) in files {
            let metadata = Metadata(objectId: object.id, fileId: name, path: UUID().description)
            metadatas.append(metadata)
            let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
            try data.write(to: url)
        }
        fileSystemMetadata[object.id] = metadatas
        try saveMetadata()
    }
    
    private func saveMetadata() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(fileSystemMetadata)
        try data.write(to: metadataUrl)
    }
    
    func read<Type: FileSystemReadable>(id: String, type: Type.Type) throws -> Type {
        guard let files = fileSystemMetadata[id] else {
            throw LoadingError(description: "Object not found for id: \(id), type: \(Type.self)")
        }
        var parts: [Type.FileId : Data] = [:]
        for metadata in files {
            let url = URL(fileURLWithPath: metadata.path, relativeTo: documentsUrl)
            let data = try Data(contentsOf: url)
            if let fileId = Type.FileId(rawValue: metadata.fileId) {
                parts[fileId] = data
            } else {
                print("Warning: could not construct fileId from \(metadata.fileId) for \(Type.self)")
            }
        }
        
        if Type.requiredKeys.isStrictSuperset(of: parts.keys) {
            let missingKeys = Type.requiredKeys.subtracting(parts.keys).map { $0.rawValue }.joined(separator: ", ")
            throw LoadingError(description: "Could not initialize type \(Type.self) because the following keys were missing: \(missingKeys)")
        } else {
            return try Type(parts: parts)
        }
    }
    
    func read<Type: FileSystemReadable>(id: String, type: Type.Type, default: @autoclosure () -> Type) -> Type {
        do {
            return try read(id: id, type: type)
        } catch {
            return `default`()
        }
    }
    
    func delete(id: String) throws {
        guard let files = fileSystemMetadata.removeValue(forKey: id) else {
            return
        }
        for file in files {
            let url = URL(fileURLWithPath: file.path, relativeTo: documentsUrl)
            try FileManager.default.removeItem(at: url)
        }
        try saveMetadata()
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
