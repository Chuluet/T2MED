import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    return user?.getIdToken();
  }

  // ==================== CRUD citas médicas ====================

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error en getAppointments: $e');
    }
    return [];
  }

  Future<String?> addAppointment(Map<String, dynamic> appointmentData) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al crear cita';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  Future<String?> updateAppointment(String id, Map<String, dynamic> appointmentData) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      );
      if (response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al actualizar cita';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  Future<String?> deleteAppointment(String id) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al eliminar cita';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

// ==================== Próximas citas ====================


}