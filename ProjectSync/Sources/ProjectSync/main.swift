//
//  main.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Cocoa

currentVerbosity = .normal

let request = SyncRequest(project: nil,
                          filter: nil,
                          projectBaseDirectory: FileManager.default.currentDirectoryPath)

guard let displayName = Host.current().localizedName else {
    log("Unable to get current host name.", .warning, .normal)
    exit(EXIT_FAILURE)
}

let peerId = MCPeerID(displayName: displayName)
log("Using peer: \(peerId.displayName)", .output, .verbose)

let browser = Browser(peerId, request, RunLoop.current, service: "semixel-prjsync")
browser.start()
