import 'dart:async';
import 'dart:developer';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

class WinBleManager {
  WinBleManager._privateConstructor();

  static WinBleManager? _instance;
  static bool _isInitialized = false;

  static WinBleManager get instance {
    _instance ??= WinBleManager._privateConstructor();
    return _instance!;
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await WinBle.initialize(serverPath: await WinServer.path());
        _isInitialized = true;
      } catch (e) {
        log('Erro ao inicializar Bluetooth: $e', name: 'THERMAL_PRINTER_FLUTTER');
        rethrow;
      }
    }
  }

  bool _isPrinterDevice(BleDevice device) {
    final serviceUUIDs = device.serviceUuids;
    if (serviceUUIDs.isEmpty && device.name.isNotEmpty) return true;
    final hasPrinterUUID = serviceUUIDs.any((uuid) =>
            uuid.toLowerCase() == '000018f0-0000-1000-8000-00805f9b34fb' || // Serviço genérico de impressora
            uuid.toLowerCase() == 'e7810a71-73ae-499d-8c15-faa9aef0c3f2' // Serviço específico de impressora térmica
        );

    return hasPrinterUUID;
  }

  Future<bool> isConnected(String address) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      return await WinBle.isPaired(address);
    } catch (e) {
      log('Erro ao verificar conexão: $e', name: 'THERMAL_PRINTER_FLUTTER');
      return false;
    }
  }

  Future<bool> connect(String address) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await WinBle.connect(address);
      // Aguarda um pouco para garantir que a conexão foi estabelecida
      await Future.delayed(const Duration(seconds: 2));
      return await WinBle.isPaired(address);
    } catch (e) {
      log('Erro ao conectar: $e', name: 'THERMAL_PRINTER_FLUTTER');
      return false;
    }
  }

  Future<void> disconnect(String address) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await WinBle.disconnect(address);
    } catch (e) {
      log('Erro ao desconectar: $e', name: 'THERMAL_PRINTER_FLUTTER');
    }
  }

  Future<List<Printer>> scanPrinters({Duration timeout = const Duration(seconds: 5)}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final completer = Completer<List<Printer>>();
      final devices = <String, Printer>{};
      StreamSubscription? subscription;
      Timer? timeoutTimer;

      subscription = WinBle.scanStream.listen((event) async {
        if (event.name.isNotEmpty && !devices.containsKey(event.address)) {
          if (_isPrinterDevice(event)) {
            final connected = await isConnected(event.address);
            devices[event.address] = Printer(
              type: PrinterType.bluethoot,
              name: event.name,
              bleAddress: event.address,
              isConnected: connected,
            );

            if (devices.isNotEmpty) {
              timeoutTimer?.cancel();
              Timer(const Duration(seconds: 1), () {
                subscription?.cancel();
                WinBle.stopScanning();
                completer.complete(devices.values.toList());
              });
            }
          }
        }
      });

      timeoutTimer = Timer(timeout, () {
        subscription?.cancel();
        WinBle.stopScanning();
        completer.complete(devices.values.toList());
      });

      WinBle.startScanning();
      return await completer.future;
    } catch (e) {
      log('Erro ao buscar impressoras Bluetooth: $e', name: 'THERMAL_PRINTER_FLUTTER');
      return [];
    } finally {
      WinBle.dispose();
    }
  }

  Future<bool> isBluetoothEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }
    return (await WinBle.getBluetoothState()) == BleState.On;
  }

  Future<void> enableBluetooth() async {
    if (!_isInitialized) {
      await initialize();
    }
    await WinBle.updateBluetoothState(true);
  }

  Stream<bool> get bluetoothStateStream => WinBle.bleState.map((state) => state == BleState.On);
}
