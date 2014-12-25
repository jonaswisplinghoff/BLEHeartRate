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
    }
    
    func updateDevice(device: String!) {
        self.deviceLabel.text = "Device: \(device)"
    }
    
    func updateMeasurement(bpm: Int!) {
        self.valueLabel.text = "Heart rate: \(bpm)"
    }
    
    func updateStatus(status: String!) {
        self.statusLabel.text = "Status: \(status)"
    }
    
    @IBAction func add(sender: UIButton) {
        con?.addCurrentValueToHealthApp()
    }
}

