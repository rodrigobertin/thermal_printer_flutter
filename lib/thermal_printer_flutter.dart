
import 'thermal_printer_flutter_platform_interface.dart';

class ThermalPrinterFlutter {
  Future<String?> getPlatformVersion() {
    return ThermalPrinterFlutterPlatform.instance.getPlatformVersion();
  }
}
