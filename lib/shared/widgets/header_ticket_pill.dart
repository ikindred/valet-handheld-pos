import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/connectivity/internet_reachability.dart';
import '../../core/theme/app_theme.dart';
import 'unsynced_cloud_icon.dart';

/// Compact ticket badge for flow headers (check-in / check-out).
class HeaderTicketPill extends StatelessWidget {
  const HeaderTicketPill({
    super.key,
    required this.ticketNumber,
    this.showUnsyncedIcon = false,
    this.maxWidth,
  });

  final String ticketNumber;
  final bool showUnsyncedIcon;

  /// When set, truncates with ellipsis. Omit to show the full ticket number.
  final double? maxWidth;

  static const Color _orange = Color(0xFFE87722);
  static const Color _bgLight = Color(0xFFFFF7EC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppThemeColors.of(context).inputFill : _bgLight;
    final display = ticketNumber.trim().isEmpty ? '…' : ticketNumber.trim();

    final text = Text(
      display,
      maxLines: 1,
      overflow: maxWidth != null ? TextOverflow.ellipsis : TextOverflow.clip,
      softWrap: false,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: _orange,
      ),
    );

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showUnsyncedIcon) ...[
            const UnsyncedCloudIcon(size: 12, color: _orange),
            const SizedBox(width: 5),
          ],
          if (maxWidth != null) Flexible(child: text) else text,
        ],
      ),
    );

    if (maxWidth == null) return pill;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: pill,
    );
  }
}

/// Ticket pill that only shows the unsynced cloud while offline.
class HeaderTicketPillLive extends StatefulWidget {
  const HeaderTicketPillLive({
    super.key,
    required this.ticketNumber,
    required this.unsynced,
    this.maxWidth,
  });

  final String ticketNumber;
  final bool unsynced;
  final double? maxWidth;

  @override
  State<HeaderTicketPillLive> createState() => _HeaderTicketPillLiveState();
}

class _HeaderTicketPillLiveState extends State<HeaderTicketPillLive>
    with WidgetsBindingObserver {
  bool? _hasInternet;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refresh());
    });
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final hasInternet = await InternetReachability.hasInternet();
    if (!mounted) return;
    setState(() => _hasInternet = hasInternet);
  }

  @override
  Widget build(BuildContext context) {
    final showCloud = widget.unsynced && _hasInternet == false;
    return HeaderTicketPill(
      ticketNumber: widget.ticketNumber,
      showUnsyncedIcon: showCloud,
      maxWidth: widget.maxWidth,
    );
  }
}
