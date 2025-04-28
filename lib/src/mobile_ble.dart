import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';

class MobileBleManager {
  MobileBleManager._privateConstructor();

  static MobileBleManager? _instance;

  static MobileBleManager get instance {
    _instance ??= MobileBleManager._privateConstructor();
    return _instance!;
  }

  final StreamController<List<Printer>> _devicesStream = StreamController<List<Printer>>.broadcast();
  Stream<List<Printer>> get devicesStream => _devicesStream.stream;
  StreamSubscription? _scanSubscription;
  final List<Printer> _devices = [];

  bool get isIos => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      log('Failed to stop scanning for devices: $e');
    }
  }

  Future<bool> connect(Printer printer) async {
    try {
      bool isConnected = false;
      final bt = BluetoothDevice.fromId(printer.bleAddress);
      await bt.connect();
      final stream = bt.connectionState.listen((event) {
        if (event == BluetoothConnectionState.connected) {
          isConnected = true;
        }
      });
      await Future.delayed(const Duration(seconds: 3));
      await stream.cancel();
      return isConnected;
    } catch (e) {
      log('Failed to connect to device: $e');
      return false;
    }
  }

  Future<bool> isConnected(Printer printer) async {
    try {
      final bt = BluetoothDevice.fromId(printer.bleAddress);
      return bt.isConnected;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect(Printer printer) async {
    try {
      final bt = BluetoothDevice.fromId(printer.bleAddress);
      await bt.disconnect();
    } catch (e) {
      log('Failed to disconnect device: $e');
    }
  }

  Future<void> printBytes({required List<int> bytes, required String address}) async {
    try {
      final device = BluetoothDevice.fromId(address);
      if (!device.isConnected) {
        log('Device is not connected');
        return;
      }

      final services = (await device.discoverServices()).skipWhile((value) => value.characteristics.where((element) => element.properties.write).isEmpty);

      BluetoothCharacteristic? writeCharacteristic;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic;
            break;
          }
        }
      }

      if (writeCharacteristic == null) {
        log('No write characteristic found');
        return;
      }

      const maxChunkSize = 512;
      for (var i = 0; i < bytes.length; i += maxChunkSize) {
        final chunk = bytes.sublist(
          i,
          i + maxChunkSize > bytes.length ? bytes.length : i + maxChunkSize,
        );

        await writeCharacteristic.write(
          Uint8List.fromList(chunk),
          withoutResponse: true,
        );
      }
    } catch (e) {
      log('Failed to print data: $e');
      rethrow;
    }
  }

  Future<bool> checkBluetoothState() async {
    try {
      if (Platform.isMacOS) {
        final state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.unknown) {
          log('Bluetooth não suportado no macOS');
          return false;
        }
        if (state == BluetoothAdapterState.off) {
          log('Bluetooth desligado no macOS');
          return false;
        }
      }
      return true;
    } catch (e) {
      log('Erro ao verificar estado do Bluetooth: $e');
      return false;
    }
  }

  Future<List<Printer>> scanPrinters() async {
    try {
      // Verifica o estado do Bluetooth antes de prosseguir
      final isBluetoothOk = await checkBluetoothState();
      if (!isBluetoothOk) {
        return [];
      }

      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _devices.clear();

      if (!isIos) {
        if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
          await FlutterBluePlus.turnOn();
          // Aguarda um momento para o Bluetooth inicializar
          await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        final BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.off) {
          log('Bluetooth is off, turning on...');
          return [];
        }
      }

      // Primeiro tenta obter os dispositivos do sistema
      final systemDevices = await _getSystemDevices();
      _devices.addAll(systemDevices);
      _sortDevices();

      // Se não encontrou dispositivos no sistema, inicia a varredura
      if (_devices.isEmpty) {
        await FlutterBluePlus.stopScan();
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
          androidScanMode: AndroidScanMode.lowLatency,
        );

        // Listen to scan results
        _scanSubscription = FlutterBluePlus.scanResults.listen((result) {
          final devices = result
              .map((e) => Printer(
                    type: PrinterType.bluethoot,
                    name: e.device.platformName,
                    bleAddress: e.device.remoteId.str,
                    isConnected: e.device.isConnected,
                  ))
              .where((device) => device.name.isNotEmpty)
              .toList();

          for (var device in devices) {
            _updateOrAddPrinter(device);
          }
        });

        // Aguarda um tempo para a varredura
        await Future.delayed(const Duration(seconds: 5));
        await FlutterBluePlus.stopScan();
      }

      // Get bonded devices (Android only)
      if (Platform.isAndroid) {
        final bondedDevices = await _getBondedDevices();
        _devices.addAll(bondedDevices);
      }

      _sortDevices();
      return _devices;
    } catch (e) {
      log('Failed to scan printers: $e');
      return [];
    }
  }

  Future<List<Printer>> _getSystemDevices() async {
    return (await FlutterBluePlus.systemDevices([]))
        .map((device) => Printer(
              type: PrinterType.bluethoot,
              name: device.platformName,
              bleAddress: device.remoteId.str,
              isConnected: device.isConnected,
            ))
        .toList();
  }

  Future<List<Printer>> _getBondedDevices() async {
    return (await FlutterBluePlus.bondedDevices)
        .map((device) => Printer(
              type: PrinterType.bluethoot,
              name: device.platformName,
              bleAddress: device.remoteId.str,
              isConnected: device.isConnected,
            ))
        .toList();
  }

  void _updateOrAddPrinter(Printer printer) {
    final index = _devices.indexWhere((device) => device.bleAddress == printer.bleAddress);
    if (index == -1) {
      _devices.add(printer);
    } else {
      _devices[index] = printer;
    }
    _sortDevices();
  }

  void _sortDevices() {
    _devices.removeWhere((element) => element.name.isEmpty);
    // Remove items with the same address
    final Set<String> seen = {};
    _devices.retainWhere((element) {
      if (seen.contains(element.bleAddress)) {
        return false;
      } else {
        seen.add(element.bleAddress);
        return true;
      }
    });
    _devicesStream.add(_devices);
  }

  Future<void> turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();
  }

  Stream<bool> get isBleTurnedOnStream {
    return FlutterBluePlus.adapterState.map(
      (event) => event == BluetoothAdapterState.on,
    );
  }
}
