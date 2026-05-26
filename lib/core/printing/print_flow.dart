import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import 'bluetooth_pos_printer.dart';
import 'check_in_receipt_data.dart';
import 'checkout_receipt_data.dart';
import 'printer_connection_notifier.dart';
import 'valet_print_service.dart';
import 'widgets/printer_pairing_sheet.dart';

/// Uses the saved printer when paired; opens the pairing sheet only on first setup.
Future<bool> runBluetoothPrint(
  BuildContext context, {
  required Future<void> Function() printJob,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    _snack(context, 'Bluetooth printing is only supported on Android tablets.');
    return false;
  }

  if (!await _ensurePrinterReady(context)) {
    return false;
  }

  try {
    await printJob();
    if (context.mounted) {
      _snack(context, 'Sent to printer.');
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      _snack(context, 'Print failed: $e');
    }
    return false;
  }
}

/// Reconnects to the default printer saved in Settings.
///
/// The pairing sheet is shown only when no printer has been saved yet.
Future<bool> _ensurePrinterReady(BuildContext context) async {
  final notifier = context.read<PrinterConnectionNotifier>();
  final printer = context.read<BluetoothPosPrinter>();

  if (!notifier.hasPairedPrinter) {
    if (!context.mounted) return false;
    final paired = await showPrinterPairingSheet(context);
    if (paired != true || !context.mounted) return false;
    notifier.refresh();
    return printer.isConnected;
  }

  if (!printer.isConnected) {
    await notifier.tryConnectPaired();
  }

  if (printer.isConnected) {
    return true;
  }

  if (context.mounted) {
    _snack(
      context,
      'Could not reach ${notifier.pairedDisplayName ?? 'your printer'}. '
      'Open Settings → Bluetooth printer to reconnect.',
    );
  }
  return false;
}

/// Prints all three receipt parts in order (Step 5 review preview — unchanged UX).
Future<bool> printCheckInFromContext(
  BuildContext context, {
  required CheckInReceiptData data,
}) {
  return runBluetoothPrint(
    context,
    printJob: () async {
      final service = context.read<ValetPrintService>();
      for (var part = 1; part <= 3; part++) {
        await service.printCheckIn(data, part: part);
      }
    },
  );
}

/// Prints checkout payment receipt (Step 5).
Future<bool> printCheckOutFromContext(
  BuildContext context, {
  required CheckoutReceiptData data,
}) {
  return runBluetoothPrint(
    context,
    printJob: () =>
        context.read<ValetPrintService>().printCheckOut(data),
  );
}

/// Prints a single receipt part (Step 6 sequential tear-off flow).
Future<bool> printCheckInPartFromContext(
  BuildContext context, {
  required CheckInReceiptData data,
  required int part,
}) {
  return runBluetoothPrint(
    context,
    printJob: () =>
        context.read<ValetPrintService>().printCheckIn(data, part: part),
  );
}

/// Builds [CheckInReceiptData] with branch name from [AuthRepository].
Future<CheckInReceiptData> withBranchName(
  AuthRepository auth,
  CheckInReceiptData data,
) async {
  final site = await auth.branchAndAreaFromDb();
  final branch = site.branch.trim();
  final area = site.area.trim();
  final label = branch.isEmpty && area.isEmpty
      ? 'Valet Master'
      : (area.isEmpty ? branch : '$branch / $area');
  return CheckInReceiptData(
    ticket: data.ticket,
    branchName: label,
    customerName: data.customerName,
    contactNumber: data.contactNumber,
    parkingLevel: data.parkingLevel,
    parkingSlot: data.parkingSlot,
    valetTypeLabel: data.valetTypeLabel,
    specialRequest: data.specialRequest,
    hasSignature: data.hasSignature,
    qrCode: data.qrCode,
    mallHours: data.mallHours,
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
