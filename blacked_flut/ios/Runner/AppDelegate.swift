import UIKit
import Flutter
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var peripheralManager: CBPeripheralManager!
  private var txCharacteristic: CBCharacteristic!
  private var service: CBService!
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let blePeripheralChannel = FlutterMethodChannel(name: "com.example.blePeripheral", binaryMessenger: controller.binaryMessenger)
    
    blePeripheralChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "startPeripheral" {
        self?.startPeripheral()
        result("Peripheral Started")
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func startPeripheral() {
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
}

extension AppDelegate: CBPeripheralManagerDelegate {
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state == .poweredOn {
      let serviceUUID = CBUUID(string: "bf27730d-860a-4e09-889c-2d8b6a9e0fe8")
      let characteristicUUID = CBUUID(string: "7f27fbcf-2862-4b1e-95d5-2b5850836cbe")
      
      let characteristic = CBMutableCharacteristic(
        type: characteristicUUID,
        properties: [.read, .write],
        value: "Initial Data".data(using: .utf8),
        permissions: [.readable, .writeable]
      )

      let service = CBMutableService(type: serviceUUID, primary: true)
      service.characteristics = [characteristic]
      
      peripheralManager.add(service)
      peripheralManager.startAdvertising([
        CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
      ])
    }
  }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
    if request.characteristic.uuid == CBUUID(string: "7f27fbcf-2862-4b1e-95d5-2b5850836cbe") {
      request.value = "Updated Data".data(using: .utf8)
      peripheralManager.respond(to: request, withResult: .success)
    }
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    // Handle write requests
  }
}
