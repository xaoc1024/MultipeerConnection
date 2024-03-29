//
//  NearbyServiceJsonTransmitter.swift
//  MultipeerConnection
//
//  Created by Andriy Zhuk on 2/26/18.
//  Copyright © 2018 Andriy Zhuk. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol JsonTransmitter: class {
    var delegate: JsonTransmitterDelegate? { get set }

    func turnOn()
    func turnOff()
    func sendJson(_ json: [String: Any], to peers: [String])
}

protocol JsonTransmitterDelegate: class {
    func connectedDevicesChanged(transmitter: JsonTransmitter, connectedDevices: [String])
    func transmitterDidReceiveData(transmitter: JsonTransmitter, jsonData: [String: Any], peerID: String)
}


class NearbyServiceJsonTransmitter: NSObject, JsonTransmitter {

    weak var delegate : JsonTransmitterDelegate?

    private let serviceType = "synchro"

    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)

    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser

    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }

    deinit {
        self.turnOff()
    }

    func sendJson(_ json: [String : Any], to peers: [String]) {
//        let peerIds = peers.compactMap { MCPeerID(displayName: $0) }

        guard let firstPeer = session.connectedPeers.first else {
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            try self.session.send(data, toPeers: [firstPeer], with: .reliable)
        }
        catch let error {
            NSLog("%@", "Error for sending: \(error)")
        }
//
//        if !session.connectedPeers.isEmpty {
//            do {
//                let data = try JSONSerialization.data(withJSONObject: json, options: [])
//                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
//            }
//            catch let error {
//                NSLog("%@", "Error for sending: \(error)")
//            }
//        }
    }

    func turnOn() {
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }

    func turnOff() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}


extension NearbyServiceJsonTransmitter : MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }

}

extension NearbyServiceJsonTransmitter : MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }

}

extension NearbyServiceJsonTransmitter : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.delegate?.connectedDevicesChanged(transmitter: self, connectedDevices: session.connectedPeers.map{ $0.displayName })
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let someJson = try? JSONSerialization.jsonObject(with: data, options: [])
        guard let json = someJson as? [String: Any] else {
            return
        }

        self.delegate?.transmitterDidReceiveData(transmitter: self, jsonData: json, peerID: peerID.displayName)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }

}

