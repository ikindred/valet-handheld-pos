import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../features/check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../storage/printer_prefs.dart';
import '../../theme/app_theme.dart';
import '../bluetooth_pos_printer.dart';
import '../printer_config.dart';
import '../printer_connection_notifier.dart';
import '../printer_service.dart';
import '../valet_print_service.dart';

/// Scan, pair, and connect to a Bluetooth thermal printer.
Future<bool?> showPrinterPairingSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _PrinterPairingSheet(),
  );
}

class _PrinterPairingSheet extends StatefulWidget {
  const _PrinterPairingSheet();

  @override
  State<_PrinterPairingSheet> createState() => _PrinterPairingSheetState();
}

class _PrinterPairingSheetState extends State<_PrinterPairingSheet> {
  List<PrinterDevice> _devices = [];
  bool _scanning = false;
  String? _error;
  PrinterDevice? _selected;
  PrinterPaperWidth _paperWidth = PrinterPaperWidth.mm58;
  bool _preferBle = false;
  PrinterPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefsAndMaybeScan();
  }

  Future<void> _loadPrefsAndMaybeScan() async {
    final prefs = await PrinterPrefs.load();
    if (!mounted) return;

    PrinterDevice? savedDevice;
    if (prefs.hasPairedPrinter) {
      final addr = prefs.address!.trim();
      final name = prefs.name?.trim();
      savedDevice = PrinterDevice(
        id: addr,
        name: name != null && name.isNotEmpty ? name : addr,
        connection: PrinterConnection.bluetooth,
      );
    }

    setState(() {
      _prefs = prefs;
      _paperWidth = prefs.paperWidth;
      _preferBle = prefs.useBle;
      _selected = savedDevice;
      if (savedDevice != null && !(_devices.any((d) => d.id == savedDevice!.id))) {
        _devices = [savedDevice, ..._devices];
      }
    });

    if (!mounted) return;
    final connected = context.read<PrinterConnectionNotifier>().isConnected;
    if (connected && savedDevice != null) {
      return;
    }
    if (!mounted) return;
    await _scan();
  }

  Future<void> _scan() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _error = 'Bluetooth printing is only available on Android tablets.';
        _scanning = false;
      });
      return;
    }
    setState(() {
      _scanning = true;
      _error = null;
      _devices = [];
    });
    try {
      final list = await context.read<BluetoothPosPrinter>().discoverBluetooth(
            includeBle: true,
          );
      if (!mounted) return;
      setState(() {
        _devices = list;
        _scanning = false;
        if (list.isEmpty) {
          _error =
              'No devices found. Turn on the printer, pair it in system Bluetooth '
              'settings if needed, then tap Scan again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _savePaperWidth(PrinterPaperWidth width) async {
    setState(() => _paperWidth = width);
    final prefs = _prefs ?? await PrinterPrefs.load();
    await prefs.setPaperWidth(width);
    _prefs = prefs;
  }

  Future<void> _savePreferBle(bool value) async {
    setState(() => _preferBle = value);
    final prefs = _prefs ?? await PrinterPrefs.load();
    await prefs.setUseBle(value);
    _prefs = prefs;
  }

  Future<void> _connectSelected() async {
    final device = _selected;
    if (device == null) return;
    setState(() => _scanning = true);
    try {
      await context.read<BluetoothPosPrinter>().connect(
            device,
            useBle: _preferBle,
          );
      if (!mounted) return;
      final notifier = context.read<PrinterConnectionNotifier>();
      await notifier.tryConnectPaired();
      notifier.refresh();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _testPrint() async {
    try {
      final auth = context.read<AuthRepository>();
      final printService = context.read<ValetPrintService>();
      final site = await auth.branchAndAreaFromDb();
      if (!mounted) return;
      final branch = site.branch.trim().isEmpty ? 'Valet Master' : site.branch;
      await printService.printTestReceipt(branchName: branch);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PrinterConnectionNotifier>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SizedBox(
        height: maxSheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bluetooth printer', style: CheckInCompactTokens.pageHeading()),
            const SizedBox(height: 4),
          Text(
            'Any ESC/POS thermal printer (HPRT, Xprinter, Epson-compatible, etc.).',
            style: CheckInCompactTokens.bodyHint(),
          ),
          const SizedBox(height: 4),
          Text(
            'HPRT HM-A300: set printer menu Paper to Receipt (not Label). '
            'App paper: 2 in (58 mm).',
            style: CheckInCompactTokens.helperText(),
          ),
            const SizedBox(height: 4),
            Text(
              notifier.statusSubtitle,
              style: CheckInCompactTokens.bodyHint(),
            ),
            const SizedBox(height: 12),
            Text('Paper width', style: CheckInCompactTokens.sectionTitle()),
            const SizedBox(height: 6),
            SegmentedButton<PrinterPaperWidth>(
              segments: PrinterPaperWidth.values
                  .map(
                    (w) => ButtonSegment(
                      value: w,
                      label: Text(w.label, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              selected: {_paperWidth},
              onSelectionChanged: (s) => _savePaperWidth(s.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Prefer Bluetooth LE',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              subtitle: Text(
                'Enable if your printer only shows up as a BLE device.',
                style: CheckInCompactTokens.helperText(),
              ),
              value: _preferBle,
              onChanged: _savePreferBle,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _scanning ? null : _scan,
                    child: Text(_scanning ? 'Scanning…' : 'Scan'),
                  ),
                ),
                if (notifier.isConnected) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _scanning ? null : _testPrint,
                    child: const Text('Test print'),
                  ),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppColors.error, fontSize: 11),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _scanning && _devices.isEmpty
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final d = _devices[i];
                        final selected = _selected?.id == d.id;
                        return ListTile(
                          dense: true,
                          title: Text(
                            d.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            d.id,
                            style: CheckInCompactTokens.helperText(),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF27AE60),
                                )
                              : null,
                          onTap: () => setState(() => _selected = d),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selected == null || _scanning ? null : _connectSelected,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF68D00),
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

