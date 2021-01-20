//
//  Browser.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import MultipeerConnectivity

class Browser: NSObject, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    let request: SyncRequest
    let runLoop: RunLoop
    let nearbyBrowser: MCNearbyServiceBrowser
    var myPeerId: MCPeerID
    var theirPeerId: MCPeerID?
    var session: MCSession?
    private var shouldKeepRunning: Bool = false
    
    func start() {
        nearbyBrowser.startBrowsingForPeers()
        shouldKeepRunning = true
        while shouldKeepRunning && runLoop.run(mode: .default, before: Date.distantFuture) {
            continue
        }
    }
    
    private func stop() {
        shouldKeepRunning = false
    }
    
    init(_ peerId: MCPeerID, _ request: SyncRequest, _ runLoop: RunLoop, service: String) {
        self.myPeerId = peerId
        self.request = request
        self.runLoop = runLoop
        self.nearbyBrowser = MCNearbyServiceBrowser(peer: peerId, serviceType: service)
        super.init()
        self.nearbyBrowser.delegate = self
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        log("could not send invitation to peer: \(peerID)", .warning, .verbose)
        nearbyBrowser.startBrowsingForPeers()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        log("could not start browsing: \(error)", .error)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        log("Peer found: \(peerID.displayName)")
        
        let session = MCSession(peer: myPeerId)
        session.delegate = self
        self.session = session
        
        theirPeerId = peerID
        nearbyBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        nearbyBrowser.stopBrowsingForPeers()
    }
    
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        switch state {
        case .connected:
            log("Connected to: \(peerID.displayName)", .output, .verbose)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(request)
                try session.send(data, toPeers: [peerID], with: .reliable)
            } catch {
                log("\(error)", .error)
            }
        case .connecting:
            log("Connecting to: \(peerID.displayName)", .output, .verbose)
        case .notConnected:
            log("Disconnected from: \(peerID.displayName)", .output, .verbose)
            nearbyBrowser.startBrowsingForPeers()
        default:
            log("unknown state encountered: \(state.rawValue)", .warning, .verbose)
            break
        }
    }
    
    func status(_ msg: String, type: MessageType, for metadata: ArtworkMetadata) {
        log(msg, type)
        log("""
                - id: \(metadata.id)
                - title: \(metadata.title)
                - project: \(metadata.project ?? "standalone")
                - size: \(metadata.size)
                - type: \(metadata.pixelType)
                - path: \(metadata.path)
                """)
    }
    
    func save(_ metadata: ArtworkMetadata, _ pixels: [RGBA]) {
        do {
            let path = "\(request.projectBaseDirectory)/\(metadata.pathWithType)"
            status("Saving \"\(metadata.title)\" at \(path)", type: .output, for: metadata)
            let encoder = JSONEncoder()
            let data = try encoder.encode(pixels)
            let url = URL(fileURLWithPath: path)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            log("\(error)", .error)
        }
    }
    
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(SyncResponse.self, from: data)
            for metadata in response.artworkList {
                guard let pixels = response.pixelData[metadata.id] else {
                    status("no pixel data was sent for artwork \"\(metadata.title)\".", type: .error, for: metadata)
                    continue
                }
                save(metadata, pixels)
            }
            
            log("Complete.", .output, .verbose)
            session.disconnect()
            stop()
        } catch {
            log("\(error)", .error)
        }
    }
    
    private func warning(_ function: String = #function) {
        log("warning: \(function) was called", .warning, .verbose)
    }
    
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        warning()
    }
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        warning()
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?, withError error: Error?) {
        warning()
    }
}

extension ArtworkMetadata {
    
    var pathWithType: String {
        return saveablePath + ".json"
    }
    
    var saveablePath: String {
        if (path == "" || path == "/") && title == "" {
            return "Untitled"
        } else {
            if title != "" {
                return title
            } else {
                return path
            }
        }
    }
}
