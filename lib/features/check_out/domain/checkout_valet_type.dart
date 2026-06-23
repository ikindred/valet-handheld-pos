import '../../../core/formatting/valet_type_format.dart';

/// Valet vs self-park detection for checkout (local meta + API `valet_type`).
abstract final class CheckoutValetType {
  static bool isSelfPark(String? raw) => ValetTypeFormat.isSelfPark(raw);

  static String? fromDriverOutMeta(String? raw) =>
      ValetTypeFormat.fromDriverOutMeta(raw);

  static bool isSelfParkFromDriverOutMeta(String? driverOut) =>
      isSelfPark(fromDriverOutMeta(driverOut));
}
