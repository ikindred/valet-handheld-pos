import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/parking_layout_service.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import 'area_detail_dialog_data.dart';
import 'branch_rates_dialog.dart';

/// Loads area detail from the API on every mount; supports retry.
class AreaDialogLoader extends StatefulWidget {
  const AreaDialogLoader({
    super.key,
    required this.authRepository,
    required this.rateFetchService,
    required this.rateService,
    required this.parkingLayoutService,
    required this.allowOfflineFallback,
    this.purpose = BranchAreaDialogPurpose.rates,
    required this.builder,
  });

  final AuthRepository authRepository;
  final RateFetchService rateFetchService;
  final RateService rateService;
  final ParkingLayoutService parkingLayoutService;
  final bool allowOfflineFallback;
  final BranchAreaDialogPurpose purpose;
  final Widget Function(
    BuildContext context,
    BranchAreaLoadResult result,
    VoidCallback retry,
  ) builder;

  @override
  State<AreaDialogLoader> createState() => _AreaDialogLoaderState();
}

class _AreaDialogLoaderState extends State<AreaDialogLoader> {
  late Future<BranchAreaLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _fetch();
  }

  Future<BranchAreaLoadResult> _fetch() => refreshBranchAreaDialogData(
        authRepository: widget.authRepository,
        rateFetchService: widget.rateFetchService,
        rateService: widget.rateService,
        parkingLayoutService: widget.parkingLayoutService,
        purpose: widget.purpose,
        allowOfflineFallback: widget.allowOfflineFallback,
      );

  void _retry() => setState(() => _loadFuture = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BranchAreaLoadResult>(
      future: _loadFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final result = snap.data ??
            const BranchAreaLoadResult(
              errorMessage: 'Could not load area data.',
            );
        return widget.builder(context, result, _retry);
      },
    );
  }
}

/// Error + retry row for area dialogs.
class AreaDialogErrorBody extends StatelessWidget {
  const AreaDialogErrorBody({
    super.key,
    required this.title,
    required this.branchName,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String branchName;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: branchRatesDialogTitleStyle()),
        const SizedBox(height: 2),
        Text(branchName, style: branchRatesDialogSubtitleStyle()),
        const SizedBox(height: 12),
        Text(message, style: branchRatesDialogSubtitleStyle()),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: branchRatesDialogCloseStyle()),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: branchRatesDialogCloseStyle()),
            ),
          ],
        ),
      ],
    );
  }
}
