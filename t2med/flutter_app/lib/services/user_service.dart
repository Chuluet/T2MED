import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Estado interno
  Map<String, dynamic>? _currentUserProfile;
  Map<String, dynamic>? get currentUserProfile => _currentUserProfile;

  // Helper para peticiones autenticadas
  Future<http.Response> _authenticatedRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: requestHeaders);
      case 'POST':
        return http.post(uri, headers: requestHeaders, body: body);
      case 'PATCH':
        return http.patch(uri, headers: requestHeaders, body: body);
      default:
        throw UnsupportedError('Método HTTP no soportado');
    }
  }

  // ==================== Perfil ====================
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final response = await _authenticatedRequest('GET', '/users/profile/$uid');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUserProfile = data;
        notifyListeners();
        return data;
      }
    } catch (e) {
      debugPrint('getUserProfile error: $e');
    }
    return null;
  }

  Future<String?> updateUserProfile(Map<String, dynamic> body) async {
  try {
    final response = await _authenticatedRequest(
      'PATCH',
      '/users/profile',
      body: jsonEncode(body),
    );
    debugPrint('📡 updateUserProfile status: ${response.statusCode}');
    debugPrint('📡 updateUserProfile body: ${response.body}');

    if (response.statusCode == 200) {
      // 🔥 Actualizar el estado local con los nuevos datos
      _currentUserProfile = {...?_currentUserProfile, ...body};
      notifyListeners(); // 🔥 Notificar a los widgets
      return null; // éxito
    }

    // Intentar obtener mensaje de error del backend
    try {
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error ${response.statusCode}';
    } catch (_) {
      return 'Error del servidor (${response.statusCode})';
    }
  } catch (e) {
    debugPrint('❌ Exception en updateUserProfile: $e');
    return 'Error de conexión: $e';
  }
}

  // ==================== Registro ====================
  Future<String?> createUser(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error creando usuario';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  // ==================== Recuperación de contraseña ====================
  Future<String?> sendPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) return null;
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error enviando correo';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  // ==================== Emergencia ====================
  Future<String?> notifyEmergency(Map<String, dynamic> body) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        '/users/notify-emergency',
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return null;
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error notificando emergencia';
    } catch (e) {
      return 'Error de red: $e';
    }
  }

  // ==================== FCM Token ====================
  Future<String?> registerFcmToken(String fcmToken) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        '/users/fcm-token',
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error registrando token';
    } catch (e) {
      return 'Error de red: $e';
    }
  }
}