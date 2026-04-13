import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/printing/valet_print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/ticket_service.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_step_body.dart';

/// After ticket is saved — print stub or skip to dashboard.
class CheckInPrintTicketScreen extends StatelessWidget {
  const CheckInPrintTicketScreen({super.key});

  Future<void> _printTicket(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = context.read<CheckInCubit>().state.ticketNumber.trim();
    if (id.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Missing ticket id.')));
      return;
    }
    final row = await context.read<TicketService>().ticketById(id);
    if (!context.mounted) return;
    if (row == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Ticket not found locally.')));
      return;
    }
    await context.read<ValetPrintService>().printCheckInTicket(row);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text('Ticket $id created')));
    context.read<CheckInCubit>().resetSession();
    if (!context.mounted) return;
    context.go('/dashboard');
  }

  void _leave(BuildContext context) {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CheckInCubit>().state;
    final id = state.ticketNumber.trim();
    final timeFmt = DateFormat('MMM dd, yyyy · hh:mm a');

    return CheckInStepBody(
      scrollable: true,
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _leave(context),
              child: Text(
                'Skip print',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: id.isEmpty ? null : () => _printTicket(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF68D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
              ),
              child: Text(
                'Print ticket',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ticket created',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            id.isEmpty ? '—' : id,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: DashboardStyles.orange,
            ),
          ),
          const SizedBox(height: 24),
          _line('Plate', state.plateNumber.trim().isEmpty ? '—' : state.plateNumber.trim()),
          _line('Brand', state.vehicleBrandMake.trim().isEmpty ? '—' : state.vehicleBrandMake.trim()),
          _line('Color', state.vehicleColor.trim().isEmpty ? '—' : state.vehicleColor.trim()),
          _line(
            'Check-in',
            state.dateTimeIn != null
                ? timeFmt.format(state.dateTimeIn!.toLocal())
                : timeFmt.format(DateTime.now()),
          ),
        ],
      ),
    );
  }

  static Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
