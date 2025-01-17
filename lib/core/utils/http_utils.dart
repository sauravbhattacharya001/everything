import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpUtils {
  static Future<Map<String, dynamic>> getRequest(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> postRequest(String url, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }
}
