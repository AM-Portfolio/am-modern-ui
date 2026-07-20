import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('Testing connection to http://localhost:9000/identity/auth/login');
  try {
    final response = await http.post(
      Uri.parse('http://localhost:9000/identity/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': 'test@example.com', 'password': 'password'}),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    print('Failed to connect: $e');
  }
}
