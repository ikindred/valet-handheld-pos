/// Helpers for server branch/area UUIDs vs display names.
abstract final class DeviceSiteIds {
  static final RegExp _uuid =
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  static bool isUuid(String? value) {
    final s = value?.trim() ?? '';
    return s.isNotEmpty && _uuid.hasMatch(s);
  }
}
