import 'package:thermal_printer_flutter/src/enums/printer_type.dart';
import 'package:thermal_printer_flutter/src/models/printer.dart';
import 'thermal_printer_flutter_platform_interface.dart';
export './src/models/printer.dart';
export './src/enums/printer_type.dart';

class ThermalPrinterFlutter implements ThermalPrinterFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() async {
    return await ThermalPrinterFlutterPlatform.instance.getPlatformVersion();
  }

  @override
  Future<List<Printer>> getPrinters({required PrinterType printerType}) async {
    return await ThermalPrinterFlutterPlatform.instance.getPrinters(printerType: printerType);
  }

  @override
  Future<void> printBytes({required List<int> bytes, required Printer printer}) async {
    return await ThermalPrinterFlutterPlatform.instance.printBytes(bytes: bytes, printer: printer);
  }

  @override
  Future<bool> connect({required Printer printer}) async {
    return await ThermalPrinterFlutterPlatform.instance.connect(printer: printer);
  }
}
