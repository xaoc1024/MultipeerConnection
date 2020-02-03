//
//  TimeSynchronizer.swift
//  MultipeerConnection
//
//  Created by Andriy Zhuk on 2/27/18.
//  Copyright © 2018 Andriy Zhuk. All rights reserved.
//

import Foundation

class PeerController: Equatable, Hashable {

    static let requestsCount = 50

    enum SynchroniztionState {
        case none
        case isSynchronizing
        case isSynchronized
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(peerID.hashValue)
    }

    var state: SynchroniztionState = .none

    var isSynchronizing: Bool = false

    var reqeuestsCount: Int = 0

    static func ==(lhs: PeerController, rhs: PeerController) -> Bool {
        return lhs.peerID == rhs.peerID
    }

    let peerID: String
    let transmitter: JsonTransmitter

    var timeDifference = [TimeInterval]()

    var previouslySentTimestamp: TimeInterval?

    init(peerID: String, transmitter: JsonTransmitter) {
        self.peerID = peerID
        self.transmitter = transmitter
    }

    func startSynchronization() {
        state = .isSynchronizing
        sendCurrentTimestamp()
    }

    func didReceiveJsonData(_ json: [String: Any]) {
        NSLog("DEBUG - didReceiveJsonData. Current peerID = \(self.peerID)")
        switch state {
        case .isSynchronizing:
            handleSynchronizingResponse(json)

        case .isSynchronized, .none:
            handleSynchronizedResponse(json)
        }
    }

    private func handleSynchronizingResponse(_ json: [String: Any]) {
        NSLog("DEBUG - handleSynchronizingResponse. Current peerID = \(self.peerID)")
        guard let peersTimestamp = json["currentTime"] as? TimeInterval, let previouslySentTimestamp = previouslySentTimestamp else {
            return
        }

        let currentTimestamp = Date().timeIntervalSince1970

        let delay = (currentTimestamp - previouslySentTimestamp) / 2.0

        let difference = (peersTimestamp - previouslySentTimestamp) - delay

        timeDifference.append(difference)

        NSLog("DEBUG - handleSynchronizingResponse. Current peerID = \(self.peerID), difference == \(difference)")

        if reqeuestsCount < PeerController.requestsCount {
            sendCurrentTimestamp(currentTimestamp: currentTimestamp)
        } else {
            self.state = .none
            print("\(self.timeDifference)")
        }
    }

    private func handleSynchronizedResponse(_ json: [String: Any]) {
        NSLog("DEBUG - handleSynchronizedResponse. Current peerID = \(self.peerID)")
        sendCurrentTimestamp()
    }

    private func sendCurrentTimestamp(currentTimestamp: TimeInterval? = nil) {
        let timestamp: TimeInterval

        if let currentTimestamp = currentTimestamp {
            timestamp = currentTimestamp
        } else {
            timestamp = Date().timeIntervalSince1970
        }

        self.previouslySentTimestamp = timestamp
        let json = ["currentTime": timestamp]
        transmitter.sendJson(json, to: [peerID])

        reqeuestsCount += 1
    }
}

protocol TimeSynchronizerDelegate: class {
    func didChangePeers(_ timeSynchronizer: TimeSynchronizer, peersCount: Int)
}

class TimeSynchronizer: NSObject {
    let transmitter: JsonTransmitter

    weak var delegate:TimeSynchronizerDelegate?

    private var peersMap = [String: PeerController]() {
        didSet {
            NSLog("Perrs Map changed, \(peersMap)")
        }
    }

    private var connectedDevicesIDs: [String] = [] {
        didSet {
            if connectedDevicesIDs != oldValue {
                let count = connectedDevicesIDs.count

                DispatchQueue.main.async {
                    self.delegate?.didChangePeers(self, peersCount: count)
                }

                var newPeersMap = [String: PeerController]()

                for deviceID in connectedDevicesIDs {
                    if let wraper = peersMap[deviceID] {
                        newPeersMap[deviceID] = wraper
                    } else {
                        newPeersMap[deviceID] = PeerController(peerID: deviceID, transmitter: self.transmitter)
                    }
                }

                self.peersMap = newPeersMap
            }
        }
    }

    init(transmitter: JsonTransmitter) {
        self.transmitter = transmitter

        super.init()

        self.transmitter.delegate = self
        self.transmitter.turnOn()
    }

    func synchronize() {
        for (_, pair) in peersMap.enumerated() {
            pair.value.startSynchronization()
        }
    }

    deinit {
        self.transmitter.turnOff()
    }
}

extension TimeSynchronizer: JsonTransmitterDelegate {
    func connectedDevicesChanged(transmitter: JsonTransmitter, connectedDevices: [String]) {
        self.connectedDevicesIDs = connectedDevices
    }

    func transmitterDidReceiveData(transmitter: JsonTransmitter, jsonData: [String: Any], peerID: String) {
        NSLog("DEBUG - TimeSynchronizer - transmitterDidReceiveData, peerID == \(peerID)")

        guard let peer = peersMap[peerID] else {
            return
        }

        peer.didReceiveJsonData(jsonData)
    }
}
