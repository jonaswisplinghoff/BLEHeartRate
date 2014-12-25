//
//  ConnectionController.swift
//  BLEHeartRate
//
//  Created by Jonas Wisplinghoff on 25.12.14.
//  Copyright (c) 2014 Jonas Wisplinghoff. All rights reserved.
//

import Foundation
import CoreBluetooth
import HealthKit

protocol ConnectionControllerDelegate{
    func updateDevice(device:String!)
    func updateStatus(status:String!)
    func updateMeasurement(bpm: Int!)
}

class ConnectionController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let HEART_RATE_SERVICE = "180D"
    let MEASUREMENT_CHARACTERISTIC = "2A37"
    
    var centralManager :CBCentralManager?
    var peripheral: CBPeripheral?
    var healthStore: HKHealthStore?
    
    var currentBpm: Int?
    
    var delegate: ConnectionControllerDelegate?
    
    init(delegate: ConnectionControllerDelegate!){
        super.init()
        
        self.delegate = delegate
        
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
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("centralManagerDidUpdateState")
        
        switch central.state {
        case .PoweredOn:
            self.delegate?.updateStatus(".PoweredOn")
            let heartRateUUID = CBUUID(string: HEART_RATE_SERVICE)
            self.centralManager?.scanForPeripheralsWithServices([heartRateUUID], options: nil)
            
        case .PoweredOff:
            self.delegate?.updateStatus(".PoweredOff")
            
        case .Resetting:
            self.delegate?.updateStatus(".Resetting")
            
        case .Unauthorized:
            self.delegate?.updateStatus(".Unauthorized")
            
        case .Unknown:
            self.delegate?.updateStatus(".Unknown")
            
        case .Unsupported:
            self.delegate?.updateStatus(".Unsupported")
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("discovered " + peripheral.name)
        
        self.delegate?.updateDevice("\(peripheral.name)")
        
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
            
            if(characteristic.UUID == CBUUID(string: MEASUREMENT_CHARACTERISTIC)){
                self.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
                println("subscribedToMeasurement")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        let bytes = characteristic.value;
        
        var marker:UInt8 = 0;
        bytes.getBytes(&marker, length: 1)
        
        var bpm_16:UInt16 = 0
        
        if((marker & 0x01) == 0){
            bytes.getBytes(&bpm_16, range: NSMakeRange(1, 1))
            
        }else{
            bytes.getBytes(&bpm_16, range: NSMakeRange(1, 2))
        }
        
        let bpm = NSNumber(unsignedShort: bpm_16).integerValue
        
        self.delegate?.updateMeasurement(bpm)
        self.currentBpm = bpm
    }
    
    func addCurrentValueToHealthApp(){
        let objectType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate as String)
        
        let bpmUnit = HKUnit(fromString: "count/min")
        let bpmValue = NSNumber(integer: self.currentBpm!).doubleValue
        
        let quantity = HKQuantity(unit: bpmUnit, doubleValue: bpmValue)
        
        let sample = HKQuantitySample(type: objectType, quantity: quantity, startDate: NSDate(), endDate: NSDate())
        
        healthStore?.saveObject(sample, withCompletion: { (success, error) -> Void in
            if(!success){
                println("HealthKit save failed, error: \(error)")
            }
        })

    }
}