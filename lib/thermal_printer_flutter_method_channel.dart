import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  Future<List<String>> getPrinters() async {
    final List<dynamic>? printers = await methodChannel.invokeMethod<List<dynamic>>('getPrinters');
    return printers?.cast<String>() ?? <String>[];
  }

  @override
  Future<bool> printBytes(List<int> bytes, String printerName) async {
    final bool result = await methodChannel.invokeMethod<bool>(
          'printBytes',
          <String, dynamic>{
            'bytes': bytes,
            'printerName': printerName,
          },
        ) ??
        false;
    return result;
  }
}
