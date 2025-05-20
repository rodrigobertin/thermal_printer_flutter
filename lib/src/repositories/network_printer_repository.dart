import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'printer_repository.dart';

class NetworkPrinterRepository implements PrinterRepository {
  final MethodChannel _channel = const MethodChannel('thermal_printer_flutter');

  @override
  Future<List<Printer>> getPrinters() async {
    // Para impressoras de rede, o usuário precisa fornecer IP e porta manualmente
    return [];
  }

  @override
  Future<bool> connect(Printer printer) async {
    try {
      final bool result = await _channel.invokeMethod<bool>(
            'connect',
            <String, dynamic>{
              'ip': printer.ip,
              'port': printer.port,
            },
          ) ??
          false;
      return result;
    } catch (e) {
      log('Error connecting network printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
      return false;
    }
  }

  @override
  Future<void> disconnect(Printer printer) async {
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      log('Error disconnecting network printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
    }
  }

  @override
  Future<void> printBytes({required List<int> bytes, required Printer printer}) async {
    try {
      final bool result = await _channel.invokeMethod<bool>(
            'writebytes',
            bytes,
          ) ??
          false;

      if (!result) {
        log('Failed to print via network', name: 'THERMAL_PRINTER_FLUTTER');
      }
    } catch (e) {
      log('Error printing via network: $e', name: 'THERMAL_PRINTER_FLUTTER');
      rethrow;
    }
  }

  @override
  Future<bool> isConnected(Printer printer) async {
    try {
      final bool result = await _channel.invokeMethod<bool>(
            'isConnected',
            <String, dynamic>{
              'ip': printer.ip,
              'port': printer.port,
            },
          ) ??
          false;
      return result;
    } catch (e) {
      log('Error checking network connection: $e', name: 'THERMAL_PRINTER_FLUTTER');
      return false;
    }
  }
}
