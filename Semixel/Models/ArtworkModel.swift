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

class Artwork: Identifiable, ObservableObject {
    var id: URL {
        return url
    }
    
    var name: String
    var url: URL
    @Published var pixelImage: PixelImage<RGBA>

    private var uiImage: UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
    
    var size: Size2D {
        let w = Int(uiImage?.size.width.rounded() ?? 0)
        let h = Int(uiImage?.size.height.rounded() ?? 0)
        return Size2D(width: w, height: h)
    }
    
    var image: Image {
        if let img = pixelImage.convertToCGImage() {
            return Image(decorative: img, scale: 1.0)
        } else {
            return Image(systemName: "questionmark")
        }
    }
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
        let image = UIImage(contentsOfFile: url.path)!
        self.pixelImage = PixelImage<RGBA>(width: image.width, height: image.height)
        image.enumeratePixels { (x, y, color) in
            self.pixelImage.buffer[y * pixelImage.size.width + x] = color
        }
    }
    
}

class FolderMonitor {
    // MARK: Properties
    
    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// URL for the directory being monitored.
    let url: Foundation.URL
    
    var folderDidChange: (() -> Void)?
    // MARK: Initializers
    init(url: Foundation.URL) {
        self.url = url
    }
    // MARK: Monitoring
    /// Listen for changes to the directory (if we are not already).
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
            
        }
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write, queue: folderMonitorQueue)
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
    /// Stop listening for changes to the directory, if the source has been created.
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}


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

extension FileManager {
    func files(in directory: URL) -> [URL] {
        let fm = FileManager()
         
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
        guard let directoryEnumerator = fm.enumerator(at: directory, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles) else {
            return []
        }
         
        var fileURLs: [URL] = []
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let isDirectory = resourceValues.isDirectory,
                let name = resourceValues.name
                else {
                    continue
            }
            
            if isDirectory {
                if name == "_extras" {
                    directoryEnumerator.skipDescendants()
                }
            } else {
                fileURLs.append(fileURL)
            }
        }
        return fileURLs
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
