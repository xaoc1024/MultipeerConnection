//
//  ViewController.swift
//  MultipeerConnection
//
//  Created by Andriy Zhuk on 2/26/18.
//  Copyright © 2018 Andriy Zhuk. All rights reserved.
//

import UIKit

class ColorSwitchViewController: UIViewController {

    @IBOutlet private var connectionsLabel: UILabel!
    @IBOutlet private var startButton: UIButton!
    
//    private lazy var synchronizer = TimeSynchronizer(transmitter: NearbyServiceJsonTransmitter())

    lazy var trasmitter = NearbyServiceJsonTransmitter()

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.synchronizer.delegate = self
        self.startButton.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        trasmitter.turnOn()
    }

    @IBAction func redTapped(_ sender: UIButton) {
        self.change(color: .red)
    }

    @IBAction func yellowTapped(_ sender: UIButton) {
        self.change(color: .yellow)
    }

    @IBAction func continiousStartAction(_ sender: UIButton) {
//        synchronizer.synchronize()
    }

    private func change(color : UIColor) {
        UIView.animate(withDuration: 0.0) {
            self.view.backgroundColor = color
        }
    }
}

extension ColorSwitchViewController: TimeSynchronizerDelegate {
    func didChangePeers(_ timeSynchronizer: TimeSynchronizer, peersCount: Int) {
        self.startButton.isEnabled = (peersCount > 0)
    }
}

