import 'dart:convert';
import 'package:thermal_printer_flutter/src/enums/printer_type.dart';

class Printer {
  final String name;
  final String ip;
  final String port;
  final String vendorId;
  final PrinterType type;

  Printer({
    required this.type,
    this.name = '',
    this.ip = '',
    this.port = '9100',
    this.vendorId = '',
  });

  Printer copyWith({
    String? name,
    String? ip,
    String? port,
    String? vendorId,
    PrinterType? type,
  }) {
    return Printer(
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      vendorId: vendorId ?? this.vendorId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ip': ip,
      'port': port,
      'vendorId': vendorId,
      'type': type.name,
    };
  }

  factory Printer.fromMap(Map<String, dynamic> map) {
    return Printer(
      name: map['name'] ?? '',
      ip: map['ip'] ?? '',
      port: map['port'] ?? '',
      vendorId: map['vendorId'] ?? '',
      type: PrinterType.values.byName(map['type']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Printer.fromJson(String source) => Printer.fromMap(json.decode(source));
}
