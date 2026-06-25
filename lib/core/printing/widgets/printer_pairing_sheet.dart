import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../features/check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../storage/printer_prefs.dart';
import '../../theme/app_theme.dart';
import '../bluetooth_pos_printer.dart';
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
              'No printers found. Make sure the printer is on and paired in your '
              "device's Bluetooth settings, then tap Scan again.";
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

  Future<void> _connectSelected() async {
    final device = _selected;
    if (device == null) return;
    setState(() => _scanning = true);
    try {
      await context.read<BluetoothPosPrinter>().connect(device);
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
    final theme = AppThemeColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SizedBox(
        height: maxSheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Bluetooth printer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                _PrinterStatusChip(notifier: notifier),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Connect a thermal receipt printer to print valet tickets.',
              style: CheckInCompactTokens.bodyHintOf(context),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: theme.hintFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How to connect',
                    style: CheckInCompactTokens.sectionTitleOf(context),
                  ),
                  const SizedBox(height: 8),
                  const _SetupStep(
                    number: 1,
                    text: 'Turn on the printer and keep it nearby.',
                  ),
                  const SizedBox(height: 6),
                  const _SetupStep(
                    number: 2,
                    text: 'Tap Scan, then select your printer from the list.',
                  ),
                  const SizedBox(height: 6),
                  const _SetupStep(
                    number: 3,
                    text: 'Tap Connect. Use Test print to confirm it works.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Works with HPRT, Xprinter, Epson-compatible, and similar models. '
              'Paper: 80 mm (3 in). HPRT HM-A300 owners: set printer Paper to Receipt.',
              style: CheckInCompactTokens.helperText(),
            ),
            const SizedBox(height: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
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

class _PrinterStatusChip extends StatelessWidget {
  const _PrinterStatusChip({required this.notifier});

  final PrinterConnectionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeColors.of(context);
    final String label;
    final Color bg;
    final Color fg;
    final IconData icon;

    if (notifier.isConnected) {
      label = 'Connected';
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (notifier.hasPairedPrinter) {
      label = 'Saved';
      bg = AppColors.warning.withValues(alpha: 0.14);
      fg = const Color(0xFFB87A00);
      icon = Icons.bluetooth_connected_rounded;
    } else {
      label = 'Not connected';
      bg = theme.chipBg;
      fg = theme.textSecondary;
      icon = Icons.bluetooth_disabled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF68D00).withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF68D00),
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: theme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

