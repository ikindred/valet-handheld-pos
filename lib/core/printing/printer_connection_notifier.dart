import 'package:flutter/foundation.dart';
import '../storage/printer_prefs.dart';
import 'bluetooth_pos_printer.dart';

/// Live Bluetooth printer connection + paired device label for UI.
class PrinterConnectionNotifier extends ChangeNotifier {
  PrinterConnectionNotifier({required BluetoothPosPrinter printer})
      : _printer = printer {
    _printer.listenConnectionStatus((_) => notifyListeners());
    _loadPrefs();
  }

  final BluetoothPosPrinter _printer;

  PrinterPrefs? _prefs;

  Future<void> _loadPrefs() async {
    _prefs = await PrinterPrefs.load();
    notifyListeners();
    if (_prefs?.hasPairedPrinter == true && !_printer.isConnected) {
      await tryConnectPaired();
    }
  }

  /// Native Bluetooth link status (single source of truth).
  bool get isConnected => _printer.isConnected;

  bool get hasPairedPrinter => _prefs?.hasPairedPrinter ?? false;

  String? get pairedDisplayName {
    final name = _prefs?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return _prefs?.address?.trim();
  }

  String get statusSubtitle {
    final label = pairedDisplayName;
    if (isConnected) {
      return label != null && label.isNotEmpty ? '$label · Connected' : 'Connected';
    }
    if (hasPairedPrinter) {
      return label != null && label.isNotEmpty
          ? '$label · Saved'
          : 'Printer saved';
    }
    return 'Not paired';
  }

  Future<bool> tryConnectPaired() async {
    if (_printer.isConnected) return true;
    final ok = await _printer.connectPaired();
    if (ok) {
      _prefs = await PrinterPrefs.load();
    }
    notifyListeners();
    return _printer.isConnected;
  }

  void refresh() => notifyListeners();
}
