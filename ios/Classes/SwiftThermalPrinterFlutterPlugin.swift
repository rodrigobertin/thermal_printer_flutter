import Flutter
import UIKit
import CoreBluetooth

public class SwiftThermalPrinterFlutterPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterPlugin {
    var centralManager: CBCentralManager?
    var discoveredDevices: [String] = []
    var connectedPeripheral: CBPeripheral!
    var targetService: CBService?
    var targetCharacteristic: CBCharacteristic?
    
    var flutterResult: FlutterResult?
    var bytes: [UInt8]?
    var stringprint = ""
    var writeChunks: [UInt8] = []
    var writeOffset: Int = 0
    var writeChunkSize: Int = 512
    var writeResult: FlutterResult?
    override init() {
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "thermal_printer_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftThermalPrinterFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        self.flutterResult = result
        
        switch call.method {
        case "getPlatformVersion":
            let iosVersion = UIDevice.current.systemVersion
            result("iOS " + iosVersion)
            
        case "isBluetoothEnabled":
            switch centralManager?.state {
            case .poweredOn:
                result(true)
            default:
                result(false)
            }
            
        case "checkBluetoothPermissions":
            if #available(iOS 10.0, *) {
                switch centralManager?.state {
                case .poweredOn:
                    result(true)
                default:
                    result(false)
                }
            }
            
        case "enableBluetooth":
            result(false)
            
        case "getPrinters":
            if let args = call.arguments as? [String: Any],
               let printerType = args["printerType"] as? String {
                switch printerType {
                case "bluethoot":
                    discoveredDevices.removeAll()
                    centralManager?.scanForPeripherals(withServices: nil, options: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.centralManager?.stopScan()
                        let printers = self.discoveredDevices.map { deviceString -> [String: Any] in
                            let components = deviceString.split(separator: "#")
                            return [
                                "name": String(components[0]),
                                "bleAddress": String(components[1]),
                                "type": "bluethoot",
                                "isConnected": false
                            ]
                        }
                        result(printers)
                    }
                case "usb":
                    result([])
                default:
                    result([])
                }
            } else {
                result([])
            }
        case "pairedbluetooths":
            discoveredDevices.removeAll()
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.centralManager?.stopScan()
                let printers = self.discoveredDevices.map { deviceString -> [String: Any] in
                    let components = deviceString.split(separator: "#")
                    return [
                        "name": String(components[0]),
                        "bleAddress": String(components[1]),
                        "type": "bluethoot",
                        "isConnected": false
                    ]
                }
                result(printers)
            }
        case "connect":
            guard let bleAddress = call.arguments as? String,
                  let uuid = UUID(uuidString: bleAddress) else {
                print("Invalid arguments for connect")
                result(false)
                return
            }
            
            print("Attempting to connect to device with address: \(bleAddress)")
            
            let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid])
            guard let peripheral = peripherals?.first else {
                print("No peripheral found with UUID: \(bleAddress)")
                result(false)
                return
            }
            
            print("Found peripheral: \(peripheral.name ?? "Unknown")")
            centralManager?.connect(peripheral, options: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if peripheral.state == .connected {
                    print("Successfully connected to peripheral")
                    self.connectedPeripheral = peripheral
                    self.connectedPeripheral.delegate = self
                    self.connectedPeripheral.discoverServices(nil)
                    result(true)
                } else {
                    print("Failed to connect to peripheral")
                    result(false)
                }
            }
            
        case "isConnected":
            let isConnected = connectedPeripheral?.state == .connected
            print("Connection status: \(isConnected)")
            result(isConnected)
            
        case "disconnect":
            if let peripheral = connectedPeripheral {
                print("Disconnecting from peripheral: \(peripheral.name ?? "Unknown")")
                centralManager?.cancelPeripheralConnection(peripheral)
                targetCharacteristic = nil
                result(true)
            } else {
                print("No peripheral to disconnect")
                result(false)
            }
            
        case "writebytes":
            guard let arguments = call.arguments as? [UInt8],
                  let characteristic = targetCharacteristic else {
                print("Invalid arguments for writebytes or no characteristic available")
                result(false)
                return
            }
            print("Attempting to write \(arguments.count) bytes")
            writeChunks = arguments
            writeOffset = 0
            writeChunkSize = 512
            writeResult = result
            self.sendNextChunk()
            
        case "printstring":
            guard let string = call.arguments as? String,
                  let characteristic = targetCharacteristic else {
                print("Invalid arguments for printstring or no characteristic available")
                result(false)
                return
            }
            print("Attempting to print string: \(string)")
            
            let data = Data(string.utf8)
            connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is enabled")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Bluetooth state is unknown")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            let device = "\(name)#\(peripheral.identifier.uuidString)"
            if !discoveredDevices.contains(device) {
                discoveredDevices.append(device)
                print("Discovered device: \(name) with UUID: \(peripheral.identifier.uuidString)")
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "Unknown error")")
        flutterResult?(false)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "No error")")
        flutterResult?(error == nil)
    }
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found")
            return
        }
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found for service: \(service.uuid)")
            return
        }
        
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid) with properties: \(characteristic.properties)")
            
            // Kiểm tra xem có hỗ trợ write không
            if characteristic.properties.contains(.write) {
                targetCharacteristic = characteristic
                targetService = service
                print("Found writable characteristic: \(characteristic.uuid)")
                break
            }
        }
        
        if targetCharacteristic == nil {
            print("No writable characteristic found in service: \(service.uuid)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value: \(error.localizedDescription)")
            writeResult?(false)
            writeResult = nil
        } else {
            print("Successfully wrote value to characteristic: \(characteristic.uuid)")
            // If there are more chunks to send, continue sending
            if !writeChunks.isEmpty && writeOffset < writeChunks.count {
                // Send the next chunk after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.sendNextChunk()
                }
            } else {
                writeChunks = []
                writeOffset = 0
                writeResult?(true)
                writeResult = nil
            }
        }
    }
    
    func sendNextChunk() {
        guard let characteristic = targetCharacteristic else { return }
        if writeOffset >= writeChunks.count {
            print("All chunks sent")
            writeResult?(true)
            writeResult = nil
            return
        }
        let end = min(writeOffset + writeChunkSize, writeChunks.count)
        let chunk = Array(writeChunks[writeOffset..<end])
        let data = Data(chunk)
        print("Writing chunk of size \(chunk.count)")
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
        writeOffset = end
    }
}
