//
//  ProjectSyncService.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class ProjectSyncService: NSObject, MCNearbyServiceAdvertiserDelegate {
    let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    let serviceType: String = "semixel-prjsync"
    let advertiser: MCNearbyServiceAdvertiser
    let store: ArtworkStore
    
    var sessions: [MCPeerID : ProjectSyncSession] = [:]
        
    init(store: ArtworkStore) {
        self.store = store
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                                               discoveryInfo: nil,
                                               serviceType: serviceType)
        super.init()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("did recieve invitation from peer: \(peerID.displayName)")
        let syncSession = ProjectSyncSession(peerId: myPeerId, service: self)
        sessions[peerID] = syncSession
        invitationHandler(true, syncSession.session)
        advertiser.stopAdvertisingPeer()
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("advertiser error: \(error)")
    }
    
    func disconnected(_ session: ProjectSyncSession, peer peerID: MCPeerID) {
        let delegate = sessions.removeValue(forKey: peerID)
        delegate?.session.disconnect()
        advertiser.startAdvertisingPeer()
    }
}
