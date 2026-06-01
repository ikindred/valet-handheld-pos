/// Checkout preview: ticket not found (HTTP 404).
class TicketNotFoundException implements Exception {
  TicketNotFoundException([this.message = 'Ticket not found.']);

  final String message;

  @override
  String toString() => 'TicketNotFoundException: $message';
}

/// Checkout API: unauthorized (HTTP 401).
class CheckoutAuthException implements Exception {
  CheckoutAuthException([this.message = 'Session expired. Sign in again.']);

  final String message;

  @override
  String toString() => 'CheckoutAuthException: $message';
}

/// POST check-out validation error (HTTP 400).
class CheckOutValidationException implements Exception {
  CheckOutValidationException(this.message);

  final String message;

  @override
  String toString() => 'CheckOutValidationException: $message';
}

/// Ticket has a pending void request (HTTP 409).
class TicketVoidPendingException implements Exception {
  TicketVoidPendingException([
    this.message =
        'This ticket has a pending void request and cannot be checked out.',
  ]);

  final String message;

  @override
  String toString() => 'TicketVoidPendingException: $message';
}

/// Ticket already checked out (HTTP 409).
class TicketAlreadyCheckedOutException implements Exception {
  TicketAlreadyCheckedOutException([
    this.message = 'This ticket is already checked out.',
  ]);

  final String message;

  @override
  String toString() => 'TicketAlreadyCheckedOutException: $message';
}

/// Other checkout HTTP failures.
class CheckoutApiException implements Exception {
  CheckoutApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode != null
      ? 'CheckoutApiException($statusCode): $message'
      : 'CheckoutApiException: $message';
}
