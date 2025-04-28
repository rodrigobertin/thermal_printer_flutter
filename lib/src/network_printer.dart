import 'dart:io';
import 'dart:async';
import 'dart:developer';

class NetworkPrinter {
  late String _host;
  int _port = 9100;
  bool _isConnected = false;
  Duration _timeout = const Duration(seconds: 5);
  late Socket _socket;

  NetworkPrinter({
    required String host,
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) {
    _host = host;
    _port = port;
    _timeout = timeout;
  }

  Future<bool> connect() async {
    try {
      _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _isConnected = true;
      return true;
    } catch (e) {
      log('Error connecting to network printer: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<bool> printBytes(List<int> bytes, {bool disconnectAfterPrint = true}) async {
    try {
      if (!_isConnected) {
        final connected = await connect();
        if (!connected) return false;
      }

      _socket.add(bytes);
      await _socket.flush();

      if (disconnectAfterPrint) {
        await disconnect();
      }

      return true;
    } catch (e) {
      log('Error printing via network: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket.flush();
      await _socket.close();
      _isConnected = false;
    } catch (e) {
      log('Error disconnecting network printer: $e');
    }
  }

  bool get isConnected => _isConnected;
}
