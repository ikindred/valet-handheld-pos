import 'dart:async';

import 'package:flutter/foundation.dart';
import '../storage/printer_prefs.dart';
import 'bluetooth_pos_printer.dart';

/// Live Bluetooth printer connection + paired device label for UI.
class PrinterConnectionNotifier extends ChangeNotifier {
  PrinterConnectionNotifier({required BluetoothPosPrinter printer})
      : _printer = printer {
    _printer.listenConnectionStatus((_) => unawaited(_syncConnectionState()));
    unawaited(_loadPrefs());
  }

  final BluetoothPosPrinter _printer;

  PrinterPrefs? _prefs;
  bool _connectedToSaved = false;

  Future<void> _loadPrefs() async {
    _prefs = await PrinterPrefs.load();
    await _syncConnectionState();
    if (_prefs?.hasPairedPrinter == true && !_connectedToSaved) {
      await tryConnectPaired();
    }
  }

  Future<void> _syncConnectionState() async {
    _connectedToSaved = await _printer.isConnectedToSavedPrinter();
    notifyListeners();
  }

  /// Connected to the printer saved in app settings (not merely system BT).
  bool get isConnected => _connectedToSaved;

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
      if (_printer.hasBluetoothLink) {
        return label != null && label.isNotEmpty
            ? '$label · Tap Reconnect'
            : 'Different printer connected';
      }
      return label != null && label.isNotEmpty
          ? '$label · Saved'
          : 'Printer saved';
    }
    return 'Not paired';
  }

  Future<bool> tryConnectPaired() async {
    if (await _printer.isConnectedToSavedPrinter()) {
      await _syncConnectionState();
      return true;
    }
    final ok = await _printer.connectPaired();
    if (ok) {
      _prefs = await PrinterPrefs.load();
    }
    await _syncConnectionState();
    return _connectedToSaved;
  }

  void refresh() {
    unawaited(_syncConnectionState());
  }
}
