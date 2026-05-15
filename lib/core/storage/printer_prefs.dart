import 'package:shared_preferences/shared_preferences.dart';

import '../printing/printer_config.dart';
import 'prefs_keys.dart';

/// Last paired Bluetooth thermal printer (ESC/POS).
class PrinterPrefs {
  PrinterPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrinterPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterPrefs(prefs);
  }

  String? get address => _prefs.getString(PrefsKeys.printerAddress);

  String? get name => _prefs.getString(PrefsKeys.printerName);

  PrinterPaperWidth get paperWidth =>
      PrinterPaperWidthX.fromStored(_prefs.getString(PrefsKeys.printerPaperWidth));

  bool get useBle => _prefs.getBool(PrefsKeys.printerUseBle) ?? false;

  bool get hasPairedPrinter {
    final addr = address?.trim() ?? '';
    return addr.isNotEmpty;
  }

  Future<void> save({
    required String address,
    required String name,
    bool? useBle,
    PrinterPaperWidth? paperWidth,
  }) async {
    await _prefs.setString(PrefsKeys.printerAddress, address.trim());
    await _prefs.setString(PrefsKeys.printerName, name.trim());
    if (useBle != null) {
      await _prefs.setBool(PrefsKeys.printerUseBle, useBle);
    }
    if (paperWidth != null) {
      await _prefs.setString(
        PrefsKeys.printerPaperWidth,
        paperWidth.storageValue,
      );
    }
  }

  Future<void> setPaperWidth(PrinterPaperWidth width) async {
    await _prefs.setString(PrefsKeys.printerPaperWidth, width.storageValue);
  }

  Future<void> setUseBle(bool value) async {
    await _prefs.setBool(PrefsKeys.printerUseBle, value);
  }

  Future<void> clear() async {
    await _prefs.remove(PrefsKeys.printerAddress);
    await _prefs.remove(PrefsKeys.printerName);
    await _prefs.remove(PrefsKeys.printerUseBle);
  }
}
