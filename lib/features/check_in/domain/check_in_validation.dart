import '../../../core/formatting/plate_number.dart';
import '../routing/check_in_step.dart';
import '../state/check_in_cubit.dart';

/// Per-step and submit validation for the check-in wizard.
abstract final class CheckInValidation {
  static String? validateStep1({
    required String customerFullName,
    required String contactNumber,
  }) {
    if (customerFullName.trim().isEmpty) {
      return 'Enter customer full name.';
    }
    if (contactNumber.trim().isEmpty) {
      return 'Enter contact number.';
    }
    return null;
  }

  static bool isStep1Complete(CheckInState state) =>
      validateStep1(
        customerFullName: state.customerFullName,
        contactNumber: state.contactNumber,
      ) ==
      null;

  /// True when a server slot id is set, or fallback level + slot labels are set.
  static bool isParkingSelectionComplete(CheckInState state) {
    if (state.parkingSlotId.trim().isNotEmpty) return true;
    return state.parkingLevel.trim().isNotEmpty &&
        state.parkingSlot.trim().isNotEmpty;
  }

  static String? validateStep2({
    required String customerFullName,
    required String contactNumber,
    required String plateNumber,
    required String vehicleBrand,
    required String vehicleColor,
    required String vehicleVrNo,
    required bool requireParkingSlot,
    required String parkingSlotId,
  }) {
    final step1 = validateStep1(
      customerFullName: customerFullName,
      contactNumber: contactNumber,
    );
    if (step1 != null) return step1;

    if (normalizePlateNumber(plateNumber).isEmpty) {
      return 'Enter plate number.';
    }
    if (vehicleBrand.trim().isEmpty) {
      return 'Enter brand / model.';
    }
    if (vehicleColor.trim().isEmpty) {
      return 'Enter vehicle color.';
    }
    if (vehicleVrNo.trim().isEmpty) {
      return 'Enter a VR number.';
    }
    if (requireParkingSlot && parkingSlotId.trim().isEmpty) {
      return 'Select a parking slot.';
    }
    return null;
  }

  static String? validateStep2FromState(
    CheckInState state, {
    bool? requireParkingSlot,
  }) {
    final needsSlot = requireParkingSlot ?? !isParkingSelectionComplete(state);
    return validateStep2(
      customerFullName: state.customerFullName,
      contactNumber: state.contactNumber,
      plateNumber: state.plateNumber,
      vehicleBrand: state.vehicleBrand,
      vehicleColor: state.vehicleColor,
      vehicleVrNo: state.vehicleVrNo,
      requireParkingSlot: needsSlot,
      parkingSlotId: state.parkingSlotId,
    );
  }

  static bool isStep2Complete(CheckInState state) =>
      validateStep2FromState(state) == null;

  static bool isStep4Complete(CheckInState state) =>
      state.isCustomerSignatureComplete;

  static bool isCheckInSubmitted(CheckInState state) {
    final serverId = state.serverTicketId?.trim() ?? '';
    if (serverId.isNotEmpty) return true;
    final qr = state.qrCode?.trim() ?? '';
    return qr.isNotEmpty;
  }

  /// Highest 0-based step index the user may open (step-1 = 0 … print = 5).
  static int highestAllowedStepIndex(CheckInState state) {
    if (!isStep1Complete(state)) return 0;
    if (!isStep2Complete(state)) return 1;
    if (!isStep4Complete(state)) return 3;
    if (!isCheckInSubmitted(state)) return 4;
    return 5;
  }

  static String pathForStepIndex(int index) => switch (index) {
        0 => '/check-in/step-1',
        1 => '/check-in/step-2',
        2 => '/check-in/step-3',
        3 => '/check-in/step-4',
        4 => '/check-in/step-5',
        _ => '/check-in/print',
      };

  /// Redirect path when [path] is ahead of completed steps; null if allowed.
  static String? forwardGuardPath(String path, CheckInState state) {
    final requested = checkInStepIndexFromPath(path);
    final allowed = highestAllowedStepIndex(state);
    if (requested <= allowed) return null;
    return pathForStepIndex(allowed);
  }
}
