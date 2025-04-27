import 'package:thermal_printer_flutter/src/models/printer.dart';
import 'thermal_printer_flutter_platform_interface.dart';
export './src/models/printer.dart';
export './src/enums/printer_type.dart';

class ThermalPrinterFlutter {
  Future<String?> getPlatformVersion() {
    return ThermalPrinterFlutterPlatform.instance.getPlatformVersion();
  }

  Future<List<Printer>> getPrinters() {
    return ThermalPrinterFlutterPlatform.instance.getPrinters();
  }

  Future<void> printBytes(List<int> bytes, Printer printer) {
    return ThermalPrinterFlutterPlatform.instance.printBytes(bytes, printer);
  }
}
