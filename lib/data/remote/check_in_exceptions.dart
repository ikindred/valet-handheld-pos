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

/// Thrown when [vr_no] is already assigned to another local ticket.
class VrNumberAlreadyUsedException implements Exception {
  @override
  String toString() => 'This VR number is already in use.';
}

/// Thrown when `POST /transactions/check-in` returns 409 because [vr_no] exists remotely.
class VrNumberConflictOnServerException implements Exception {
  VrNumberConflictOnServerException([this.message]);

  final String? message;

  @override
  String toString() =>
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'This VR number already exists on the server.';
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
