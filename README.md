# thermal_printer_flutter

Flutter plugin for thermal printing with support for multiple platforms and connection types.

## Support Table

| Platform   | USB | Bluetooth | Network |
|------------|-----|-----------|---------|
| Android    | ❌  | ✅        | ✅      |
| iOS        | ❌  | ✅        | ✅      |
| macOS      | ❌  | ✅        | ✅      |
| Windows    | ✅  | ✅        | ✅      |
| Linux      | ❌  | ❌        | ✅      |
| Web        | ❌  | ❌        | ✅      |

## Project Setup

### Android

1. Add the following permissions to the `android/app/src/main/AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

2. For Android 12 or higher, also add:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

### iOS

1. Add the following keys to the `ios/Runner/Info.plist` file:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth access to connect to thermal printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>We need Bluetooth access to connect to thermal printers</string>
```

2. For iOS 13 or higher, also add:

```xml
<key>NSBluetoothAlwaysAndWhenInUseUsageDescription</key>
<string>We need Bluetooth access to connect to thermal printers</string>
```

### macOS

1. Add the following keys to the `macos/Runner/Info.plist` file:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth access to connect to thermal printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>We need Bluetooth access to connect to thermal printers</string>
```

2. Add the following keys to the `macos/Runner/DebugProfile.entitlements` file:

```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```

3. Add the following keys to the `macos/Runner/Release.entitlements` file:

```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```

### Windows

1. For USB printers, ensure the printer drivers are installed.
2. For Bluetooth printers, Windows must support Bluetooth LE (Bluetooth 4.0 or higher).

### Linux

1. For network printers, ensure that the firewall allows connections on port 9100 (or the configured port).

### Web

1. For network printers, ensure that the web server allows WebSocket connections.
2. Add the following script to the `web/index.html` file:

```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('flutter-first-frame', function () {
      navigator.serviceWorker.register('flutter_service_worker.js');
    });
  }
</script>
```

## Usage

```dart
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
//⚠️ Use a library based on esc_pos_utils to generate the print bytes
import 'package:esc_pos_utils/esc_pos_utils.dart';

// Create an instance of the plugin
final thermalPrinter = ThermalPrinterFlutter();
Printer? _selectedPrinter;

// Only Android, Ios, Macos
final bluetoothPrinters = await thermalPrinter.getPrinters(printerType: PrinterType.bluethoot);
// Only Windows 
final usbPrinters = await thermalPrinter.getPrinters(printerType: PrinterType.usb);


// Connect to a printer only bluethoot
final connected = await thermalPrinter.connect(printer: selectedPrinter);


 Future<void> _printTest({required ThermalPrinterFlutter termalPrinter,  required Printer printer}) async {
    try {
      final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());
      List<int> bytes = [];

      bytes += generator.text('Print Test',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ));
      bytes += generator.feed(2);
      bytes += generator.text('Date: ${DateTime.now()}');
      bytes += generator.feed(2);
      bytes += generator.text('This is a test print');
      bytes += generator.feed(2);
      bytes += generator.cut();

      await termalPrinter.printBytes(bytes: bytes, printer: printer);
     
    } catch (e) {
      print('Error printing: $e');
    }
  }
```

## Example

Check out the complete example at `example/lib/main.dart` for a sample implementation with a graphical interface.

## Contribution

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
