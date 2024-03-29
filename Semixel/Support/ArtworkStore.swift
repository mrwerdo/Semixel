//
//  ArtworkStore.swift
//  Semixel
//
//  Created by Andrew Thompson on 12/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import SwiftUI
import Geometry
import SemixelCore

enum PixelType: String, Codable {
    case semantic
}

class ArtworkMetadata: Identifiable, Codable, ObservableObject {
    let id: String
    var _title: String?
    var size: Size2D
    var pixelType: PixelType
    var path: String
    
    init(id: String, title: String? = nil, size: Size2D, pixelType: PixelType, path: String) {
        self.id = id
        self._title = title
        self.size = size
        self.pixelType = pixelType
        self.path = path
    }
    
    var title: String {
        get {
            return _title ?? "Untitled"
        }
        set {
            _title = newValue != "" ? newValue : ""
            objectWillChange.send()
        }
    }
}

extension ArtworkMetadata {
    private var type: String {
        switch pixelType {
        case .semantic:
            return "semantic"
        }
    }
    
    var subtitle: String {
        return "\(type) - \(size.width)x\(size.height)"
    }
}

class ProjectMetadata: Identifiable, Codable, ObservableObject {
    var title: String
    var id: String
    var artworkIds: [String]
}

class ArtworkStore: ObservableObject {
    
    struct Metadata: Codable, FileSystemReadable, FileSystemRepresentable {
        
        var projects: [ProjectMetadata]
        var standaloneArtworks: [ArtworkMetadata]
        var visibleDefaultArtwork: Set<String>
        var toolIconOverrides: [ToolType : String] = [:]
        
        enum FileId: String, CaseIterable {
            case metadata
        }
        
        var id: String {
            "metadata"
        }
        
        init(parts: [FileId : Data]) throws {
            let decoder = JSONDecoder()
            self = try decoder.decode(Metadata.self, from: parts[.metadata]!)
        }
        
        init() {
            projects = []
            standaloneArtworks = []
            visibleDefaultArtwork = Set()
        }
        
        func encode(for fileId: FileId) throws -> Data {
            let encoder = JSONEncoder()
            switch fileId {
            case .metadata:
                return try encoder.encode(self)
            }
        }
    }
    
    @Published var artwork: [ArtworkMetadata] = []
    
    private var metadata: Metadata
    private var fs: ArtworkFileSystem
    private var semanticArtworkCache: [String : SemanticArtwork] = [:]
    
    init(fileSystem fs: ArtworkFileSystem) throws {
        metadata = fs.read(id: "metadata", type: Metadata.self, default: Metadata())
        self.fs = fs
        
        artwork = metadata.standaloneArtworks
    }
    
    func save(_ artwork: ArtworkMetadata) throws {
        let ref = model(for: artwork)
        try fs.write(object: ref)
    }
    
    func saveMetadata() throws {
        try fs.write(object: metadata)
    }
    
    func create(_ type: PixelType, size: Size2D) throws -> ArtworkMetadata {
        let id = UUID().description
        let metadata = ArtworkMetadata(id: id, size: size, pixelType: type, path: "/")

        switch type {
        case .semantic:
            semanticArtworkCache[metadata.id] = SemanticArtwork(createUsing: metadata)
        }
        
        self.metadata.standaloneArtworks.append(metadata)
        
        do {
            try saveMetadata()
        } catch {
            print("Warning: could not save metadata.")
        }
        
        artwork.append(metadata)
        
        return metadata
    }
    
    func remove(_ artwork: ArtworkMetadata) throws {
        semanticArtworkCache[artwork.id] = nil
        try fs.delete(id: artwork.id)
        metadata.standaloneArtworks.removeAll { $0.id == artwork.id }
        try saveMetadata()
    }
    
    // Returns the in memory representation of `artwork`, loading it from disk if needed.
    func model(for artwork: ArtworkMetadata) -> SemanticArtwork {
        if let obj = semanticArtworkCache[artwork.id] {
            return obj
        } else {
            let loadedArtwork = fs.read(id: artwork.id,
                                        type: SemanticArtwork.self,
                                        default: SemanticArtwork(createUsing: artwork))
            semanticArtworkCache[artwork.id] = loadedArtwork
            return loadedArtwork
        }
    }
    
    func view(for artwork: ArtworkMetadata) -> some View {
        let destination = PixelView()
            .environmentObject(model(for: artwork))
            .environmentObject(artwork)
        return destination
    }
    
    func preview(for metadata: ArtworkMetadata, size n: CGFloat = 64) -> some View {
        let artwork = model(for: metadata)
        let length = n / max(CGFloat(metadata.size.width), CGFloat(metadata.size.height))
        return PixelBufferView(pixelSize: CGSize(square: length), image: artwork.bitmapImage, centered: true)
            .frame(width: n, height: n, alignment: .center)
    }
    
    func icon<T: View>(for tool: ToolType, ifNotFound `default`: T) -> AnyView {
        if let id = metadata.toolIconOverrides[tool] {
            if let m = artwork.first(where: { $0.id == id }) {
                return AnyView(preview(for: m, size: 32))
            }
        }
        return AnyView(`default`)
    }
    
    func toolOverride(for metadata: ArtworkMetadata) -> ToolType? {
        return self.metadata.toolIconOverrides.first(where: { $0.value == metadata.id })?.key
    }
    
    func setToolOverride(_ tool: ToolType?, for metadata: ArtworkMetadata) {
        if let oldValue = toolOverride(for: metadata) {
            self.metadata.toolIconOverrides.removeValue(forKey: oldValue)
        }
        if let tool = tool {
            self.metadata.toolIconOverrides[tool] = metadata.id
        }
    }
}

extension SemanticArtwork: FileSystemRepresentable, FileSystemReadable {
    enum Keys: String, CaseIterable, CodingKey {
        case pixels
        case semantics
        case colorPalettes
        case identifierTree
        case size
        case id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(image.buffer.map { $0.color }, forKey: .pixels)
        try container.encode(image.buffer.map { $0.semantic }, forKey: .semantics)
        try container.encode(colorPalette.colors, forKey: .colorPalettes)
        try container.encode(root, forKey: .identifierTree)
        try container.encode(image.size, forKey: .size)
        try container.encode(id, forKey: .id)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let pixels = try container.decode([Int].self, forKey: .pixels)
        let semantics = try container.decode([Int].self, forKey: .semantics)
        let colors = try container.decode([IdentifiableColor].self, forKey: .colorPalettes)
        let root = try container.decode(SemanticIdentifier.self, forKey: .identifierTree)
        let size = try container.decode(Size2D.self, forKey: .size)
        let id = try container.decode(String.self, forKey: .id)
        
        let buffer = zip(semantics, pixels).map { SemanticPixel(semantic: $0.0, color: $0.1) }
        let image = PixelImage<SemanticPixel>(size: size, buffer: buffer)
        self.init(id: id, title: "", image: image, root: root, colorPalette: ColorPalette(colors))
    }
}

extension ArtworkStore {
    func remove(at offsets: IndexSet) throws {
        var errors = [Error]()
        var successfulOffsets = IndexSet()
        
        for offset in offsets {
            do {
                try remove(artwork[offset])
                successfulOffsets.insert(offset)
            } catch {
                errors.append(error)
            }
        }
        
        artwork.remove(atOffsets: successfulOffsets)
        
        if errors.count > 0 {
            struct RemovalError: Error {
                var errors: [Error]
            }
            throw RemovalError(errors: errors)
        }
    }
    
    static var defaultArtworkUrls: [URL]? {
        Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Default Artwork")
    }
    
    func addDefaultArtwork(force: Bool = false) throws {
        let userDefaults = UserDefaults()
        guard !userDefaults.bool(forKey: "Semixel_DefaultArtwork_Added") || force else {
            return
        }
        userDefaults.set(true, forKey: "Semixel_DefaultArtwork_Added")
        
        guard let artworkUrls = ArtworkStore.defaultArtworkUrls else {
            throw LoadingError(description: "Failed to find default artwork subdirectory.")
        }
        
        for url in artworkUrls {
            guard let image = UIImage(contentsOfFile: url.path) else {
                continue
            }
            
            let size = Size2D(width: image.width, height: image.height)
            let metadata = try create(.semantic, size: size)
            metadata.title = url.deletingPathExtension().lastPathComponent
            let artwork = model(for: metadata)
            artwork.colorPalette.colors = []
            image.enumeratePixels { (x, y, pixel) in
                if let index = artwork.colorPalette.colors.first(where: { item in item.color == pixel }) {
                    artwork.image[x, y] = SemanticPixel(semantic: 0, color: index.id)
                } else {
                    let index = artwork.colorPalette.add(pixel)
                    artwork.image[x, y] = SemanticPixel(semantic: 0, color: index)
                }
            }
            try save(metadata)
        }
    }
}

extension ArtworkStore {
    func reset() throws {
        try fs.reset()
        UserDefaults().removeObject(forKey: "Semixel_DefaultArtwork_Added")
        artwork = []
        metadata = Metadata()
    }
}
