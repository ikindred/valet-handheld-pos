/// Read-only labels for checkout vehicle review (from sync payload / server).
class CheckoutTicketDisplay {
  const CheckoutTicketDisplay({
    this.customerName,
    this.parkingLine,
    this.valetTypeLabel,
  });

  final String? customerName;
  final String? parkingLine;
  final String? valetTypeLabel;
}
