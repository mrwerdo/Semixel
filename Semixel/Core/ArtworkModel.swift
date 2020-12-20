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
    @Published var artwork: [Artwork] = []
    
    private var folderMonitor: FolderMonitor
    
    init() throws {
        folderMonitor = FolderMonitor(url: try ArtworkModel.getArtworkUrl())
        
        folderMonitor.folderDidChange = { [weak self] in
            self?.handleChanges()
        }
        
        folderMonitor.startMonitoring()
        
        artwork = FileManager.default.files(in: try ArtworkModel.getArtworkUrl()).map {
            Artwork(name: $0.lastPathComponent, url: $0)
        }
    }
    
    private func handleChanges() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderMonitor.url, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            DispatchQueue.main.sync {
                print("Updating menu.")
                artwork = files.map { Artwork(name: $0.lastPathComponent, url: $0) }
            }
        } catch {
            print(error)
        }
    }
    
    private func getFilename() -> String {
        let filenames = Set(artwork.map { $0.name })
        if !filenames.contains("Untitled.png") {
            return "Untitled.png"
        } else {
            var i = 0
            while filenames.contains("Untitled \(i).png") {
                i += 1
            }
            return "Untitled \(i).png"
        }
    }
    
    func remove(at offsets: IndexSet) {
        
        for offset in offsets {
            let a = artwork[offset]
            do {
                try FileManager.default.removeItem(at: a.url)
            } catch {
                print(error)
            }
        }
        
        artwork.remove(atOffsets: offsets)
    }
    
    func createArtwork() throws -> Artwork {
        let filename = getFilename()
        let image = PixelImage<RGBA>(width: 32, height: 32)
        let url = try ArtworkModel.getArtworkUrl().appendingPathComponent(filename)
        
        try image.write(to: url)
        
        return Artwork(name: url.lastPathComponent, url: url)        
    }
}

extension ArtworkModel {
    
    static func load() throws -> [Artwork] {
        return FileManager.default.files(in: try getArtworkUrl()).map { url in
            print(url)
            return Artwork(name: url.lastPathComponent, url: url)
        }
    }
    
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
