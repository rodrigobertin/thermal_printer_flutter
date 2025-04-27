import 'package:thermal_printer_flutter/src/enums/printer_type.dart';

class Printer {
  final String name;
  final String ip;
  final String port;
  final String vendorId;
  final PrinterType type;

  Printer({
    this.name = '',
    this.ip = '',
    this.port = '9100',
    this.vendorId = '',
    required this.type,
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
}
