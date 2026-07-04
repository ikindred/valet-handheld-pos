import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/formatting/plate_number.dart';
import '../../../core/formatting/vr_number.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/unsynced_cloud_icon.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/printing/express_checkout_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/printer_connection_notifier.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';
import '../../../shared/widgets/cashier_greeting_header.dart';
import '../../auth/state/auth_bloc.dart';
import '../../cash/presentation/widgets/cash_figma_text_styles.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../sync/state/sync_cubit.dart';
import '../../sync/state/sync_state.dart';
import '../domain/express_cashier_demo_defaults.dart';
import '../state/express_cashier_cubit.dart';
import '../state/express_cashier_state.dart';
import 'widgets/express_transaction_detail_dialog.dart';

/// Adaptive palette aligned with [DashboardStyles] / [AppThemeColors].
final class _ExpressTheme {
  const _ExpressTheme._({
    required this.orange,
    required this.plateBlue,
    required this.plateBadgeBg,
    required this.headerBg,
    required this.rowAltBg,
    required this.rowDivider,
    required this.cardDecoration,
    required this.cardBorder,
    required this.tableSurfaceBg,
    required this.amountFieldBg,
    required this.bottomBarBg,
    required this.shadowColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color orange;
  final Color plateBlue;
  final Color plateBadgeBg;
  final Color headerBg;
  final Color rowAltBg;
  final Color rowDivider;
  final BoxDecoration cardDecoration;
  final Color cardBorder;
  final Color tableSurfaceBg;
  final Color amountFieldBg;
  final Color bottomBarBg;
  final Color shadowColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  static _ExpressTheme of(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isDark = AppThemeColors.isDark(context);
    return _ExpressTheme._(
      orange: DashboardStyles.orange,
      plateBlue: DashboardStyles.plateBlue,
      plateBadgeBg: tc.plateBadgeBg,
      headerBg: tc.hintFill,
      rowAltBg: tc.checkboxFill,
      rowDivider: tc.divider,
      cardDecoration: DashboardStyles.cardDecorationOf(context),
      cardBorder: tc.cardBorder,
      tableSurfaceBg: tc.cardBg,
      amountFieldBg: tc.accentSurface,
      bottomBarBg: tc.cardBg,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.04),
      textPrimary: tc.textPrimary,
      textSecondary: tc.textSecondary,
      textMuted: tc.textSubtitleMuted,
    );
  }

  BoxDecoration card({double radius = 12}) => cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  TextStyle sectionCaps() => CashFigmaStyles.sectionCaps().copyWith(
        color: textSecondary,
        fontSize: 10,
        letterSpacing: 0.5,
      );

  TextStyle fieldLabel() =>
      CashFigmaStyles.fieldLabel().copyWith(color: textSecondary);

  TextStyle fieldValue() =>
      CashFigmaStyles.fieldValue().copyWith(color: textPrimary);

  TextStyle notesHint() => CashFigmaStyles.notesHint().copyWith(color: textMuted);

  TextStyle tableHeader() => fieldLabel().copyWith(
        fontSize: 9,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
      );
}

class ExpressCashierScreen extends StatefulWidget {
  const ExpressCashierScreen({super.key});

  @override
  State<ExpressCashierScreen> createState() => _ExpressCashierScreenState();
}

class _ExpressCashierScreenState extends State<ExpressCashierScreen> {
  final _plateCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();
  final _vrCtrl = TextEditingController();
  final _driverInCtrl = TextEditingController();
  final _driverOutCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _plateFocus = FocusNode();
  final _ticketFocus = FocusNode();
  final _vrFocus = FocusNode();
  final _driverInFocus = FocusNode();
  final _driverOutFocus = FocusNode();
  final _amountFocus = FocusNode();

  String _firstName = '';
  String _headerSubtitle = '';
  bool _printAfterSave = false;
  bool _isPrinting = false;

  static const _inputPaneKey = ValueKey('express-input-pane');

  static final _pesoFmt =
      PesoCurrency.currency(decimalDigits: 2, spaceAfter: true);

  /// Poppins lacks U+20B1; bundled Noto Sans (Regular/Bold only) renders ₱.
  TextStyle _pesoMoneyStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontFamily: 'Noto Sans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.25,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    for (final ctrl in [
      _plateCtrl,
      _ticketCtrl,
      _vrCtrl,
      _driverInCtrl,
      _driverOutCtrl,
      _amountCtrl,
    ]) {
      ctrl.addListener(_onFormChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadHeader();
      _loadTransactions();
      await _assignAutoTicketNumber();
      _applyDemoDefaults();
      if (!mounted) return;
      context.read<PrinterConnectionNotifier>().refresh();
    });
  }

  void _setControllerText(TextEditingController ctrl, String text) {
    ctrl.removeListener(_onFormChanged);
    ctrl.text = text;
    ctrl.addListener(_onFormChanged);
  }

  void _applyDemoDefaults() {
    if (!ExpressCashierDemoDefaults.enabled) return;
    _setControllerText(_plateCtrl, ExpressCashierDemoDefaults.plateNumber);
    _setControllerText(_vrCtrl, ExpressCashierDemoDefaults.uniqueVrNo());
    _setControllerText(_driverInCtrl, ExpressCashierDemoDefaults.driverIn);
    _setControllerText(_driverOutCtrl, ExpressCashierDemoDefaults.driverOut);
    _setControllerText(_amountCtrl, ExpressCashierDemoDefaults.amountText);
    if (mounted) setState(() {});
  }

  Future<void> _assignAutoTicketNumber() async {
    final id = await context.read<TicketService>().generateTicketId('');
    if (!mounted) return;
    _ticketCtrl.removeListener(_onFormChanged);
    _ticketCtrl.text = id;
    _ticketCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFormComplete {
    final plate = normalizePlateNumber(_plateCtrl.text);
    final ticket = _ticketCtrl.text.trim();
    final vr = _vrCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    return plate.isNotEmpty &&
        ticket.isNotEmpty &&
        vr.isNotEmpty &&
        amount > 0;
  }

  String? _validateForm() {
    final plate = normalizePlateNumber(_plateCtrl.text);
    if (plate.isEmpty) {
      _plateFocus.requestFocus();
      return 'Enter a plate number.';
    }
    if (_ticketCtrl.text.trim().isEmpty) {
      _ticketFocus.requestFocus();
      return 'Enter a ticket number.';
    }
    if (_vrCtrl.text.trim().isEmpty) {
      _vrFocus.requestFocus();
      return 'Enter a VR number.';
    }
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    if (amount <= 0) {
      _amountFocus.requestFocus();
      return 'Enter a valid amount.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final node in [
      _plateFocus,
      _ticketFocus,
      _vrFocus,
      _driverInFocus,
      _driverOutFocus,
      _amountFocus,
    ]) {
      node.dispose();
    }
    for (final ctrl in [
      _plateCtrl,
      _ticketCtrl,
      _vrCtrl,
      _driverInCtrl,
      _driverOutCtrl,
      _amountCtrl,
    ]) {
      ctrl.removeListener(_onFormChanged);
    }
    _plateCtrl.dispose();
    _ticketCtrl.dispose();
    _vrCtrl.dispose();
    _driverInCtrl.dispose();
    _driverOutCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  int? get _localUserId {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || auth.userId == null) return null;
    return int.tryParse(auth.userId!);
  }

  Future<void> _loadHeader() async {
    final auth = context.read<AuthBloc>().state;
    final repo = context.read<AuthRepository>();
    var firstName = '';
    final prefs = await SharedPreferences.getInstance();
    final dateLine = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final siteSub = await repo.dateAndSiteLine(prefs, dateLine);
    if (auth is AuthAuthenticated && auth.userId != null) {
      final id = int.tryParse(auth.userId!);
      if (id != null) {
        final acct = await repo.offlineAccountById(id);
        if (acct != null) {
          firstName = _firstNameFromFullName(acct.fullName);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _firstName = firstName;
      _headerSubtitle = siteSub;
    });
  }

  String get _greetingTitle {
    final name = _firstName.isEmpty ? '…' : _firstName;
    return '${DashboardScreen.greetingWord()}, $name';
  }

  String get _expressHeaderSubtitle {
    final site = _headerSubtitle.isEmpty ? '— : —' : _headerSubtitle;
    return 'Express Cashier · $site';
  }

  void _loadTransactions() {
    final id = _localUserId;
    if (id == null) return;
    context.read<ExpressCashierCubit>().loadTransactions(id);
  }

  Future<void> _openTransactionDetail(ExpressCashierTransaction tx) async {
    final userId = _localUserId;
    if (userId == null || !mounted) return;

    final cubit = context.read<ExpressCashierCubit>();
    final messenger = ScaffoldMessenger.of(context);

    if (!context.mounted) return;
    await showExpressTransactionDetailDialog(
      context: context,
      transaction: tx,
      formatPlateDisplay: _formatPlateDisplay,
      formatAmount: _formatAmount,
      onVoid: (reason) async {
        try {
          final result = await cubit.voidTransaction(
            localUserId: userId,
            ticketId: tx.ticketId,
            reason: reason,
          );
          if (!mounted) return;
          final message = switch (result) {
            ExpressVoidResult.applied => 'Transaction voided on server.',
            ExpressVoidResult.queuedForSync =>
              'Void queued — will sync to server when online.',
          };
          messenger.showSnackBar(SnackBar(content: Text(message)));
        } on TransactionsApiException catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(e.message)),
          );
          rethrow;
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Could not void transaction: $e')),
          );
          rethrow;
        }
      },
    );
  }

  Future<void> _clearForm() async {
    _plateCtrl.clear();
    _vrCtrl.clear();
    _driverInCtrl.clear();
    _driverOutCtrl.clear();
    _amountCtrl.clear();
    await _assignAutoTicketNumber();
    _applyDemoDefaults();
  }

  Future<void> _save() async {
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final id = _localUserId;
    if (id == null) return;
    await context.read<ExpressCashierCubit>().save(
          localUserId: id,
          plateNumber: _plateCtrl.text,
          ticketNumber: _ticketCtrl.text,
          amountText: _amountCtrl.text,
          vrNo: normalizeVrNumber(_vrCtrl.text),
          driverIn: _driverInCtrl.text,
          driverOut: _driverOutCtrl.text,
        );
  }

  Future<void> _saveAndPrint() async {
    _printAfterSave = true;
    await _save();
  }

  Future<void> _printExpressReceipt(String ticketId) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final ticketService = context.read<TicketService>();
      final auth = context.read<AuthRepository>();
      final ticket = await ticketService.ticketById(ticketId);
      if (!mounted) return;
      if (ticket == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket not found for printing.')),
        );
        return;
      }

      final amount = ticket.fee ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No amount on file for this ticket.')),
        );
        return;
      }

      final site = await auth.branchAndAreaFromDb();
      if (!mounted) return;
      final branch = site.branch.trim();
      final area = site.area.trim();
      final branchLabel = branch.isEmpty && area.isEmpty
          ? null
          : (area.isEmpty ? branch : '$branch · $area');

      final data = ExpressCheckoutReceiptData.fromTicket(
        ticket: ticket,
        branchDisplayName: branchLabel,
      );
      if (!mounted) return;
      await printExpressCheckOutFromContext(context, data: data);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  String _formatPlateDisplay(String raw) {
    final normalized = normalizePlateNumber(raw).toUpperCase();
    if (normalized.length <= 3) return normalized;
    return '${normalized.substring(0, 3)} ${normalized.substring(3)}';
  }

  String _formatAmount(double amount) {
    return _pesoFmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncCubit, SyncState>(
      listenWhen: (_, current) => current is SyncComplete,
      listener: (context, state) {
        final id = _localUserId;
        if (id == null) return;
        context.read<ExpressCashierCubit>().reloadTransactionsFromDb(id);
      },
      child: BlocConsumer<ExpressCashierCubit, ExpressCashierState>(
      listener: (context, state) async {
        if (state is ExpressCashierSaved) {
          final shouldPrint = _printAfterSave;
          _printAfterSave = false;
          final ticketId = state.ticketId;
          await _clearForm();
          context.read<ExpressCashierCubit>().restoreLoadedAfterSave(
                state.transactions,
              );
          if (shouldPrint) {
            await _printExpressReceipt(ticketId);
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved $ticketId')),
          );
        }
        if (state is ExpressCashierError) {
          _printAfterSave = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          final id = _localUserId;
          if (id != null) {
            context.read<ExpressCashierCubit>().loadTransactions(id);
          }
        }
      },
      builder: (context, state) {
        final transactions = switch (state) {
          ExpressCashierLoaded(:final transactions) => transactions,
          ExpressCashierSaved(:final transactions) => transactions,
          _ => const <ExpressCashierTransaction>[],
        };
        final isSaving =
            state is ExpressCashierLoaded && state.isSaving;
        // Keep input layout stable while the keyboard is open — toggling
        // compact mode on IME show/hide was rebuilding fields and dismissing focus.
        final compact = MediaQuery.sizeOf(context).height < 640;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppThemeColors.of(context).scaffoldBg,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ExpressCashierLeftRail(),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: CashierGreetingHeader(
                          title: _greetingTitle,
                          subtitle: _expressHeaderSubtitle,
                          showRates: false,
                          showSlots: false,
                        ),
                      ),
                      Expanded(
                        child: state is ExpressCashierLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: SingleChildScrollView(
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        child: _InputPane(
                                          key: _inputPaneKey,
                                          plateCtrl: _plateCtrl,
                                          ticketCtrl: _ticketCtrl,
                                          vrCtrl: _vrCtrl,
                                          driverInCtrl: _driverInCtrl,
                                          driverOutCtrl: _driverOutCtrl,
                                          amountCtrl: _amountCtrl,
                                          plateFocus: _plateFocus,
                                          ticketFocus: _ticketFocus,
                                          vrFocus: _vrFocus,
                                          driverInFocus: _driverInFocus,
                                          driverOutFocus: _driverOutFocus,
                                          amountFocus: _amountFocus,
                                          pesoMoneyStyle: _pesoMoneyStyle,
                                          compact: compact,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 7,
                                      child: _TransactionsPane(
                                        transactions: transactions,
                                        formatPlateDisplay:
                                            _formatPlateDisplay,
                                        formatAmount: _formatAmount,
                                        pesoMoneyStyle: _pesoMoneyStyle,
                                        onTransactionTap: _openTransactionDetail,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      _BottomBar(
                        isSaving: isSaving,
                        isPrinting: _isPrinting,
                        canSave: _isFormComplete,
                        onCancel: _clearForm,
                        onSave: _save,
                        onSaveAndPrint: _saveAndPrint,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }
}
class _InputPane extends StatelessWidget {
  const _InputPane({
    super.key,
    required this.plateCtrl,
    required this.ticketCtrl,
    required this.vrCtrl,
    required this.driverInCtrl,
    required this.driverOutCtrl,
    required this.amountCtrl,
    required this.plateFocus,
    required this.ticketFocus,
    required this.vrFocus,
    required this.driverInFocus,
    required this.driverOutFocus,
    required this.amountFocus,
    required this.pesoMoneyStyle,
    this.compact = false,
  });

  final TextEditingController plateCtrl;
  final TextEditingController ticketCtrl;
  final TextEditingController vrCtrl;
  final TextEditingController driverInCtrl;
  final TextEditingController driverOutCtrl;
  final TextEditingController amountCtrl;
  final FocusNode plateFocus;
  final FocusNode ticketFocus;
  final FocusNode vrFocus;
  final FocusNode driverInFocus;
  final FocusNode driverOutFocus;
  final FocusNode amountFocus;
  final TextStyle Function({
    double fontSize,
    FontWeight fontWeight,
    Color color,
  }) pesoMoneyStyle;
  final bool compact;

  static const _fieldMinHeight = 40.0;
  static const _fieldMinHeightCompact = 36.0;

  double get _fieldHeight =>
      compact ? _fieldMinHeightCompact : _fieldMinHeight;

  @override
  Widget build(BuildContext context) {
    final theme = _ExpressTheme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 14, 16, compact ? 10 : 14),
      decoration: theme.card(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.car,
                size: 14,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'VEHICLE IDENTIFICATION',
                style: theme.sectionCaps(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('PLATE NUMBER', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          AppTextField(
            controller: plateCtrl,
            focusNode: plateFocus,
            hint: 'ABC 1234',
            minHeight: _fieldHeight,
            style: GoogleFonts.poppins(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w600,
              color: theme.orange,
              letterSpacing: 1.2,
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          if (!compact) ...[
            const SizedBox(height: 2),
            Text(
              'Philippine format — 3 letters + 4 digits',
              style: theme.notesHint().copyWith(fontSize: 10),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          Text('TICKET NUMBER', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          AppTextField(
            controller: ticketCtrl,
            focusNode: ticketFocus,
            hint: 'TKT-260623-A1B2-143052',
            minHeight: _fieldHeight,
            style: theme.fieldValue(),
          ),
          if (!compact) ...[
            const SizedBox(height: 2),
            Text(
              'Auto-generated — tap to edit',
              style: theme.notesHint().copyWith(fontSize: 10),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          Text('VR NO.', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          AppTextField(
            controller: vrCtrl,
            focusNode: vrFocus,
            hint: 'e.g. VR-12345',
            minHeight: _fieldHeight,
            style: theme.fieldValue(),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text('DRIVER IN (OPTIONAL)', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          AppTextField(
            controller: driverInCtrl,
            focusNode: driverInFocus,
            hint: 'Carlos Mendoza',
            minHeight: _fieldHeight,
            style: theme.fieldValue(),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: compact ? 8 : 12),
          Text('DRIVER OUT (OPTIONAL)', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          AppTextField(
            controller: driverOutCtrl,
            focusNode: driverOutFocus,
            hint: 'Pedro Santos',
            minHeight: _fieldHeight,
            style: theme.fieldValue(),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: compact ? 8 : 12),
          Text('AMOUNT', style: theme.fieldLabel()),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.amountFieldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.orange.withValues(alpha: 0.55)),
            ),
            child: AppTextField(
              controller: amountCtrl,
              focusNode: amountFocus,
              hint: '150.00',
              minHeight: compact ? _fieldMinHeightCompact + 4 : _fieldMinHeight + 4,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: pesoMoneyStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: theme.orange,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Text(
                    PesoCurrency.symbol,
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: theme.orange.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _TransactionsPane extends StatefulWidget {
  const _TransactionsPane({
    required this.transactions,
    required this.formatPlateDisplay,
    required this.formatAmount,
    required this.pesoMoneyStyle,
    required this.onTransactionTap,
  });

  final List<ExpressCashierTransaction> transactions;
  final String Function(String) formatPlateDisplay;
  final String Function(double) formatAmount;
  final TextStyle Function({
    double fontSize,
    FontWeight fontWeight,
    Color color,
  }) pesoMoneyStyle;
  final ValueChanged<ExpressCashierTransaction> onTransactionTap;

  @override
  State<_TransactionsPane> createState() => _TransactionsPaneState();
}

class _TransactionsPaneState extends State<_TransactionsPane> {
  static const _colGap = 10.0;
  static const _ticketFlex = 5;
  static const _plateFlex = 2;
  static const _vrFlex = 2;
  static const _amountFlex = 2;

  var _showClosedCash = true;

  /// Current-shift total: excludes voided rows and rows already counted in a
  /// prior close-cash session (`included_in_close_cash`).
  double get _shiftTotal => widget.transactions
      .where((tx) => !tx.isVoided && !tx.includedInCloseCash)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  /// Current-shift ticket count: same exclusions as [_shiftTotal].
  int get _activeTicketCount => widget.transactions
      .where((tx) => !tx.isVoided && !tx.includedInCloseCash)
      .length;

  /// How many rows were already counted in a prior close-cash session.
  int get _closedCashCount =>
      widget.transactions.where((tx) => tx.includedInCloseCash).length;

  List<ExpressCashierTransaction> get _visibleTransactions {
    if (_showClosedCash) return widget.transactions;
    return widget.transactions
        .where((tx) => !tx.includedInCloseCash)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _ExpressTheme.of(context);
    final visible = _visibleTransactions;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: theme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.scrollText,
                size: 14,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.transactions.isEmpty
                      ? 'TRANSACTIONS'
                      : 'TRANSACTIONS · $_activeTicketCount',
                  style: theme.sectionCaps(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_closedCashCount > 0) ...[
                const SizedBox(width: 8),
                _ClosedCashVisibilityControl(
                  theme: theme,
                  count: _closedCashCount,
                  showClosedCash: _showClosedCash,
                  onToggle: (value) => setState(() => _showClosedCash = value),
                ),
              ],
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Refresh',
                icon: LucideIcons.refreshCw,
                onPressed: () {
                  final auth = context.read<AuthBloc>().state;
                  if (auth is AuthAuthenticated && auth.userId != null) {
                    final id = int.tryParse(auth.userId!);
                    if (id != null) {
                      context.read<ExpressCashierCubit>().loadTransactions(id);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visible.isEmpty
                ? _EmptyTransactions(
                    message: widget.transactions.isNotEmpty &&
                            !_showClosedCash
                        ? 'Closed cash transactions hidden'
                        : null,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: theme.tableSurfaceBg,
                      border: Border.all(color: theme.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: theme.headerBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _TransactionTableHeader(theme: theme),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.rowDivider,
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: theme.tableSurfaceBg,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: theme.rowDivider,
                              ),
                              itemBuilder: (context, index) {
                                final tx = visible[index];
                                return Material(
                                  color: index.isEven
                                      ? theme.tableSurfaceBg
                                      : theme.rowAltBg,
                                  child: InkWell(
                                    onTap: () => widget.onTransactionTap(tx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      child: _TransactionTableRow(
                                        theme: theme,
                                        ticketId: tx.ticketId,
                                        plateLabel:
                                            widget.formatPlateDisplay(
                                          tx.plateNumber,
                                        ),
                                        vrNo: tx.vrNo?.trim().isNotEmpty == true
                                            ? tx.vrNo!.trim()
                                            : '—',
                                        vrNoMissing:
                                            tx.vrNo?.trim().isNotEmpty != true,
                                        amountLabel:
                                            widget.formatAmount(tx.amount),
                                        isSynced: tx.isSynced,
                                        isVoided: tx.isVoided,
                                        includedInCloseCash: tx.includedInCloseCash,
                                        pesoMoneyStyle: widget.pesoMoneyStyle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.rowDivider,
                        ),
                        Container(
                          color: theme.headerBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$_activeTicketCount ticket${_activeTicketCount == 1 ? '' : 's'}',
                                style: theme.fieldLabel(),
                              ),
                              const Spacer(),
                              Text(
                                'Shift total',
                                style: theme.fieldLabel(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.formatAmount(_shiftTotal),
                                style: widget.pesoMoneyStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = _ExpressTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.headerBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 16, color: theme.textSecondary),
          ),
        ),
      ),
    );
  }
}
class _ClosedCashVisibilityControl extends StatelessWidget {
  const _ClosedCashVisibilityControl({
    required this.theme,
    required this.count,
    required this.showClosedCash,
    required this.onToggle,
  });

  final _ExpressTheme theme;
  final int count;
  final bool showClosedCash;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final visible = showClosedCash;
    final accent = visible ? theme.orange : theme.textSecondary;

    return Tooltip(
      message: visible
          ? 'Hide $count prior close-cash transaction${count == 1 ? '' : 's'}'
          : 'Show $count prior close-cash transaction${count == 1 ? '' : 's'}',
      child: Material(
        color: visible
            ? theme.orange.withValues(alpha: 0.08)
            : theme.headerBg,
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onToggle(!visible),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: visible
                    ? theme.orange.withValues(alpha: 0.4)
                    : theme.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.lock, size: 12, color: accent),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count closed',
                      style: theme.fieldLabel().copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: visible
                                ? theme.textPrimary
                                : theme.textSecondary,
                          ),
                    ),
                    Text(
                      visible ? 'Showing' : 'Hidden',
                      style: theme.fieldLabel().copyWith(
                            fontSize: 9,
                            height: 1.1,
                            color: accent,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  visible ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 14,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = _ExpressTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.inbox,
            size: 32,
            color: theme.textSecondary.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            message ?? 'No transactions yet this shift.',
            style: theme.notesHint(),
            textAlign: TextAlign.center,
          ),
          if (message == null) ...[
            const SizedBox(height: 4),
            Text(
              'Saved tickets will appear here.',
              style: theme.notesHint().copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
class _TransactionTableHeader extends StatelessWidget {
  const _TransactionTableHeader({required this.theme});

  final _ExpressTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TransactionTableCell(
          flex: _TransactionsPaneState._ticketFlex,
          isLast: false,
          child: Text('Ticket', style: theme.tableHeader()),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._plateFlex,
          isLast: false,
          child: Text('Plate', style: theme.tableHeader()),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._vrFlex,
          isLast: false,
          child: Text('VR No.', style: theme.tableHeader()),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._amountFlex,
          isLast: true,
          child: Text(
            'Amount',
            style: theme.tableHeader(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
class _TransactionTableCell extends StatelessWidget {
  const _TransactionTableCell({
    required this.flex,
    required this.child,
    required this.isLast,
  });

  final int flex;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(
          right: isLast ? 0 : _TransactionsPaneState._colGap,
        ),
        child: child,
      ),
    );
  }
}
class _TransactionTableRow extends StatelessWidget {
  const _TransactionTableRow({
    required this.theme,
    required this.ticketId,
    required this.plateLabel,
    required this.vrNo,
    required this.vrNoMissing,
    required this.amountLabel,
    required this.isSynced,
    required this.isVoided,
    required this.includedInCloseCash,
    required this.pesoMoneyStyle,
  });

  final _ExpressTheme theme;
  final String ticketId;
  final String plateLabel;
  final String vrNo;
  final bool vrNoMissing;
  final String amountLabel;
  final bool isSynced;
  final bool isVoided;
  final bool includedInCloseCash;
  final TextStyle Function({
    double fontSize,
    FontWeight fontWeight,
    Color color,
  }) pesoMoneyStyle;

  @override
  Widget build(BuildContext context) {
    final rowMuted = isVoided || includedInCloseCash;
    final muted = rowMuted ? theme.textSecondary : theme.textPrimary;
    final valueStyle = theme.fieldValue().copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: muted,
      decoration: isVoided ? TextDecoration.lineThrough : null,
      decorationColor: theme.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TransactionTableCell(
          flex: _TransactionsPaneState._ticketFlex,
          isLast: false,
          child: Row(
            children: [
              if (!isSynced && !isVoided && !includedInCloseCash) ...[
                const UnsyncedCloudIcon(),
                const SizedBox(width: 5),
              ],
              if (isVoided) ...[
                const _VoidedBadge(),
                const SizedBox(width: 5),
              ],
              if (includedInCloseCash && !isVoided) ...[
                _ClosedCashRowIcon(theme: theme),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  ticketId,
                  style: valueStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._plateFlex,
          isLast: false,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: rowMuted ? 0.55 : 1,
              child: _PlateBadge(label: plateLabel, theme: theme),
            ),
          ),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._vrFlex,
          isLast: false,
          child: Text(
            vrNo,
            style: valueStyle.copyWith(
              color: vrNoMissing ? theme.textSecondary : muted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        _TransactionTableCell(
          flex: _TransactionsPaneState._amountFlex,
          isLast: true,
          child: Text(
            amountLabel,
            style: pesoMoneyStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: muted,
            ).copyWith(
              decoration: isVoided ? TextDecoration.lineThrough : null,
              decorationColor: theme.textSecondary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _VoidedBadge extends StatelessWidget {
  const _VoidedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        'Voided',
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFDC2626),
          height: 1.1,
        ),
      ),
    );
  }
}

class _ClosedCashRowIcon extends StatelessWidget {
  const _ClosedCashRowIcon({required this.theme});

  final _ExpressTheme theme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Already counted in a closed cash session',
      child: Icon(
        LucideIcons.lock,
        size: 13,
        color: theme.textSecondary.withValues(alpha: 0.85),
      ),
    );
  }
}
class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.label, required this.theme});

  final String label;
  final _ExpressTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.plateBadgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.plateBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: theme.fieldValue().copyWith(
          fontSize: 10,
          color: theme.plateBlue,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isSaving,
    required this.isPrinting,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  final bool isSaving;
  final bool isPrinting;
  final bool canSave;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final Future<void> Function() onSaveAndPrint;

  @override
  Widget build(BuildContext context) {
    final theme = _ExpressTheme.of(context);
    final printer = context.watch<PrinterConnectionNotifier>();
    final connected = printer.isConnected;
    final busy = isSaving || isPrinting;
    final canSubmit = canSave && !busy;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: theme.bottomBarBg,
        border: Border(
          top: BorderSide(color: theme.cardBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            connected ? LucideIcons.bluetoothConnected : LucideIcons.bluetoothOff,
            size: 16,
            color: connected
                ? const Color(0xFF27AE60)
                : theme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              printer.statusSubtitle,
              style: theme.notesHint().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: connected
                    ? const Color(0xFF27AE60)
                    : theme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: busy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(92, 42),
              foregroundColor: theme.orange,
              disabledForegroundColor: theme.textSecondary.withValues(alpha: 0.45),
              side: BorderSide(color: theme.orange.withValues(alpha: 0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: canSubmit ? () => unawaited(onSaveAndPrint()) : null,
            icon: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.orange,
                    ),
                  )
                : Icon(LucideIcons.printer, size: 16, color: theme.orange),
            label: const Text('Save and Print'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(132, 42),
              foregroundColor: theme.orange,
              disabledForegroundColor: theme.textSecondary.withValues(alpha: 0.45),
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: theme.headerBg,
              side: BorderSide(color: theme.orange.withValues(alpha: 0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canSubmit ? () => unawaited(onSave()) : null,
            style: FilledButton.styleFrom(
              backgroundColor: theme.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.headerBg,
              disabledForegroundColor: theme.textSecondary.withValues(alpha: 0.45),
              minimumSize: const Size(92, 42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

String _firstNameFromFullName(String fullName) {
  final t = fullName.trim();
  if (t.isEmpty) return '';
  return t.split(RegExp(r'\s+')).first;
}