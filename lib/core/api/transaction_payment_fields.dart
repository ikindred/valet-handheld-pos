/// Parses payment-related fields from transaction API payloads.
///
/// The API may return empty objects (`{}`) for unset optional money fields;
/// those are treated as absent.
abstract final class TransactionPaymentFields {
  static double? optionalMoney(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(raw.toString().trim());
    return parsed;
  }

  static double? amountFrom(Map<String, dynamic> json) {
    for (final key in const [
      'amount',
      'amount_paid',
      'amountPaid',
      'fee',
    ]) {
      final v = optionalMoney(json[key]);
      if (v != null) return v;
    }
    return null;
  }

  static double? cashTenderedFrom(Map<String, dynamic> json) =>
      optionalMoney(json['cash_tendered'] ?? json['cashTendered']);

  /// Cash tendered and change for receipts and detail screens.
  ///
  /// Change is always `cashTendered - amount` when both are present. API `change`
  /// is never read.
  static ({double? cashTendered, double? change}) resolve({
    Map<String, dynamic>? json,
    double? amount,
    double? cashTendered,
  }) {
    final amt = amount ?? (json != null ? amountFrom(json) : null);
    final tendered =
        cashTendered ?? (json != null ? cashTenderedFrom(json) : null);

    double? ch;
    if (tendered != null && amt != null) {
      final diff = tendered - amt;
      ch = diff < 0.009 ? 0 : diff;
    }

    return (cashTendered: tendered, change: ch);
  }
}
