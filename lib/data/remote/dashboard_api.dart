import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import 'dashboard_summary.dart';

/// `GET /api/v1/dashboard/summary` — shift-scoped cashier dashboard.
class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardSummary?> fetchSummary({required String bearerToken}) async {
    if (AppConfig.useStubApi) return null;
    final token = bearerToken.trim();
    if (token.isEmpty) return null;

    final res = await _dio.get<dynamic>(
      AppConfig.dashboardSummary,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (c) => c != null && c < 500,
      ),
    );
    if (res.statusCode != 200) {
      ValetLog.warning(
        'DashboardApi',
        'GET dashboard/summary HTTP ${res.statusCode}',
      );
      return null;
    }
    return DashboardSummary.fromResponseData(res.data);
  }
}
