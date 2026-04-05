import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/widgets/login/decorative_background.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';

class AddmedPage extends StatefulWidget {
  const AddmedPage({super.key});

  @override
  State<AddmedPage> createState() => _AddmedPageState();
}

class _AddmedPageState extends State<AddmedPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicamentoController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _hora;
  int _selectedColor = 0;
  bool _isSaving = false;

  int _minutosGracia = 15;
  final List<int> _opcionesGracia = [5, 10, 15, 30, 45, 60];

  final List<Color> _colors = [
    Colors.orange,
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.deepPurple,
  ];

  @override
  void dispose() {
    _medicamentoController.dispose();
    _dosisController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Color(0xFF2C3E50), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Agregar Medicamento',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Formulario ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Información básica ──────────────────────
                          const _SectionLabel(label: 'INFORMACIÓN BÁSICA'),
                          const SizedBox(height: 12),

                          RoundedInputField(
                            controller: _medicamentoController,
                            hintText: 'Nombre del medicamento',
                            prefixIcon: Icons.medication_outlined,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          RoundedInputField(
                            controller: _dosisController,
                            hintText: 'Dosis (Ej: 500mg)',
                            prefixIcon: Icons.scale_outlined,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'La dosis es obligatoria'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Nota: TextField nativo porque necesita maxLines
                          _StyledTextArea(
                            controller: _notaController,
                            hint: 'Notas (opcional)',
                          ),

                          const SizedBox(height: 24),

                          // ── Fechas y hora ───────────────────────────
                          const _SectionLabel(label: 'FECHAS Y HORA'),
                          const SizedBox(height: 12),

                          _DateTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha de inicio',
                            value: _fechaInicio == null
                                ? null
                                : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                            onTap: _pickFechaInicio,
                          ),
                          const SizedBox(height: 10),

                          _DateTile(
                            icon: Icons.event_outlined,
                            label: 'Fecha de fin',
                            value: _fechaFin == null
                                ? null
                                : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                            onTap: _pickFechaFin,
                          ),
                          const SizedBox(height: 10),

                          _DateTile(
                            icon: Icons.access_time_outlined,
                            label: 'Hora de toma',
                            value: _hora == null ? null : _formatTimeOfDay(_hora!),
                            onTap: _pickHora,
                          ),

                          const SizedBox(height: 24),

                          // ── Alerta ──────────────────────────────────
                          const _SectionLabel(label: 'ALERTA DE EMERGENCIA'),
                          const SizedBox(height: 12),

                          _DropdownTile(
                            icon: Icons.notifications_active_outlined,
                            label: 'Avisar si no toma en...',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _minutosGracia,
                                isDense: true,
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: _opcionesGracia.map((int v) {
                                  return DropdownMenuItem<int>(
                                    value: v,
                                    child: Text('$v min'),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _minutosGracia = v!),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Color ───────────────────────────────────
                          const _SectionLabel(label: 'COLOR DE IDENTIFICACIÓN'),
                          const SizedBox(height: 12),

                          _ColorPickerRow(
                            colors: _colors,
                            selected: _selectedColor,
                            onSelect: (i) => setState(() => _selectedColor = i),
                          ),

                          const SizedBox(height: 32),

                          // ── Botón guardar ───────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isSaving ? null : _guardarMedicamento,
                              child: _isSaving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : const Text(
                                'GUARDAR MEDICAMENTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          OutlinedActionButton(
                            label: 'CANCELAR',
                            onPressed: () => Navigator.pop(context),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaFin = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _guardarMedicamento() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate() ||
        _hora == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      _showSnackBar('⚠️ Por favor completa todos los campos requeridos', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final medService = context.read<MedicationService>();

    final Map<String, dynamic> medicineData = {
      'nombre': _medicamentoController.text.trim(),
      'dosis': _dosisController.text.trim(),
      'nota': _notaController.text.isNotEmpty ? _notaController.text : null,
      'fechaInicio': _fechaInicio!.toIso8601String(),
      'fechaFin': _fechaFin!.toIso8601String(),
      'hora': _formatTimeOfDay(_hora!),
      'colorIndex': _selectedColor,
      'tiempoGraciaMinutos': _minutosGracia,
    };

    final error = await medService.addMedicine(medicineData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showSnackBar(error, Colors.red);
    } else {
      _showSnackBar('✅ Medicamento guardado correctamente', Colors.green);
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// TextField nativo estilizado para campos multilinea (notas)
class _StyledTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _StyledTextArea({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.notes_rounded,
            color: Colors.black, size: 20),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasValue ? Colors.black :  Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasValue ? value! : label,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black :  Colors.black87,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9DB2C4), size: 20),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final List<Color> colors;
  final int selected;
  final void Function(int) onSelect;

  const _ColorPickerRow({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(colors.length, (i) {
          final bool isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: colors[i].withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
