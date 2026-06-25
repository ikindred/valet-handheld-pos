import 'api_error_message.dart';

/// True when check-in failed because [vr_no] is already on the server.
bool isVrNumberAlreadyExistsResponse(int? statusCode, dynamic responseData) {
  if (statusCode != 409) return false;
  final msg = messageFromResponseData(responseData)?.toLowerCase() ?? '';
  if (msg.isEmpty) return false;
  return msg.contains('vr') && msg.contains('already');
}
