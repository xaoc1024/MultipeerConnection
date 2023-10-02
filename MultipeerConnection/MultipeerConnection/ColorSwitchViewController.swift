//
//  ViewController.swift
//  MultipeerConnection
//
//  Created by Andriy Zhuk on 2/26/18.
//  Copyright © 2018 Andriy Zhuk. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ColorSwitchViewController: UIViewController {

    private enum Constant {
        static let serviceType = "my-service"
    }

    lazy var session: MCSession = {
        print(UIDevice.current.name)
        return MCSession(peer: MCPeerID(displayName: UIDevice.current.name))
    }()

    var advertiserAssistant: MCAdvertiserAssistant?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func browseAction(_ sender: UIButton) {
        let vc = MCBrowserViewController.init(serviceType: Constant.serviceType, session: session)
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func advertiseAction(_ sender: UIButton) {
        advertiserAssistant = MCAdvertiserAssistant(serviceType: Constant.serviceType, discoveryInfo: nil, session: session)
        
        if let advertiserAssistant = advertiserAssistant {
            advertiserAssistant.delegate = self
            advertiserAssistant.start()
        }
    }
}

extension ColorSwitchViewController: MCAdvertiserAssistantDelegate {
    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        print("advertiserAssistantWillPresentInvitation")
    }

    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        print("advertiserAssistantDidDismissInvitation")
    }
}
