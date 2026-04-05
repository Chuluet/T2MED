import 'package:flutter/material.dart';
import 'package:t2med/widgets/profile/build_condition_card.dart';
import 'package:t2med/services/medical_profile_service.dart';

class MedicalConditionsPage extends StatefulWidget {
  const MedicalConditionsPage({super.key});

  @override
  State<MedicalConditionsPage> createState() =>
      _MedicalConditionsPageState();
}

class _MedicalConditionsPageState
    extends State<MedicalConditionsPage> {
  final TextEditingController _conditionController =
      TextEditingController();
  final TextEditingController _allergyController =
      TextEditingController();
  final TextEditingController _surgeryController =
      TextEditingController();
  final TextEditingController _aditionalConditionController =
      TextEditingController();

  final MedicalProfileService _service =
      MedicalProfileService();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// 🔹 Cargar datos desde backend
  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final data = await _service.getMedicalProfile();

      _conditionController.text = data['conditions'] ?? '';
      _allergyController.text = data['allergies'] ?? '';
      _surgeryController.text = data['surgeries'] ?? '';
      _aditionalConditionController.text =
          data['additionalNotes'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cargando perfil médico"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Guardado automático al presionar DONE
  Future<void> _toggleEdit() async {
    if (_isEditing) {
      await _saveMedicalConditions();
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  /// 🔹 Guardar en NestJS
  Future<void> _saveMedicalConditions() async {
    if (_conditionController.text.trim().isEmpty &&
        _allergyController.text.trim().isEmpty &&
        _surgeryController.text.trim().isEmpty &&
        _aditionalConditionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Debe ingresar al menos un campo de información médica"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _service.saveMedicalProfile(
        conditions: _conditionController.text,
        allergies: _allergyController.text,
        surgeries: _surgeryController.text,
        additionalNotes:
            _aditionalConditionController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Observaciones médicas actualizadas exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al guardar información"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _allergyController.dispose();
    _surgeryController.dispose();
    _aditionalConditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Condiciones Médicas',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme:
            const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          TextButton(
            onPressed:
                _isLoading ? null : _toggleEdit,
            child: Text(
              _isEditing ? "Done" : "Edit",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  BuildConditionCard(
                    title:
                        'Condiciones Médicas',
                    icon: Icons
                        .health_and_safety,
                    controller:
                        _conditionController,
                    isEditing:
                        _isEditing,
                  ),
                  const SizedBox(
                      height: 16),
                  BuildConditionCard(
                    title: 'Alergias',
                    icon: Icons
                        .warning_amber_rounded,
                    controller:
                        _allergyController,
                    isEditing:
                        _isEditing,
                  ),
                  const SizedBox(
                      height: 16),
                  BuildConditionCard(
                    title:
                        'Cirugías Previas',
                    icon: Icons
                        .local_hospital,
                    controller:
                        _surgeryController,
                    isEditing:
                        _isEditing,
                  ),
                  const SizedBox(
                      height: 16),
                  BuildConditionCard(
                    title:
                        'Otras Observaciones',
                    icon:
                        Icons.notes,
                    controller:
                        _aditionalConditionController,
                    isEditing:
                        _isEditing,
                  ),
                ],
              ),
            ),
    );
  }
}