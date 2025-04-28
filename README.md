# thermal_printer_flutter

Plugin Flutter para impressão térmica com suporte a múltiplas plataformas e tipos de conexão.

## Tabela de Suporte

| Plataforma | USB | Bluetooth | Rede |
|------------|-----|-----------|------|
| Android    | ❌  | ✅        | ✅   |
| iOS        | ❌  | ✅        | ✅   |
| macOS      | ❌  | ✅        | ✅   |
| Windows    | ✅  | ✅        | ✅   |
| Linux      | ❌  | ❌        | ✅   |
| Web        | ❌  | ❌        | ✅   |

## Configuração do Projeto

### Android

1. Adicione as seguintes permissões no arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

2. Para Android 12 ou superior, adicione também:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

### iOS

1. Adicione as seguintes chaves no arquivo `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
```

2. Para iOS 13 ou superior, adicione também:

```xml
<key>NSBluetoothAlwaysAndWhenInUseUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
```

### macOS

1. Adicione as seguintes chaves no arquivo `macos/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar com impressoras térmicas</string>
```

### Windows

1. Para impressoras USB, certifique-se de que os drivers da impressora estão instalados
2. Para Bluetooth, o Windows deve ter suporte a Bluetooth LE (Bluetooth 4.0 ou superior)

### Linux

1. Para impressoras de rede, certifique-se de que o firewall permite conexões na porta 9100 (ou a porta configurada)

### Web

1. Para impressoras de rede, certifique-se de que o servidor web permite conexões WebSocket
2. Adicione a seguinte permissão no arquivo `web/index.html`:

```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('flutter-first-frame', function () {
      navigator.serviceWorker.register('flutter_service_worker.js');
    });
  }
</script>
```

## Uso

```dart
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';

// Criar uma instância do plugin
final thermalPrinter = ThermalPrinterFlutter();

// Buscar impressoras
final bluetoothPrinters = await thermalPrinter.getPrinters(printerType: PrinterType.bluethoot);
final usbPrinters = await thermalPrinter.getPrinters(printerType: PrinterType.usb);
final networkPrinters = await thermalPrinter.getPrinters(printerType: PrinterType.network);

// Conectar com uma impressora
final connected = await thermalPrinter.connect(printer: selectedPrinter);

// Imprimir
await thermalPrinter.printBytes(bytes: bytes, printer: selectedPrinter);
```

## Exemplo

Veja o exemplo completo em `example/lib/main.dart` para um exemplo de implementação com interface gráfica.

## Dependências

Adicione ao seu `pubspec.yaml`:

```yaml
dependencies:
  thermal_printer_flutter: ^0.0.1
  flutter_blue_plus: ^1.31.3
  esc_pos_utils: ^1.1.0
```

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.