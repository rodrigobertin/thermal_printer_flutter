import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/src/helpers/platform.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'thermal_printer_flutter_platform_interface.dart';

/// An implementation of [ThermalPrinterFlutterPlatform] that uses method channels.
class MethodChannelThermalPrinterFlutter extends ThermalPrinterFlutterPlatform {
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
    List<Printer> result = [];
    if (isWindows) {
      if (printerType == PrinterType.usb) {
        final List<dynamic>? printers = await methodChannel.invokeMethod<List<dynamic>>('getPrinters');
        final List<String> resultWin = printers?.cast<String>() ?? [];
        result = resultWin.map((p) => Printer(type: PrinterType.usb, name: p)).toList();
      } else {
        _logPlatformNotSuported();
      }
    } else {
      _logPlatformNotSuported();
    }

    return result;
  }

  @override
  Future<void> printBytes({required List<int> bytes, required Printer printer}) async {
    if (isWindows && printer.type == PrinterType.usb) {
      final bool result = await methodChannel.invokeMethod<bool>(
            'printBytes',
            <String, dynamic>{
              'bytes': bytes,
              'printerName': printer.name,
            },
          ) ??
          false;
      if (result == false) log('printBytes error', name: 'THERMAL_PRINTER_FLUTTER');
    }
  }

  void _logPlatformNotSuported() {
    log('Platform not suported', name: 'THERMAL_PRINTER_FLUTTER');
  }
}
