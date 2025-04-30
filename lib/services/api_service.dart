import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<void> sendTask(String title) async {
    final url = Uri.parse('$baseUrl/tasks');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'isCompleted': false,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send task: ${response.body}');
    }
  }
}
