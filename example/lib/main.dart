import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:thermal_printer_flutter/thermal_printer_flutter.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _thermalPrinterFlutterPlugin = ThermalPrinterFlutter();
  List<Printer> _printers = [];
  Printer? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _thermalPrinterFlutterPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await _thermalPrinterFlutterPlugin.getPrinters(printerType: PrinterType.bluethoot);
      setState(() {
        _printers = printers;
        if (printers.isNotEmpty) {
          _selectedPrinter = printers[0];
        }
      });
    } catch (e) {
      print('Erro ao carregar impressoras: $e');
    }
  }

  Future<void> _printTest() async {
    if (_selectedPrinter == null) return;

    try {
      final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());
      List<int> bytes = [];

      bytes += generator.text('Teste de impressao');
      bytes += generator.feed(2);
      bytes += generator.cut();
      // final bytes = generator
      //   ..text('Teste de Impressão',
      //       styles: const PosStyles(
      //         align: PosAlign.center,
      //         bold: true,
      //         height: PosTextSize.size2,
      //         width: PosTextSize.size2,
      //       ))
      //   ..feed(2)
      //   ..text('Data: ${DateTime.now()}')
      //   ..feed(2)
      //   ..text('Esta é uma impressão de teste')
      //   ..feed(2)
      //   ..cut();

      await _thermalPrinterFlutterPlugin.printBytes(bytes: bytes, printer: _selectedPrinter!);
    } catch (e) {
      print('Erro ao imprimir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Running on: $_platformVersion\n'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadPrinters,
                  child: const Text('Carregar Impressoras'),
                ),
                const SizedBox(height: 20),
                if (_printers.isNotEmpty) ...[
                  const Text('Selecione uma impressora:'),
                  const SizedBox(height: 10),
                  DropdownButton<Printer>(
                    value: _selectedPrinter,
                    items: _printers.map((printer) {
                      return DropdownMenuItem<Printer>(
                        value: printer,
                        child: Text(printer.name),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPrinter = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _printTest,
                    child: const Text('Imprimir Teste'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
