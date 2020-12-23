//
//  ArtworkModel.swift
//  Semixel
//
//  Created by Andrew Thompson on 10/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

final class ArtworkModel: ObservableObject {
    @Published var artwork: [SemanticArtwork] = []
    
    private var folderMonitor: FolderMonitor
    
    let artworkDirectory: URL
    
    init(_ artworkDirectory: URL) throws {
        self.artworkDirectory = artworkDirectory
        folderMonitor = FolderMonitor(url: artworkDirectory)
        
        folderMonitor.$files.map { (files: [URL]) in
            files.compactMap { (file: URL) in
                do {
                    return try self.convert(url: file)
                } catch {
                    print(error)
                    return nil
                }
            }
        }
        .receive(on: RunLoop.main)
        .assign(to: &$artwork)
        
        try folderMonitor.startMonitoring()
    }
    
    private func convert(url: URL) throws -> SemanticArtwork? {
        if url.pathExtension == "png" {
            let newUrl = url.deletingPathExtension().appendingPathExtension("json")
            
            // convert file...
            guard let image = UIImage(contentsOfFile: url.path) else {
                return nil
            }
            
            var pixelImage = PixelImage<SemanticPixel<RGBA>>(width: image.width, height: image.height)
            image.enumeratePixels { (x, y, color) in
                pixelImage.buffer[y * pixelImage.size.width + x] = SemanticPixel(id: 0, color: color)
            }
            
            let semanticArtwork = SemanticArtwork(url: newUrl, image: pixelImage)
            
            try semanticArtwork.write(to: newUrl)
            try FileManager.default.removeItem(at: url)
            
            semanticArtwork.url = newUrl
            
            return semanticArtwork
        } else {
            let esa: EncodedSemanticArtwork = try load(url: url)
            return try SemanticArtwork(url: url, esa)
        }
    }
    
    private func getFilename() -> String {
        let filenames = Set(artwork.map { $0.url.lastPathComponent })
        if !filenames.contains("Untitled.json") {
            return "Untitled.json"
        } else {
            var i = 0
            while filenames.contains("Untitled \(i).json") {
                i += 1
            }
            return "Untitled \(i).json"
        }
    }
    
    func remove(at offsets: IndexSet) {
        
        for offset in offsets {
            let a = artwork[offset]
            do {
                print("Removing: \(a.url.lastPathComponent)")
                try FileManager.default.removeItem(at: a.url)
            } catch {
                print(error)
            }
        }
        
        artwork.remove(atOffsets: offsets)
    }
    
    func createArtwork() throws -> SemanticArtwork {
        let filename = getFilename()
        let image = PixelImage<SemanticPixel<RGBA>>(width: 32, height: 32)
        let url = artworkDirectory.appendingPathComponent(filename)
        var tree = SemanticIdentifier(id: -1, name: "Root")
        tree.children.append(SemanticIdentifier(id: 0, name: "Default"))
        
        let artwork = SemanticArtwork(url: url, image: image, root: tree, colorPalettes: [0: [.white]])
        try artwork.write(to: url)
        return artwork
    }
}

extension ArtworkModel {
    
    private struct LoadingError: Error, CustomStringConvertible {
        var description: String
    }
    
    static func getArtworkUrl() throws -> URL {
        let fm = FileManager.default
        let urls = fm.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                           in: .userDomainMask)
        guard let documentsUrl = urls.first else {
            throw LoadingError(description: "Colud not find documents directory.")
        }
        let url = documentsUrl.appendingPathComponent("Artwork", isDirectory: true)
        return url
    }
    
    static func initializeDirectory() throws {
        let fm = FileManager.default
        let artworkUrl = try ArtworkModel.getArtworkUrl()
        
        do {
            try fm.createDirectory(at: artworkUrl, withIntermediateDirectories: false, attributes: nil)
        } catch let error as CocoaError {
            if error.code == .fileWriteFileExists {
//                return
            } else {
                throw error
            }
        }
        
        guard let defaultArtworkUrls = Bundle.main.urls(forResourcesWithExtension: "png",
                                          subdirectory: "Default Artwork") else {
            throw LoadingError(description: "Failed to find urls for Default Artwork subdirectory.")
        }
        
        
        for url in defaultArtworkUrls {
            let filename = url.lastPathComponent
            let destination = artworkUrl.appendingPathComponent(filename, isDirectory: false)
            // todo: make copy atomic
            do {
                try fm.removeItem(at: destination)
            } catch { }
            try fm.copyItem(at: url, to: destination)
        }
    }
}
