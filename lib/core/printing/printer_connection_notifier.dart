import 'package:flutter/foundation.dart';
import '../storage/printer_prefs.dart';
import 'bluetooth_pos_printer.dart';

/// Live Bluetooth printer connection + paired device label for UI.
class PrinterConnectionNotifier extends ChangeNotifier {
  PrinterConnectionNotifier({required BluetoothPosPrinter printer})
      : _printer = printer {
    _connected = _printer.isConnected;
    _printer.listenConnectionStatus((c) {
      if (_connected == c) return;
      _connected = c;
      notifyListeners();
    });
    _loadPrefs();
  }

  final BluetoothPosPrinter _printer;

  PrinterPrefs? _prefs;
  bool _connected = false;

  Future<void> _loadPrefs() async {
    _prefs = await PrinterPrefs.load();
    notifyListeners();
  }

  bool get isConnected => _connected;

  bool get hasPairedPrinter => _prefs?.hasPairedPrinter ?? false;

  String get statusSubtitle {
    if (_connected) {
      final name = _prefs?.name?.trim();
      if (name != null && name.isNotEmpty) return '$name · Connected';
      return 'Connected';
    }
    if (_prefs?.hasPairedPrinter == true) {
      return '${_prefs?.name ?? _prefs?.address} · Tap to connect';
    }
    return 'Not paired';
  }

  Future<bool> tryConnectPaired() async {
    if (_printer.isConnected) {
      _connected = true;
      notifyListeners();
      return true;
    }
    final ok = await _printer.connectPaired();
    _connected = ok && _printer.isConnected;
    notifyListeners();
    return _connected;
  }

  void refresh() {
    _connected = _printer.isConnected;
    notifyListeners();
  }
}
