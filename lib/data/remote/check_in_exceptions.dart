/// Thrown when `POST /transactions/check-in` returns 400.
class CheckInValidationException implements Exception {
  CheckInValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the vehicle is already checked in (HTTP 409).
class VehicleAlreadyCheckedInException implements Exception {
  @override
  String toString() => 'This vehicle is already checked in.';
}

/// Thrown for unexpected check-in API status codes.
class CheckInApiException implements Exception {
  CheckInApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode != null ? 'CheckInApiException($statusCode): $message' : message;
}
