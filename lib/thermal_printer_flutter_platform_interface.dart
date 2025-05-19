import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:thermal_printer_flutter/src/models/configuration.dart';
import 'package:thermal_printer_flutter/src/models/printer.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';

import 'thermal_printer_flutter_method_channel.dart';

abstract class ThermalPrinterFlutterPlatform extends PlatformInterface {
  /// Constructs a ThermalPrinterFlutterPlatform.
  ThermalPrinterFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ThermalPrinterFlutterPlatform _instance = MethodChannelThermalPrinterFlutter();

  /// The default instance of [ThermalPrinterFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelThermalPrinterFlutter].
  static ThermalPrinterFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ThermalPrinterFlutterPlatform] when
  /// they register themselves.
  static set instance(ThermalPrinterFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Printer>> getPrinters({required PrinterType printerType}) {
    throw UnimplementedError('getPrinters() has not been implemented.');
  }

  Future<void> printBytes({required List<int> bytes, required Printer printer, required Configuration configuration}) {
    throw UnimplementedError('printBytes() has not been implemented.');
  }

  Future<bool> connect({required Printer printer}) {
    throw UnimplementedError('printBytes() has not been implemented.');
  }
}
