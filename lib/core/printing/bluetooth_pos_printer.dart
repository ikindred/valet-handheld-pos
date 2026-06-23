import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:flutter_pos_printer_platform_image_3/discovery.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart'
    as pos;
import 'package:permission_handler/permission_handler.dart';

import '../logging/valet_log.dart';
import '../storage/printer_prefs.dart';
import 'printer_config.dart';
import 'printer_service.dart';

/// Normalizes Bluetooth MAC addresses for comparison (case/colon agnostic).
bool bluetoothAddressesMatch(String? a, String? b) {
  if (a == null || b == null) return false;
  String norm(String value) =>
      value.trim().toUpperCase().replaceAll(':', '').replaceAll('-', '');
  final left = norm(a);
  final right = norm(b);
  return left.isNotEmpty && left == right;
}

/// Bluetooth ESC/POS printer via [PrinterManager].
///
/// Works with any Bluetooth thermal printer that accepts standard ESC/POS
/// (Epson-compatible) commands — receipt printers, portables (HPRT, Xprinter,
/// Rongta, etc.). Pair in Android/iOS settings first if the device does not
/// appear during scan.
class BluetoothPosPrinter implements PrinterService {
  BluetoothPosPrinter();

  PrinterPrefs? _prefs;
  final pos.PrinterManager _manager = pos.PrinterManager.instance;

  CapabilityProfile? _profile;
  StreamSubscription<pos.BTStatus>? _statusSub;

  /// Address of the printer this app session last connected to via [connect].
  String? _activeConnectionAddress;

  Future<PrinterPrefs> get _prefsAsync async {
    _prefs ??= await PrinterPrefs.load();
    return _prefs!;
  }

  @override
  Future<CapabilityProfile> loadProfile() async {
    _profile ??= await CapabilityProfile.load();
    return _profile!;
  }

  Future<PrinterPaperWidth> get paperWidth async =>
      (await _prefsAsync).paperWidth;

  /// Raw native Bluetooth link (any paired device — may differ from saved prefs).
  bool get hasBluetoothLink =>
      _manager.currentStatusBT == pos.BTStatus.connected;

  /// Back-compat alias; prefer [isConnectedToSavedPrinter] for print/UI gating.
  bool get isConnected => hasBluetoothLink;

  /// True when the active link targets the printer saved in app settings.
  Future<bool> isConnectedToSavedPrinter() async {
    if (!hasBluetoothLink) return false;
    final prefs = await _prefsAsync;
    final saved = prefs.address?.trim();
    if (saved == null || saved.isEmpty) return false;
    final active = _activeConnectionAddress?.trim();
    if (active == null || active.isEmpty) {
      // System Bluetooth may be connected to another printer; not our saved one.
      return false;
    }
    return bluetoothAddressesMatch(active, saved);
  }

  Future<String?> get pairedName async => (await _prefsAsync).name;

  Future<String?> get pairedAddress async => (await _prefsAsync).address;

  void listenConnectionStatus(void Function(bool connected) onChange) {
    _statusSub?.cancel();
    _statusSub = _manager.stateBluetooth.listen((status) {
      onChange(status == pos.BTStatus.connected);
    });
  }

  @override
  Future<void> disconnect() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _manager.disconnect(type: pos.PrinterType.bluetooth);
    _activeConnectionAddress = null;
  }

  @override
  Future<List<PrinterDevice>> discover() => discoverBluetooth();

  /// Discovers classic Bluetooth, BLE, and already-paired Android devices.
  Future<List<PrinterDevice>> discoverBluetooth({
    Duration timeout = const Duration(seconds: 8),
    bool includeBle = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return [];
    await ensureBluetoothPermissions();

    final found = <String, PrinterDevice>{};

    void addFromPos(pos.PrinterDevice d) {
      final addr = d.address?.trim() ?? '';
      if (addr.isEmpty) return;
      found[addr] = PrinterDevice(
        id: addr,
        name: d.name.trim().isEmpty ? addr : d.name.trim(),
        connection: PrinterConnection.bluetooth,
      );
    }

    void addBonded(PrinterDiscovered<pos.BluetoothPrinterDevice> p) {
      final addr = p.detail.address?.trim() ?? '';
      if (addr.isEmpty) return;
      final name = p.name.trim().isEmpty ? addr : p.name.trim();
      found[addr] = PrinterDevice(
        id: addr,
        name: name,
        connection: PrinterConnection.bluetooth,
      );
    }

    if (Platform.isAndroid) {
      for (final isBle in [false, if (includeBle) true]) {
        try {
          final bonded =
              await pos.BluetoothPrinterConnector.discoverPrinters(isBle: isBle);
          for (final p in bonded) {
            addBonded(p);
          }
        } catch (e) {
          ValetLog.debug(
            'BluetoothPosPrinter.discover',
            'bonded list isBle=$isBle failed: $e',
          );
        }
      }
    }

    final subs = <StreamSubscription<pos.PrinterDevice>>[];
    subs.add(
      _manager
          .discovery(type: pos.PrinterType.bluetooth, isBle: false)
          .listen(addFromPos),
    );
    if (includeBle) {
      subs.add(
        _manager
            .discovery(type: pos.PrinterType.bluetooth, isBle: true)
            .listen(addFromPos),
      );
    }

    await Future<void>.delayed(timeout);
    for (final sub in subs) {
      await sub.cancel();
    }

    final list = found.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<void> connect(PrinterDevice device, {bool? useBle}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'Bluetooth printing is only supported on Android/iOS.',
      );
    }
    await ensureBluetoothPermissions();

    final prefs = await _prefsAsync;
    if (hasBluetoothLink &&
        !bluetoothAddressesMatch(_activeConnectionAddress, device.id)) {
      await disconnect();
    }

    final preferBle = useBle ?? prefs.useBle;
    final modes = preferBle ? [true, false] : [false, true];

    for (final isBle in modes) {
      final ok = await _manager.connect(
        type: pos.PrinterType.bluetooth,
        model: pos.BluetoothPrinterInput(
          name: device.name,
          address: device.id,
          isBle: isBle,
          autoConnect: true,
        ),
      );
      if (ok) {
        _activeConnectionAddress = device.id;
        await prefs.save(
          address: device.id,
          name: device.name,
          useBle: isBle,
        );
        _prefs = prefs;
        return;
      }
    }

    throw StateError(
      'Could not connect to ${device.name}. Pair it in system Bluetooth settings, '
      'then try again.',
    );
  }

  /// Connect to the last paired printer from prefs.
  Future<bool> connectPaired() async {
    final prefs = await _prefsAsync;
    final addr = prefs.address?.trim() ?? '';
    if (addr.isEmpty) return false;

    if (await isConnectedToSavedPrinter()) return true;

    if (hasBluetoothLink) {
      await disconnect();
    }

    try {
      await connect(
        PrinterDevice(
          id: addr,
          name: prefs.name?.trim().isNotEmpty == true
              ? prefs.name!.trim()
              : addr,
          connection: PrinterConnection.bluetooth,
        ),
        useBle: prefs.useBle,
      );
      return await waitUntilConnectedToSaved();
    } catch (e, st) {
      ValetLog.error('BluetoothPosPrinter.connectPaired', 'failed', e, st);
      return false;
    }
  }

  /// Waits until connected to the saved printer or [timeout] elapses.
  Future<bool> waitUntilConnectedToSaved({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (await isConnectedToSavedPrinter()) return true;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await isConnectedToSavedPrinter()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return isConnectedToSavedPrinter();
  }

  /// Waits until [hasBluetoothLink] or [timeout] elapses.
  Future<bool> waitUntilConnected({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (hasBluetoothLink) return true;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (hasBluetoothLink) return true;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return hasBluetoothLink;
  }

  /// Ensures a connection to the saved printer before sending bytes.
  Future<void> ensureConnected() async {
    if (await isConnectedToSavedPrinter()) return;

    if (hasBluetoothLink) {
      await disconnect();
    }

    if ((await _prefsAsync).hasPairedPrinter) {
      final ok = await connectPaired();
      if (ok && await isConnectedToSavedPrinter()) return;
    }
    throw StateError(
      'No Bluetooth printer connected. Pair a printer in Settings.',
    );
  }

  @override
  Future<void> printBytes(List<int> bytes) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'Bluetooth printing is only supported on Android/iOS.',
      );
    }
    await ensureConnected();

    if (Platform.isAndroid &&
        _manager.currentStatusBT != pos.BTStatus.connected) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    final sent = await _manager.send(
      type: pos.PrinterType.bluetooth,
      bytes: bytes,
    );
    if (!sent) {
      throw StateError('Printer did not accept the print job.');
    }
  }

  void dispose() {
    _statusSub?.cancel();
  }
}

/// Android 12+ Bluetooth scan/connect + legacy location for discovery.
Future<void> ensureBluetoothPermissions() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

  final toRequest = <Permission>[
    if (Platform.isAndroid) ...[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ],
  ];

  if (toRequest.isEmpty) return;
  final statuses = await toRequest.request();
  final denied = statuses.entries
      .where((e) => e.value.isDenied || e.value.isPermanentlyDenied);
  if (denied.isNotEmpty) {
    ValetLog.debug(
      'ensureBluetoothPermissions',
      'some permissions denied: ${denied.map((e) => e.key).join(", ")}',
    );
  }
}
