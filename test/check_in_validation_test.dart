import 'package:flutter_test/flutter_test.dart';

import 'package:valet_handheld_pos/features/check_in/domain/check_in_validation.dart';
import 'package:valet_handheld_pos/features/check_in/state/check_in_cubit.dart';
import 'dart:typed_data';

CheckInState _filledThroughStep2() => const CheckInState(
      customerFullName: 'Juan dela Cruz',
      contactNumber: '09171234567',
      plateNumber: 'ABC1234',
      vehicleBrand: 'Toyota Vios',
      vehicleColor: 'White',
      vehicleVrNo: 'VR-1',
      parkingLevel: 'VAL-1',
      parkingSlot: 'VAL01',
      parkingSlotId: 'slot-uuid',
    );

void main() {
  group('CheckInValidation.validateStep1', () {
    test('requires customer full name', () {
      expect(
        CheckInValidation.validateStep1(
          customerFullName: '',
          contactNumber: '09171234567',
        ),
        'Enter customer full name.',
      );
    });

    test('requires contact number', () {
      expect(
        CheckInValidation.validateStep1(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '',
        ),
        'Enter contact number.',
      );
    });

    test('passes when name and contact are filled', () {
      expect(
        CheckInValidation.validateStep1(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
        ),
        isNull,
      );
    });
  });

  group('CheckInValidation.validateStep2', () {
    test('requires plate, brand, color, VR, and slot when parking required', () {
      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: '',
          vehicleBrand: 'Toyota Vios',
          vehicleColor: 'White',
          vehicleVrNo: 'VR-1',
          requireParkingSlot: true,
          parkingSlotId: 'slot-uuid',
        ),
        'Enter plate number.',
      );

      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: 'ABC 1234',
          vehicleBrand: '',
          vehicleColor: 'White',
          vehicleVrNo: 'VR-1',
          requireParkingSlot: true,
          parkingSlotId: 'slot-uuid',
        ),
        'Enter brand / model.',
      );

      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: 'ABC 1234',
          vehicleBrand: 'Toyota Vios',
          vehicleColor: '',
          vehicleVrNo: 'VR-1',
          requireParkingSlot: true,
          parkingSlotId: 'slot-uuid',
        ),
        'Enter vehicle color.',
      );

      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: 'ABC 1234',
          vehicleBrand: 'Toyota Vios',
          vehicleColor: 'White',
          vehicleVrNo: '',
          requireParkingSlot: true,
          parkingSlotId: 'slot-uuid',
        ),
        'Enter a VR number.',
      );

      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: 'ABC 1234',
          vehicleBrand: 'Toyota Vios',
          vehicleColor: 'White',
          vehicleVrNo: 'VR-1',
          requireParkingSlot: true,
          parkingSlotId: '',
        ),
        'Select a parking slot.',
      );
    });

    test('passes with complete vehicle data', () {
      expect(
        CheckInValidation.validateStep2(
          customerFullName: 'Juan dela Cruz',
          contactNumber: '09171234567',
          plateNumber: 'ABC 1234',
          vehicleBrand: 'Toyota Vios',
          vehicleColor: 'White',
          vehicleVrNo: 'VR-1',
          requireParkingSlot: true,
          parkingSlotId: 'slot-uuid',
        ),
        isNull,
      );
    });
  });

  group('CheckInValidation.forwardGuardPath', () {
    test('blocks step 3 when step 1 is incomplete', () {
      expect(
        CheckInValidation.forwardGuardPath(
          '/check-in/step-3',
          const CheckInState(),
        ),
        '/check-in/step-1',
      );
    });

    test('blocks step 5 when signature is missing', () {
      expect(
        CheckInValidation.forwardGuardPath(
          '/check-in/step-5',
          _filledThroughStep2(),
        ),
        '/check-in/step-4',
      );
    });

    test('blocks print until check-in is submitted', () {
      final signed = _filledThroughStep2().copyWith(
        signaturePng: Uint8List.fromList([1, 2, 3]),
      );
      expect(
        CheckInValidation.forwardGuardPath('/check-in/print', signed),
        '/check-in/step-5',
      );
    });

    test('allows print after submit', () {
      final submitted = _filledThroughStep2().copyWith(
        signaturePng: Uint8List.fromList([1, 2, 3]),
        qrCode: 'TKT-0001',
      );
      expect(
        CheckInValidation.forwardGuardPath('/check-in/print', submitted),
        isNull,
      );
    });
  });
}
