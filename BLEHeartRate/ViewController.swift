//
//  ViewController.swift
//  BLEHeartRate
//
//  Created by Jonas Wisplinghoff on 25.12.14.
//  Copyright (c) 2014 Jonas Wisplinghoff. All rights reserved.
//

import UIKit
import CoreBluetooth
import HealthKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    let HEART_RATE_SERVICE = "180D"
    let MEASUREMENT_CHAR = "2A37"
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    var centralManager :CBCentralManager?
    var peripheral: CBPeripheral?
    var healthStore: HKHealthStore?
    var bpm: UInt16?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        println("ViewDidLoad")
    
        if(HKHealthStore.isHealthDataAvailable()){
            self.healthStore = HKHealthStore()
            healthStore?.requestAuthorizationToShareTypes(NSSet(object: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate as String)), readTypes: nil, completion: { (success, error) -> Void in
                if(success){
                    println("Health Kit Access granted")
                }else{
                    println("Healt Kit Access Error: \(error)")
                }
            })
        }
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        println("State: \(self.centralManager!.state.rawValue)")
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("centralManagerDidUpdateState")
        
        switch central.state {
        case .PoweredOn:
            self.statusLabel.text = "Status: .PoweredOn"
            let heartRateUUID = CBUUID(string: HEART_RATE_SERVICE)
            self.centralManager?.scanForPeripheralsWithServices([heartRateUUID], options: nil)
            
        case .PoweredOff:
            self.statusLabel.text = "Status: .PoweredOff"
            
        case .Resetting:
            self.statusLabel.text = "Status: .Resetting"
            
        case .Unauthorized:
            self.statusLabel.text = "Status: .Unauthorized"
            
        case .Unknown:
            self.statusLabel.text = "Status: .Unknown"
            
        case .Unsupported:
            self.statusLabel.text = "Status: .Unsupported"
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("discovered " + peripheral.name)
        
        self.deviceLabel.text = "Device: \(peripheral.name)"
        
        self.peripheral = peripheral
        peripheral.delegate = self
        self.centralManager?.connectPeripheral(peripheral, options: nil);
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("didConnectPeripheral: \(peripheral.name)")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil);
        
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("didDiscoverServices")
        for service in peripheral.services{
            peripheral.discoverCharacteristics(nil, forService: service as CBService)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("didDiscoverCharacteristicsForService: \(service.UUID)")
        
        for char in service.characteristics{
            let characteristic = char as CBCharacteristic
            
            if(characteristic.UUID == CBUUID(string: MEASUREMENT_CHAR)){
                self.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
                println("subscribedToMeasurement")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        let bytes = characteristic.value;
        
        var marker:UInt8 = 0;
        bytes.getBytes(&marker, length: 1)
        
        var bpm:UInt16 = 0
        
        if((marker & 0x01) == 0){
            bytes.getBytes(&bpm, range: NSMakeRange(1, 1))
            
        }else{
            bytes.getBytes(&bpm, range: NSMakeRange(1, 2))
        }
        
        self.bpm = bpm;
        
        self.valueLabel.text = "Heart rate: \(bpm)"
    }
    
    @IBAction func add(sender: UIButton) {
        let objectType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate as String)
        
        let bpmUnit = HKUnit(fromString: "count/min")
        let bpmValue = NSNumber(unsignedShort: self.bpm!).doubleValue
        
        let quantity = HKQuantity(unit: bpmUnit, doubleValue: bpmValue)
        
        let sample = HKQuantitySample(type: objectType, quantity: quantity, startDate: NSDate(), endDate: NSDate())
        
        healthStore?.saveObject(sample, withCompletion: { (success, error) -> Void in
            if(!success){
                println("HealthKit save failed, error: \(error)")
            }
        })
    }
}

