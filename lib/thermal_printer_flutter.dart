import 'thermal_printer_flutter_platform_interface.dart';

class ThermalPrinterFlutter {
  Future<String?> getPlatformVersion() {
    return ThermalPrinterFlutterPlatform.instance.getPlatformVersion();
  }

  Future<List<Printer>> getPrinters() {
    return ThermalPrinterFlutterPlatform.instance.getPrinters();
  }

  Future<bool> printBytes(List<int> bytes, String printerName) {
    return ThermalPrinterFlutterPlatform.instance.printBytes(bytes, printerName);
  }
}
