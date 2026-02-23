import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/appointment_service.dart';

class AddAppointmentPage extends StatefulWidget {
  const AddAppointmentPage({super.key});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lugarController = TextEditingController();
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
          'Registrar Cita Médica',
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
                  _hora == null ? 'Seleccionar hora' : _formatTimeOfDay(_hora!),
                  Icons.access_time,
                ),
              ),

              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 20),
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

  Widget _buildInputField(TextEditingController controller, String hint) {
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isSaving ? null : _guardarCita,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          "Guardar",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fecha = picked);
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

  void _guardarCita() async {
    if (_isSaving) return;

    if (_especialidad == null ||
        _fecha == null ||
        _hora == null ||
        _lugarController.text.isEmpty) {
      _showErrorSnackBar('Todos los campos son obligatorios');
      return;
    }

    setState(() => _isSaving = true);

    final hora24 = _formatTimeOfDay(_hora!);

    final appointmentService = context.read<AppointmentService>();

    final Map<String, dynamic> citaData = {
      'especialidad': _especialidad,
      'fecha': _fecha!.toIso8601String(),
      'hora': hora24,
      'lugar': _lugarController.text,
    };

    final error = await appointmentService.addAppointment(citaData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showErrorSnackBar(error);
    } else {
      // Actualizar lista de próximas citas
      await appointmentService.getAppointments();

      _showSuccessSnackBar('Cita médica registrada exitosamente');

      // Regresar después de un pequeño delay para que se vea el SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    }
  }

  void _showErrorSnackBar(String m) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  void _showSuccessSnackBar(String m) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}