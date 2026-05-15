import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/printing/bluetooth_pos_printer.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/printer_connection_notifier.dart';
import '../../../core/printing/valet_print_service.dart';
import '../../../core/printing/widgets/printer_pairing_sheet.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/presentation/logout_flow.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final printerStatus = context.watch<PrinterConnectionNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Settings', style: CheckInCompactTokens.pageHeading()),
            const SizedBox(height: 16),
            Text('BLUETOOTH PRINTER', style: CheckInCompactTokens.sectionTitle()),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                printerStatus.isConnected ? 'Connected' : 'Not connected',
                style: CheckInCompactTokens.fieldValue(),
              ),
              subtitle: Text(
                printerStatus.statusSubtitle,
                style: CheckInCompactTokens.bodyHint(),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showPrinterPairingSheet(context),
            ),
            if (Platform.isAndroid || Platform.isIOS) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: printerStatus.isConnected
                    ? () async {
                        final auth = context.read<AuthRepository>();
                        final site = await auth.branchAndAreaFromDb();
                        final branch = site.branch.trim().isEmpty
                            ? 'Valet Master'
                            : site.branch;
                        await runBluetoothPrint(
                          context,
                          printJob: () => context
                              .read<ValetPrintService>()
                              .printTestReceipt(branchName: branch),
                        );
                      }
                    : null,
                child: const Text('Print test receipt'),
              ),
              if (printerStatus.hasPairedPrinter && !printerStatus.isConnected)
                TextButton(
                  onPressed: () async {
                    await context
                        .read<BluetoothPosPrinter>()
                        .connectPaired();
                    if (context.mounted) {
                      context.read<PrinterConnectionNotifier>().refresh();
                    }
                  },
                  child: const Text('Reconnect to saved printer'),
                ),
            ] else
              Text(
                'Bluetooth printing is available on Android handheld devices.',
                style: CheckInCompactTokens.bodyHint(),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => showLogoutFlow(context),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
