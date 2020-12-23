//
//  FolderMonitor.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import Foundation
import Combine

class FolderMonitor: ObservableObject {
    /// URL for the directory being monitored.
    let url: Foundation.URL
    
    @Published private(set) var files: [URL] = []
    
    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    
    init(url: Foundation.URL) {
        self.url = url
    }
    
    struct WatchingError: Error {
        var description: String
    }
    
    /// Listen for changes to the directory (if we are not already).
    func startMonitoring() throws {
        files = try url.scan()
        
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        
        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor,
                                                                        eventMask: .write,
                                                                        queue: folderMonitorQueue)
        
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange()
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
    
    private func folderDidChange() {
        do {
            files = try url.scan()
        } catch {
            print("An error occurred while monitoring a folder: \(error)")
        }
    }
}

extension URL {
    fileprivate func scan() throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: self,
                                 includingPropertiesForKeys: nil,
                                 options: [.skipsSubdirectoryDescendants])
    }
}
