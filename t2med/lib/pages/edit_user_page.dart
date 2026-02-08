import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t2med/services/user_service.dart';

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

  final UserService userService = UserService();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      controller: _lastNameController,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'El apellido es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final pattern =
                            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                        return RegExp(pattern).hasMatch(value ?? '')
                            ? null
                            : 'Correo inválido';
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      controller: _phoneController,
                      label: 'Teléfono de contacto',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                        return RegExp(pattern).hasMatch(value ?? '')
                            ? null
                            : 'Debe ser un número de 10 dígitos';
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      controller: _emergencyPhoneController,
                      label: 'Teléfono de emergencia (opcional)',
                      icon: Icons.phone_in_talk,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                        return RegExp(pattern).hasMatch(value)
                            ? null
                            : 'Debe ser un número de 10 dígitos';
                      },
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Guardar cambios',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final error = await userService.updateUserProfile(
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil actualizado')),
      );
      Navigator.pop(context);
    }
  }
}
