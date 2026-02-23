import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/appointment_service.dart';

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
    'Odontología'
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Cita Médica',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Especialidad"),
              _buildEspecialidadDropdown(),

              _label("Lugar"),
              _buildInputField(_lugarController, 'Ej: Hospital Central'),

              _label("Fecha"),
              GestureDetector(
                onTap: _pickFecha,
                child: _buildDateField(
                  _fecha == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(_fecha!),
                  Icons.calendar_today,
                ),
              ),

              _label("Hora"),
              GestureDetector(
                onTap: _pickHora,
                child: _buildDateField(
                  _hora == null
                      ? 'Seleccionar hora'
                      : _formatTimeOfDay(_hora!),
                  Icons.access_time,
                ),
              ),

              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEspecialidadDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _especialidad,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: const Text('Selecciona especialidad'),
        items: _especialidades.map((String esp) {
          return DropdownMenuItem<String>(
            value: esp,
            child: Text(esp),
          );
        }).toList(),
        onChanged: (value) => setState(() => _especialidad = value),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateField(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          Icon(icon, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isSaving ? null : _guardarCambios,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          "Guardar Cambios",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

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
    final picked =
    await showTimePicker(context: context, initialTime: _hora ?? TimeOfDay.now());
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _guardarCambios() async {
    if (_especialidad == null ||
        _fecha == null ||
        _hora == null ||
        _lugarController.text.isEmpty) {
      _showSnack('Todos los campos son obligatorios');
      return;
    }

    setState(() => _isSaving = true);

    final appointmentService = context.read<AppointmentService>();

    final appointmentData = {
      'especialidad': _especialidad,
      'fecha': DateFormat('yyyy-MM-dd').format(_fecha!),
      'hora': _formatTimeOfDay(_hora!),
      'lugar': _lugarController.text,
    };

    final error = await appointmentService.updateAppointment(
      widget.appointment['id'],
      appointmentData,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showSnack(error);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}