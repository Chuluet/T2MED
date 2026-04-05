import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';

// widgets reutilizables
import 'package:t2med/widgets/login/app_logo_header.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';
import 'package:t2med/widgets/login/decorative_background.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userService = context.read<UserService>();
    final userData = await userService.getUserProfile(user.uid);

    _emailController.text = user.email ?? '';
    _nameController.text = userData?['name'] ?? '';
    _lastNameController.text = userData?['lastName'] ?? '';
    _phoneController.text = userData?['phone'] ?? '';
    _emergencyPhoneController.text = userData?['emergencyPhone'] ?? '';

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  const AppLogoHeader(avatarRadius: 70),

                  const SizedBox(height: 8),

                  const Text(
                    'Editar perfil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A7A96),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        /// Nombre y apellido
                        Row(
                          children: [
                            Expanded(
                              child: RoundedInputField(
                                controller: _nameController,
                                hintText: 'Nombre',
                                prefixIcon: Icons.person_outline,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Obligatorio'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RoundedInputField(
                                controller: _lastNameController,
                                hintText: 'Apellido',
                                prefixIcon: Icons.person_outline,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Obligatorio'
                                        : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _emailController,
                          hintText: 'Correo electrónico',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            const pattern =
                                r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
                                r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
                                r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                            return RegExp(pattern).hasMatch(value ?? '')
                                ? null
                                : 'Correo inválido';
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _phoneController,
                          hintText: 'Teléfono de contacto (+57...)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            const pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                            return RegExp(pattern).hasMatch(value ?? '')
                                ? null
                                : 'Número con prefijo internacional';
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _emergencyPhoneController,
                          hintText: 'Tel. emergencia (opcional)',
                          prefixIcon: Icons.phone_in_talk_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            const pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                            return RegExp(pattern).hasMatch(value)
                                ? null
                                : 'Número con prefijo internacional';
                          },
                        ),

                        const SizedBox(height: 24),

                        PrimaryButton(
                          label: _isSaving
                              ? 'GUARDANDO...'
                              : 'GUARDAR CAMBIOS',
                          onPressed: _isSaving ? null : _saveChanges,
                        ),

                        const SizedBox(height: 24),

                        LinkTextButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                          textColor: const Color(0xFF1E88E5),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userService = context.read<UserService>();

    final Map<String, dynamic> profileData = {
      'email': _emailController.text.trim(),
      'name': _nameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'emergencyPhone': _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
    };

    final error = await userService.updateUserProfile(profileData);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil actualizado')),
      );
      Navigator.pop(context);
    }
  }
}