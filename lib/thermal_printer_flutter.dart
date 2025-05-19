import 'package:flutter/cupertino.dart';
import 'package:thermal_printer_flutter/src/enums/printer_type.dart';
import 'package:thermal_printer_flutter/src/models/configuration.dart';
import 'package:thermal_printer_flutter/src/models/printer.dart';
import 'package:thermal_printer_flutter/src/services/screent_shot.dart';
import 'thermal_printer_flutter_platform_interface.dart';
export './src/models/printer.dart';
export './src/enums/printer_type.dart';
export './src/services/screent_shot.dart';
export './src/models/configuration.dart';
import 'package:image/image.dart' as img;
export 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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
  Future<void> printBytes({required List<int> bytes, required Printer printer, Configuration? configuration}) async {
    return await ThermalPrinterFlutterPlatform.instance.printBytes(bytes: bytes, printer: printer, configuration: configuration ?? Configuration());
  }

  @override
  Future<bool> connect({required Printer printer}) async {
    return await ThermalPrinterFlutterPlatform.instance.connect(printer: printer);
  }

  Future<img.Image> screenShotWidget(
    BuildContext context, {
    required Widget widget,
    double pixelRatio = 3.0,
    int width = 550,
    int threshold = 160,
    bool flipHorizontal = false,
    bool applyTextScaling = true,
    bool useBetterText = true,
    double textScaleFactor = 1.3,
  }) async {
    return await ThermalScreenshot.captureWidgetAsMonochromeImage(context,
        widget: widget, flipHorizontal: flipHorizontal, pixelRatio: pixelRatio, threshold: threshold, width: width, applyTextScaling: applyTextScaling, useBetterText: useBetterText, textScaleFactor: textScaleFactor);
  }
}
