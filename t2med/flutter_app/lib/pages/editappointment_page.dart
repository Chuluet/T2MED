import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/appointment_service.dart';
import 'package:t2med/widgets/login/decorative_background.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';

class EditAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const EditAppointmentPage({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lugarController;

  DateTime? _fecha;
  TimeOfDay? _hora;
  String? _especialidad;
  bool _isSaving = false;

  final List<String> _especialidades = [
    'Cardiología',
    'Dermatología',
    'Pediatría',
    'Medicina General',
    'Neurología',
    'Odontología',
  ];

  @override
  void initState() {
    super.initState();
    _lugarController =
        TextEditingController(text: widget.appointment['lugar'] ?? '');
    _especialidad = widget.appointment['especialidad'];
    _fecha = _parseDate(widget.appointment['fecha']);
    _hora = _parseHora(widget.appointment['hora']);
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseHora(String? hora) {
    if (hora == null) return null;
    try {
      final parts = hora.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _lugarController.dispose();
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
                        'Editar Cita Médica',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Detalles de la cita ─────────────────────
                          const _SectionLabel(label: 'DETALLES DE LA CITA'),
                          const SizedBox(height: 12),

                          _DropdownField(
                            icon: Icons.medical_services_outlined,
                            hint: 'Especialidad médica',
                            value: _especialidad,
                            items: _especialidades,
                            onChanged: (v) =>
                                setState(() => _especialidad = v),
                          ),
                          const SizedBox(height: 12),

                          RoundedInputField(
                            controller: _lugarController,
                            hintText: 'Lugar (Ej: Hospital Central)',
                            prefixIcon: Icons.location_on_outlined,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'El lugar es obligatorio'
                                : null,
                          ),

                          const SizedBox(height: 24),

                          // ── Fecha y hora ────────────────────────────
                          const _SectionLabel(label: 'FECHA Y HORA'),
                          const SizedBox(height: 12),

                          _DateTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Seleccionar fecha',
                            value: _fecha == null
                                ? null
                                : DateFormat('dd/MM/yyyy').format(_fecha!),
                            onTap: _pickFecha,
                          ),
                          const SizedBox(height: 10),

                          _DateTile(
                            icon: Icons.access_time_outlined,
                            label: 'Seleccionar hora',
                            value: _hora == null
                                ? null
                                : _formatTimeOfDay(_hora!),
                            onTap: _pickHora,
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
                              onPressed: _isSaving ? null : _guardarCambios,
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
                                'GUARDAR CAMBIOS',
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

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _guardarCambios() async {
    if (_especialidad == null ||
        _fecha == null ||
        _hora == null ||
        _lugarController.text.isEmpty) {
      _showSnackBar('⚠️ Todos los campos son obligatorios', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final appointmentService = context.read<AppointmentService>();

    final appointmentData = {
      'especialidad': _especialidad,
      'fecha': DateFormat('yyyy-MM-dd').format(_fecha!),
      'hora': _formatTimeOfDay(_hora!),
      'lugar': _lugarController.text.trim(),
    };

    final error = await appointmentService.updateAppointment(
      widget.appointment['id'],
      appointmentData,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      _showSnackBar('✅ Cita actualizada correctamente', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(error, Colors.red);
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
        color: Colors.black54,
        letterSpacing: 1.2,
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
              color: hasValue ? Colors.black87 : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasValue ? value! : label,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black87 : Colors.black54,
                  fontWeight:
                  hasValue ? FontWeight.w600 : FontWeight.normal,
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

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: Colors.black54, size: 20),
              const SizedBox(width: 14),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF9DB2C4), size: 20),
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String esp) {
            return DropdownMenuItem<String>(
              value: esp,
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF1E88E5), size: 18),
                  const SizedBox(width: 12),
                  Text(esp),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}