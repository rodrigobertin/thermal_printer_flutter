import 'package:thermal_printer_flutter/src/enums/printer_type.dart';
import 'package:thermal_printer_flutter/src/models/printer.dart';
import 'thermal_printer_flutter_platform_interface.dart';
export './src/models/printer.dart';
export './src/enums/printer_type.dart';

class ThermalPrinterFlutter {
  Future<String?> getPlatformVersion() {
    return ThermalPrinterFlutterPlatform.instance.getPlatformVersion();
  }

  Future<List<Printer>> getPrinters({required PrinterType printerType}) {
    return ThermalPrinterFlutterPlatform.instance.getPrinters(printerType: printerType);
  }

  Future<void> printBytes({required List<int> bytes, required Printer printer}) {
    return ThermalPrinterFlutterPlatform.instance.printBytes(bytes: bytes, printer: printer);
  }
}
