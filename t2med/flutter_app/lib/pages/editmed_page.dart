import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/widgets/login/decorative_background.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';

class EditMedPage extends StatefulWidget {
  final Map<String, dynamic> med;

  const EditMedPage({super.key, required this.med});

  @override
  State<EditMedPage> createState() => _EditMedPageState();
}

class _EditMedPageState extends State<EditMedPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _medicamentoController;
  late TextEditingController _dosisController;
  late TextEditingController _notaController;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _hora;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _medicamentoController = TextEditingController(text: widget.med['nombre']);
    _dosisController = TextEditingController(text: widget.med['dosis']);
    _notaController = TextEditingController(text: widget.med['nota'] ?? '');
    _fechaInicio = _parseDate(widget.med['fechaInicio']);
    _fechaFin = _parseDate(widget.med['fechaFin']);
    _hora = _parseHora(widget.med['hora']);
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return null;
      }
    }
    if (date is DateTime) return date;
    return null;
  }

  TimeOfDay _parseHora(String? hora) {
    if (hora == null || hora.isEmpty) return TimeOfDay.now();
    try {
      final parts = hora.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return TimeOfDay.now();
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

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
                        'Editar Medicamento',
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Información básica ──────────────────
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

                          // Dosis con TextFormField nativo para inputFormatters
                          TextFormField(
                            controller: _dosisController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'La dosis es obligatoria'
                                : null,
                            decoration: InputDecoration(
                              hintText: 'Dosis (Ej: 500mg)',
                              hintStyle: const TextStyle(
                                  color: Colors.black54, fontSize: 15),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.scale_outlined,
                                  color: Colors.black54, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Notas con layout externo para centrar ícono
                          Container(
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
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 16),
                                  child: Icon(Icons.notes_rounded,
                                      color: Colors.black54, size: 20),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _notaController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      hintText: 'Notas (opcional)',
                                      hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 15),
                                      filled: false,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Fechas y hora ───────────────────────
                          const _SectionLabel(label: 'FECHAS Y HORA'),
                          const SizedBox(height: 12),

                          _DateTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha de inicio',
                            value: _fechaInicio == null
                                ? null
                                : DateFormat('dd/MM/yyyy')
                                .format(_fechaInicio!),
                            onTap: _pickFechaInicio,
                          ),
                          const SizedBox(height: 10),

                          _DateTile(
                            icon: Icons.event_outlined,
                            label: 'Fecha de fin',
                            value: _fechaFin == null
                                ? null
                                : DateFormat('dd/MM/yyyy')
                                .format(_fechaFin!),
                            onTap: _pickFechaFin,
                          ),
                          const SizedBox(height: 10),

                          _DateTile(
                            icon: Icons.access_time_outlined,
                            label: 'Hora de toma',
                            value: _hora == null
                                ? null
                                : _formatTimeOfDay(_hora!),
                            onTap: _pickHora,
                          ),

                          const SizedBox(height: 32),

                          // ── Botón guardar ───────────────────────
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
                              onPressed: _loading ? null : _guardarCambios,
                              child: _loading
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

  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _fechaInicio = picked);
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _fechaFin = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _hora = picked);
  }

  // ── Guardar ───────────────────────────────────────────────────────────────

  Future<void> _guardarCambios() async {
    if (_loading) return;

    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty ||
        _hora == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      _showSnackBar(
          '⚠️ Por favor completa todos los campos requeridos', Colors.red);
      return;
    }

    if (mounted) setState(() => _loading = true);

    final medService = context.read<MedicationService>();

    final Map<String, dynamic> medicineData = {
      'nombre': _medicamentoController.text.trim(),
      'dosis': _dosisController.text.trim(),
      'nota': _notaController.text.isNotEmpty ? _notaController.text : null,
      'fechaInicio': _fechaInicio!.toIso8601String(),
      'fechaFin': _fechaFin!.toIso8601String(),
      'hora': _formatTimeOfDay(_hora!),
    };

    final error = await medService.updateMedicine(
      widget.med['id'],
      medicineData,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      _showSnackBar('✅ Medicamento actualizado exitosamente', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(error, Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
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