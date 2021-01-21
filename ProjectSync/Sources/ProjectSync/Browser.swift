//
//  Browser.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import MultipeerConnectivity

class Browser: NSObject, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    let serviceType: String = "semixel-prjsync"
    let logger: Logger
    let request: SyncRequest
    let runLoop: RunLoop
    let nearbyBrowser: MCNearbyServiceBrowser
    var myPeerId: MCPeerID
    var theirPeerId: MCPeerID?
    var session: MCSession?
    private var shouldKeepRunning: Bool = false
        
    init(_ peerId: MCPeerID, _ request: SyncRequest, _ runLoop: RunLoop, logger: Logger) {
        self.myPeerId = peerId
        self.request = request
        self.runLoop = runLoop
        self.nearbyBrowser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        self.logger = logger
        super.init()
        self.nearbyBrowser.delegate = self
    }
    
    func start() {
        logger.verbose("Using peer: \(myPeerId.displayName)")
        nearbyBrowser.startBrowsingForPeers()
        shouldKeepRunning = true
        while shouldKeepRunning && runLoop.run(mode: .default, before: Date.distantFuture) {
            continue
        }
    }
    
    private func stop() {
        shouldKeepRunning = false
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        logger.warning("could not send invitation to peer: \(peerID)", isVerbose: true)
        nearbyBrowser.startBrowsingForPeers()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        logger.error("could not start browsing: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        logger.log("Peer found: \(peerID.displayName)")
        
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
            logger.verbose("Connected to: \(peerID.displayName)")
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(request)
                try session.send(data, toPeers: [peerID], with: .reliable)
            } catch {
                logger.error("\(error)")
            }
        case .connecting:
            logger.verbose("Connecting to: \(peerID.displayName)")
        case .notConnected:
            logger.verbose("Disconnected from: \(peerID.displayName)")
            nearbyBrowser.startBrowsingForPeers()
        default:
            logger.warning("unknown state encountered: \(state.rawValue)", isVerbose: true)
            break
        }
    }
    
    func save(_ metadata: ArtworkMetadata, _ pixels: [RGBA]) {
        do {
            let path = "\(request.projectBaseDirectory)/\(metadata.pathWithType)"
            logger.log("Saving \"\(metadata.title)\" at \(path)")
            logger.log(metadata.description)
            let encoder = JSONEncoder()
            let data = try encoder.encode(pixels)
            let url = URL(fileURLWithPath: path)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            logger.error("\(error)")
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
                    logger.error("no pixel data was sent for artwork \"\(metadata.title)\".")
                    logger.log(metadata.description)
                    continue
                }
                save(metadata, pixels)
            }
            
            logger.verbose("Complete.")
            session.disconnect()
            stop()
        } catch {
            logger.error("\(error)")
        }
    }
    
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        logger.warning("warning: \(#function) was called", isVerbose: true)
    }
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        logger.warning("warning: \(#function) was called", isVerbose: true)
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?, withError error: Error?) {
        logger.warning("warning: \(#function) was called", isVerbose: true)
    }
}

extension ArtworkMetadata: CustomStringConvertible {
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
    
    var description: String {
        return """
            - id: \(id)
            - title: \(title)
            - project: \(project ?? "standalone")
            - size: \(size)
            - type: \(pixelType)
            - path: \(path)
            """
    }
}
