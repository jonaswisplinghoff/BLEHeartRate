//
//  ViewController.swift
//  BLEHeartRate
//
//  Created by Jonas Wisplinghoff on 25.12.14.
//  Copyright (c) 2014 Jonas Wisplinghoff. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ConnectionControllerDelegate {
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var continuouslySwitch: UISwitch!
    @IBOutlet weak var addToHealthAppButton: UIButton!

    var con: ConnectionController?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        println("ViewDidLoad")
    
        self.con = ConnectionController(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        println("Memory warning!")
    }
    
    @IBAction func add(sender: UIButton) {
        con?.addCurrentValueToHealthApp()
    }
    
    @IBAction func sendContinuouslySwitchChanged(sender: UISwitch) {
        self.con?.setSaveContinuously(sender.on)
        self.addToHealthAppButton.enabled = !sender.enabled
    }
    
    func updateDevice(device: String!) {
        self.deviceLabel.text = "Device: \(device)"
    }
    
    func updateStatus(status: String!) {
        self.statusLabel.text = "Bluetooth Status: \(status)"
    }
    
    func updateMeasurement(bpm: Int!) {
        self.valueLabel.text = "Heart rate: \(bpm)"
        if !self.continuouslySwitch.on{
            self.addToHealthAppButton.enabled = true
        }
    }
}

