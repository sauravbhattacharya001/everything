import '../utils/http_utils.dart';
import '../constants/app_constants.dart';

class GraphService {
  final String accessToken;

  GraphService(this.accessToken);

  Future<List<Map<String, dynamic>>> fetchCalendarEvents() async {
    final url = '${AppConstants.microsoftGraphBaseUrl}/me/events';
    final response = await HttpUtils.getRequest(url, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    return List<Map<String, dynamic>>.from(response['value']);
  }
}
