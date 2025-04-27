// import 'package:flutter_test/flutter_test.dart';
// import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
// import 'package:thermal_printer_flutter/thermal_printer_flutter_platform_interface.dart';
// import 'package:thermal_printer_flutter/thermal_printer_flutter_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockThermalPrinterFlutterPlatform
//     with MockPlatformInterfaceMixin
//     implements ThermalPrinterFlutterPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final ThermalPrinterFlutterPlatform initialPlatform = ThermalPrinterFlutterPlatform.instance;

//   test('$MethodChannelThermalPrinterFlutter is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelThermalPrinterFlutter>());
//   });

//   test('getPlatformVersion', () async {
//     ThermalPrinterFlutter thermalPrinterFlutterPlugin = ThermalPrinterFlutter();
//     MockThermalPrinterFlutterPlatform fakePlatform = MockThermalPrinterFlutterPlatform();
//     ThermalPrinterFlutterPlatform.instance = fakePlatform;

//     expect(await thermalPrinterFlutterPlugin.getPlatformVersion(), '42');
//   });
// }
