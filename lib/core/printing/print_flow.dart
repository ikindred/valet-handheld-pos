import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import 'bluetooth_pos_printer.dart';
import 'check_in_receipt_data.dart';
import 'printer_connection_notifier.dart';
import 'valet_print_service.dart';
import 'widgets/printer_pairing_sheet.dart';

/// Pair if needed, then run a print job. Returns false when cancelled or failed.
Future<bool> runBluetoothPrint(
  BuildContext context, {
  required Future<void> Function() printJob,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    _snack(context, 'Bluetooth printing is only supported on Android tablets.');
    return false;
  }

  final notifier = context.read<PrinterConnectionNotifier>();
  if (!notifier.isConnected) {
    final paired = await showPrinterPairingSheet(context);
    if (paired != true || !context.mounted) return false;
  } else {
    await context.read<BluetoothPosPrinter>().ensureConnected();
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
      await showPrinterPairingSheet(context);
    }
    return false;
  }
}

Future<bool> printCheckInFromContext(
  BuildContext context, {
  required CheckInReceiptData data,
}) {
  return runBluetoothPrint(
    context,
    printJob: () => context.read<ValetPrintService>().printCheckIn(data),
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
      : (area.isEmpty ? branch : '$branch · $area');
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
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
