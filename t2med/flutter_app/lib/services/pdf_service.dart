import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PdfService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String?> generateAndSendPdf(String emailAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Usuario no autenticado';

    final token = await user.getIdToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pdf/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': emailAddress}),
      );

      if (response.statusCode == 200) return null;

      // Intentar extraer mensaje de error del backend
      try {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Error al enviar el PDF';
      } catch (_) {
        return 'Error al enviar el PDF (código ${response.statusCode})';
      }
    } catch (e) {
      return 'Error de red: $e';
    }
  }
}