import FlutterMacOS
import AppKit
import CoreBluetooth
import IOKit
import IOKit.usb

public class ThermalPrinterFlutterPlugin: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterPlugin {
    var centralManager: CBCentralManager?
    var discoveredDevices: [String] = []
    var connectedPeripheral: CBPeripheral!
    var targetService: CBService?
    var targetCharacteristic: CBCharacteristic?
    
    var flutterResult: FlutterResult?
    var bytes: [UInt8]?
    
    // UUIDs comuns para impressoras térmicas
    let printerServiceUUID = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    let printerCharacteristicUUID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    
    override init() {
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "thermal_printer_flutter", binaryMessenger: registrar.messenger)
        let instance = ThermalPrinterFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Initialize central manager if not already initialized
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        self.flutterResult = result
        
        switch call.method {
        case "getPlatformVersion":
            let macOSVersion = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(macOSVersion.majorVersion).\(macOSVersion.minorVersion).\(macOSVersion.patchVersion)"
            result("macOS \(versionString)")
            
        case "isBluetoothEnabled":
            switch centralManager?.state {
            case .poweredOn:
                result(true)
            default:
                result(false)
            }
            
        case "checkBluetoothPermissions":
            result(true)
            
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
                    let usbPrinters = self.getUSBPrinters()
                    result(usbPrinters)
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
            
        case "usbprinters":
            let usbPrinters = self.getUSBPrinters()
            result(usbPrinters)
            
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
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
            print("Using characteristic: \(characteristic.uuid)")
            print("Characteristic properties: \(characteristic.properties)")
            
            // Dividir os dados em chunks menores se necessário
            let chunkSize = 512
            var offset = 0
            while offset < arguments.count {
                let end = min(offset + chunkSize, arguments.count)
                let chunk = Array(arguments[offset..<end])
                let data = Data(chunk)
                
                let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                print("Writing chunk of size \(chunk.count) with type \(writeType)")
                connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
                
                offset = end
                // Pequeno delay entre chunks
                Thread.sleep(forTimeInterval: 0.1)
            }
            result(true)
            
        case "printstring":
            guard let string = call.arguments as? String,
                  let characteristic = targetCharacteristic else {
                print("Invalid arguments for printstring or no characteristic available")
                result(false)
                return
            }
            print("Attempting to print string: \(string)")
            let data = Data(string.utf8)
            let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
            result(true)
            
        case "printBytes":
            if let args = call.arguments as? [String: Any],
               let bytes = args["bytes"] as? [UInt8],
               let characteristic = targetCharacteristic {
                print("Attempting to print \(bytes.count) bytes")
                let data = Data(bytes)
                let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
                result(true)
            } else {
                print("Invalid arguments for printBytes or no characteristic available")
                result(false)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - USB Printer Methods
    
    private func getUSBPrinters() -> [[String: Any]] {
        var printers: [[String: Any]] = []
        
        var masterPort: mach_port_t = 0
        let status = IOMasterPort(bootstrap_port, &masterPort)
        
        guard status == KERN_SUCCESS else {
            print("Failed to create master port")
            return printers
        }
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
        
        if result == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != 0 {
                if let printer = getPrinterInfo(from: device) {
                    printers.append(printer)
                }
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        return printers
    }
    
    private func getPrinterInfo(from device: io_object_t) -> [String: Any]? {
        var printerInfo: [String: Any] = [:]
        
        // Get device name
        if let name = getDeviceProperty(device, key: "USB Product Name") as? String {
            printerInfo["name"] = name
        } else {
            printerInfo["name"] = "Unknown USB Printer"
        }
        
        // Get device address
        if let address = getDeviceProperty(device, key: "USB Address") as? Int {
            printerInfo["usbAddress"] = String(address)
        }
        
        // Add type
        printerInfo["type"] = "usb"
        printerInfo["isConnected"] = true
        
        return printerInfo
    }
    
    private func getDeviceProperty(_ device: io_object_t, key: String) -> Any? {
        var value: Any?
        let keyRef = IORegistryEntryCreateCFProperty(device, key as CFString, kCFAllocatorDefault, 0)
        if let keyRef = keyRef {
            value = keyRef.takeUnretainedValue()
        }
        return value
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
        
        if let services = peripheral.services {
            for service in services {
                print("Discovered service: \(service.uuid)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")
                print("Characteristic properties: \(characteristic.properties)")
                
                // Lista de UUIDs possíveis para características de impressão
                let possiblePrinterCharacteristics = [
                    "49535343-1E4D-4BD9-BA61-23C647249616", // UUID original
                    "49535343-ACA3-481C-91EC-D85E28A60318", // UUID encontrado
                    "49535343-8841-43F4-A8D4-ECBE34729BB3", // UUID comum para impressoras
                    "49535343-4C02-A5E5-4B9A-9B9A-9B9A9B9A9B9A" // UUID genérico
                ]
                
                if possiblePrinterCharacteristics.contains(characteristic.uuid.uuidString) {
                    targetCharacteristic = characteristic
                    print("Found printer characteristic: \(characteristic.uuid.uuidString)")
                    print("Characteristic properties: \(characteristic.properties)")
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value: \(error.localizedDescription)")
            print("Error details: \(error)")
            flutterResult?(false)
        } else {
            print("Successfully wrote value to characteristic: \(characteristic.uuid)")
            print("Characteristic properties: \(characteristic.properties)")
            flutterResult?(true)
        }
    }
    
    // MARK: - Write Methods
    
    private func writeData(_ data: Data, characteristic: CBCharacteristic) {
        print("Writing data of length: \(data.count)")
        print("Using characteristic: \(characteristic.uuid)")
        print("Characteristic properties: \(characteristic.properties)")
        
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        connectedPeripheral?.writeValue(data, for: characteristic, type: writeType)
    }
}
