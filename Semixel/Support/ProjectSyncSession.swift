//
//  ProjectSyncSession.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import MultipeerConnectivity

struct SyncRequest: Codable {
    let project: String?
    let filter: String?
    let projectBaseDirectory: String
}

struct ArtworkMetadataPayload: Identifiable, Codable {
    let id: String
    let title: String
    let size: Size2D
    let pixelType: PixelType
    let path: String
    let project: String?

    init(id: String, title: String, size: Size2D, pixelType: PixelType, path: String, project: String?) {
        self.id = id
        self.title = title
        self.size = size
        self.pixelType = pixelType
        self.path = path
        self.project = project
    }
    
    init(_ m: ArtworkMetadata) {
        id = m.id
        title = m.title
        size = m.size
        pixelType = m.pixelType
        path = m.path
        project = nil
    }
}

struct SyncResponse: Codable {
    var artworkList: [ArtworkMetadataPayload]
    var pixelData: [String : [RGBA]]
}

class ProjectSyncSession: NSObject, MCSessionDelegate {
    let session: MCSession
    weak var service: ProjectSyncService?
    
    init(peerId: MCPeerID, service: ProjectSyncService) {
        self.session = MCSession(peer: peerId)
        self.service = service
        super.init()
        session.delegate = self
    }

    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .notConnected:
            print("Disconnected: \(peerID.displayName)")
            service?.disconnected(self, peer: peerID)
            service = nil
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        default:
            print("warning: unknown state encountered: \(state.rawValue)")
        }
    }
    
    func sync(_ request: SyncRequest, _ session: MCSession, _ peerID: MCPeerID) throws {
        
        guard let service = service else {
            print("warning: trying to sync but could not access ProjectSyncService")
            return
        }
        
        var metadata = service.store.artwork
         
        if let filter = request.filter {
            metadata = metadata.filter { $0.title.contains(filter) }
        }
        
        let semanticArtwork = metadata.map { service.store.model(for: $0) }
        let pixels = semanticArtwork.map { $0.image.buffer.map { $0.color } }
        let ids = semanticArtwork.map { $0.id }
        
        let pixelData = Dictionary(uniqueKeysWithValues: zip(ids, pixels))
        
        let response = SyncResponse(artworkList: metadata.map(ArtworkMetadataPayload.init),
                                    pixelData: pixelData)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        try session.send(data, toPeers: [peerID], with: .reliable)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let decoder = JSONDecoder()
            let request = try decoder.decode(SyncRequest.self, from: data)
            try sync(request, session, peerID)
        } catch {
            print("error: \(error)")
        }
    }
    
    private func warning(_ function: String = #function) {
        print("warning: \(function) was called")
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
                 at localURL: URL?,
                 withError error: Error?) {
        warning()
    }
}
