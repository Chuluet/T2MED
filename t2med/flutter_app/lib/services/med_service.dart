import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MedicationService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    return user?.getIdToken();
  }

  // ==================== CRUD medicamentos ====================

  Future<List<Map<String, dynamic>>> getMedicines() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meds'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error en getMedicines: $e');
    }
    return [];
  }

  Future<String?> addMedicine(Map<String, dynamic> medicineData) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meds/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(medicineData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al crear';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  Future<String?> updateMedicine(String id, Map<String, dynamic> medicineData) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/meds/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(medicineData),
      );
      if (response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al actualizar';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  Future<String?> deleteMedicine(String id) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/meds/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al eliminar';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  // ==================== Gestión de tomas (historial) ====================

  Future<String?> registrarToma(String medId, DateTime fecha, String estado, String horaProgramada, String nombreMedicamento) async {
    final token = await _getToken();
    if (token == null) return 'No autenticado';

    final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meds/$medId/toma'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'estado': estado,
          'fecha': fechaStr,
          'horaProgramada': horaProgramada,
          'nombreMedicamento': nombreMedicamento,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return null;
      }
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Error al registrar toma';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  Future<Map<String, dynamic>?> getTomaDelDia(String medId, DateTime fecha) async {
    final token = await _getToken();
    if (token == null) return null;

    final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meds/$medId/toma?fecha=$fechaStr'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error en getTomaDelDia: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getHistorial() async {
  final token = await _getToken();
  if (token == null) return [];

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/meds/historial'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      // Convertir cada toma: el campo 'fecha' puede venir como objeto Timestamp
      return data.map((toma) {
        if (toma['fecha'] is Map && toma['fecha'].containsKey('_seconds')) {
          final seconds = toma['fecha']['_seconds'];
          final nanoseconds = toma['fecha']['_nanoseconds'] ?? 0;
          final date = DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + nanoseconds ~/ 1000000,
          );
          toma['fecha'] = date.toIso8601String();
        } else if (toma['fecha'] is String) {
          // Ya está en formato ISO, lo dejamos igual
        }
        return toma as Map<String, dynamic>;
      }).toList();
    }
  } catch (e) {
    print('Error en getHistorial: $e');
  }
  return [];
}
}