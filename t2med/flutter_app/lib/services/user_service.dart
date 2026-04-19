import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Map<String, dynamic>? _currentUserProfile;
  Map<String, dynamic>? get currentUserProfile => _currentUserProfile;

  Future<String?> login(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Una vez autenticado, cargamos el perfil desde NestJS
    final uid = credential.user!.uid;
    await getUserProfile(uid);

    return null; // null = éxito
  } on FirebaseAuthException catch (e) {
    return switch (e.code) {
      'user-not-found'  => 'No existe una cuenta con este correo',
      'wrong-password'  => 'Contraseña incorrecta',
      'invalid-email'   => 'Correo inválido',
      'user-disabled'   => 'Esta cuenta ha sido deshabilitada',
      'invalid-credential' => 'Correo o contraseña incorrectos',
      _ => 'Error al iniciar sesión',
    };
  } catch (e) {
    return 'Error de red: $e';
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
      if (response.statusCode == 200) {
        _currentUserProfile = {...?_currentUserProfile, ...body};
        notifyListeners();
        return null;
      }
      final resBody = jsonDecode(response.body);
      return resBody['message'] ?? 'Error ${response.statusCode}';
    } catch (e) {
      return 'Error de conexión: $e';
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

  // ==================== Helper autenticado ====================
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
}