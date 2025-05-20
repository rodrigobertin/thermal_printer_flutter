import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'printer_repository.dart';

class BluetoothPrinterRepository implements PrinterRepository {
  final MethodChannel _channel = const MethodChannel('thermal_printer_flutter');

  @override
  Future<List<Printer>> getPrinters() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod<List<dynamic>>('pairedbluetooths') ?? [];
      return devices.map((device) {
        final parts = device.split('#');
        return Printer(
          type: PrinterType.bluethoot,
          name: parts[0],
          bleAddress: parts[1],
        );
      }).toList();
    } catch (e) {
      print('Erro ao obter impressoras Bluetooth: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(Printer printer) async {
    try {
      // Primeiro desconecta qualquer conexão existente
      await disconnect(printer);

      // Aguarda um momento para garantir que a desconexão foi concluída
      await Future.delayed(const Duration(milliseconds: 500));

      // Tenta conectar
      final bool result = await _channel.invokeMethod<bool>('connect', printer.bleAddress) ?? false;
      return result;
    } catch (e) {
      print('Erro ao conectar impressora Bluetooth: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect(Printer printer) async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      print('Erro ao desconectar impressora Bluetooth: $e');
    }
  }

  @override
  Future<void> printBytes({required List<int> bytes, required Printer printer}) async {
    try {
      await _channel.invokeMethod('writebytes', bytes);
    } catch (e) {
      print('Erro ao imprimir bytes: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isConnected(Printer printer) async {
    try {
      final bool result = await _channel.invokeMethod<bool>('isConnected', printer.bleAddress) ?? false;
      return result;
    } catch (e) {
      print('Erro ao verificar conexão Bluetooth: $e');
      return false;
    }
  }
}
