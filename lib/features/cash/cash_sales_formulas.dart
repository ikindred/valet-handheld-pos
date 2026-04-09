/// Single place to adjust how expected cash and remittance are derived from shift figures.
abstract final class CashSalesFormulas {
  static double expectedCash(double openingFloat, double totalSales) =>
      openingFloat + totalSales;

  /// Amount to remit to supervisor (same as expected cash for now).
  static double salesToRemit(double openingFloat, double totalSales) =>
      openingFloat + totalSales;
}
