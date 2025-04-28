# thermal_printer_flutter

## Permissões necessárias

### Android
Adicione as seguintes permissões no arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS
Adicione as seguintes chaves no arquivo `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
```

### macOS
Adicione as seguintes chaves no arquivo `macos/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
```