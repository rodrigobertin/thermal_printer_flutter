import 'dart:convert';

import 'package:thermal_printer_flutter/src/enums/printer_type.dart';

class Printer {
  final String name;
  final String ip;
  final String port;
  final String bleAddress;
  final PrinterType type;
  final bool isConnected;

  Printer({
    required this.type,
    this.name = '',
    this.ip = '',
    this.port = '9100',
    this.bleAddress = '',
    this.isConnected = false,
  });

  Printer copyWith({
    String? name,
    String? ip,
    String? port,
    String? bleAddress,
    PrinterType? type,
    bool? isConnected,
  }) {
    return Printer(
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      bleAddress: bleAddress ?? this.bleAddress,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ip': ip,
      'port': port,
      'bleAddress': bleAddress,
      'type': type.name,
      'isConnected': isConnected,
    };
  }

  factory Printer.fromMap(Map<String, dynamic> map) {
    return Printer(
      name: map['name'] ?? '',
      ip: map['ip'] ?? '',
      port: map['port'] ?? '',
      bleAddress: map['bleAddress'] ?? '',
      type: PrinterType.values.byName(map['type']),
      isConnected: map['isConnected'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Printer.fromJson(String source) => Printer.fromMap(json.decode(source));
}
