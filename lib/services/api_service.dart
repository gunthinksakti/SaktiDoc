import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/template_model.dart';

class ApiService {
  static const String baseUrl = "https://script.google.com/macros/s/AKfycbwVkzr9KyPo-h5C3YSYzQPKvqcYzOBOn3k_WbE1WAc5ESDUgxCDSYi0kDirte5EEGq-Ag/exec";
  
  static Future<List<Template>> fetchTemplates() async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({'aksi': 'ambil_template'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sukses'] == true) {
          return (data['data'] as List).map((i) => Template.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
