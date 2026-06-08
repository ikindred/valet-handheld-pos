import '../remote/api_error_message.dart';

/// True when POST `/cash-sessions/start` failed because a session is already open.
bool isCashSessionAlreadyOpenResponse(int? statusCode, dynamic responseData) {
  final code = statusCode ?? 0;
  if (code == 409) return true;
  if (code != 400 && code != 422) return false;
  final msg = messageFromResponseData(responseData)?.toLowerCase() ?? '';
  if (msg.isEmpty) return false;
  return msg.contains('already') &&
      (msg.contains('open') ||
          msg.contains('session') ||
          msg.contains('cash'));
}
