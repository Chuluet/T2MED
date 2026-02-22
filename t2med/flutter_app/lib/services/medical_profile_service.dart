import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MedicalProfileService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<void> saveMedicalProfile({
    required String conditions,
    required String allergies,
    required String surgeries,
    required String additionalNotes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user!.getIdToken();

    await http.post(
      Uri.parse("$baseUrl/condition"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "conditions": conditions,
        "allergies": allergies,
        "surgeries": surgeries,
        "additionalNotes": additionalNotes,
      }),
    );
  }

  Future<Map<String, dynamic>> getMedicalProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user!.getIdToken();

    final response = await http.get(
      Uri.parse("$baseUrl/condition"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }
}