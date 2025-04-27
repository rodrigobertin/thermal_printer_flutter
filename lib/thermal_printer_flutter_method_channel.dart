import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/src/helpers/platform.dart';
import 'package:thermal_printer_flutter/src/models/printer.dart';
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
  Future<List<Printer>> getPrinters() async {
    List<Printer> result = [];
    if (isWindows) {
      final List<dynamic>? printers = await methodChannel.invokeMethod<List<dynamic>>('getPrinters');
      if (isWindows) {
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
  Future<void> printBytes(List<int> bytes, Printer printer) async {
    if (isWindows) {
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
