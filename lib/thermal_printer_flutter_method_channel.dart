import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'thermal_printer_flutter_platform_interface.dart';

/// An implementation of [ThermalPrinterFlutterPlatform] that uses method channels.
class MethodChannelThermalPrinterFlutter implements ThermalPrinterFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('thermal_printer_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<Printer>> getPrinters({required PrinterType printerType}) async {
    if (printerType == PrinterType.usb) {
      try {
        final List<dynamic>? printers = await methodChannel.invokeMethod<List<dynamic>>('getPrinters');
        final List<String> resultWin = printers?.cast<String>() ?? [];
        return resultWin.map((p) => Printer(type: PrinterType.usb, name: p)).toList();
      } catch (e) {
        log('Error getting USB printers: $e', name: 'THERMAL_PRINTER_FLUTTER');
        return [];
      }
    } else if (printerType == PrinterType.bluethoot) {
      try {
        final List<dynamic>? devices = await methodChannel.invokeMethod<List<dynamic>>('pairedbluetooths');
        return devices?.map((d) {
              final parts = d.split('#');
              return Printer(
                type: PrinterType.bluethoot,
                name: parts[0],
                bleAddress: parts[1],
              );
            }).toList() ??
            [];
      } catch (e) {
        log('Error getting Bluetooth printers: $e', name: 'THERMAL_PRINTER_FLUTTER');
        return [];
      }
    } else if (printerType == PrinterType.network) {
      // Para impressoras de rede, o usuário precisa fornecer IP e porta manualmente
      return [];
    }

    return [];
  }

  @override
  Future<void> printBytes({required List<int> bytes, required Printer printer}) async {
    if (printer.type == PrinterType.usb) {
      try {
        final bool result = await methodChannel.invokeMethod<bool>(
              'printBytes',
              <String, dynamic>{
                'bytes': bytes,
                'printerName': printer.name,
              },
            ) ??
            false;
        if (!result) {
          log('Failed to print bytes', name: 'THERMAL_PRINTER_FLUTTER');
        }
      } catch (e) {
        log('Error printing: $e', name: 'THERMAL_PRINTER_FLUTTER');
        rethrow;
      }
    } else if (printer.type == PrinterType.bluethoot) {
      try {
        final bool result = await methodChannel.invokeMethod<bool>(
              'writebytes',
              bytes,
            ) ??
            false;

        if (!result) {
          log('Failed to print via Bluetooth', name: 'THERMAL_PRINTER_FLUTTER');
        }
      } catch (e) {
        log('Error printing via Bluetooth: $e', name: 'THERMAL_PRINTER_FLUTTER');
        rethrow;
      }
    } else if (printer.type == PrinterType.network) {
      try {
        final bool result = await methodChannel.invokeMethod<bool>(
              'printNetworkBytes',
              <String, dynamic>{
                'bytes': bytes,
                'ip': printer.ip,
                'port': int.tryParse(printer.port) ?? 9100,
              },
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
  }

  @override
  Future<bool> connect({required Printer printer}) async {
    if (printer.type == PrinterType.bluethoot) {
      try {
        final bool result = await methodChannel.invokeMethod<bool>(
              'connect',
              printer.bleAddress,
            ) ??
            false;
        return result;
      } catch (e) {
        log('Error connecting Bluetooth printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
        return false;
      }
    } else if (printer.type == PrinterType.network) {
      try {
        final bool result = await methodChannel.invokeMethod<bool>(
              'connectNetwork',
              <String, dynamic>{
                'ip': printer.ip,
                'port': int.tryParse(printer.port) ?? 9100,
              },
            ) ??
            false;
        return result;
      } catch (e) {
        log('Error connecting network printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
        return false;
      }
    }
    return false;
  }

  @override
  Future<void> disconnect({required Printer printer}) async {
    if (printer.type == PrinterType.bluethoot) {
      try {
        await methodChannel.invokeMethod('disconnect');
      } catch (e) {
        log('Error disconnecting Bluetooth printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
      }
    } else if (printer.type == PrinterType.network) {
      try {
        await methodChannel.invokeMethod('disconnectNetwork');
      } catch (e) {
        log('Error disconnecting network printer: $e', name: 'THERMAL_PRINTER_FLUTTER');
      }
    }
  }
}
