import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:t2med/services/addmed_service.dart';
import 'package:t2med/services/notification_service.dart';

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

  // --- NUEVO REQUISITO: Tiempo de gracia configurable ---
  int _minutosGracia = 15;
  final List<int> _opcionesGracia = [5, 10, 15, 30, 45, 60];

  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];
  final AddMedService addMedService = AddMedService();
  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.initNotification();
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
          'Agregar Medicamento',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Medicamento"),
              _buildInputField(_medicamentoController, 'Nombre del medicamento'),

              _label("Dosis"),
              _buildInputField(_dosisController, 'Ej: 500mg', isNumeric: false), // Cambiado a false por si incluyen unidades

              _label("Margen de aviso a emergencia"),
              _buildGraciaDropdown(), // NUEVO WIDGET

              _label("Notas (opcional)"),
              _buildInputField(_notaController, 'Agrega una nota...'),

              _label("Fecha de inicio"),
              GestureDetector(
                onTap: _pickFechaInicio,
                child: _buildDateField(
                  _fechaInicio == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                  Icons.calendar_today,
                ),
              ),

              _label("Fecha de fin"),
              GestureDetector(
                onTap: _pickFechaFin,
                child: _buildDateField(
                  _fechaFin == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                  Icons.event,
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

              _label("Color"),
              _buildColorPicker(),

              const SizedBox(height: 30),

              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para seleccionar los minutos de gracia (Criterio: Configurable por el usuario)
  Widget _buildGraciaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: _minutosGracia,
          decoration: const InputDecoration(border: InputBorder.none),
          items: _opcionesGracia.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text("Avisar tras $value min de retraso"),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _minutosGracia = newValue!);
          },
        ),
      ),
    );
  }

  // --- Lógica de guardado actualizada ---
  void _guardarMedicamento() async {
    if (_isSaving) return;

    if (_medicamentoController.text.isEmpty || _dosisController.text.isEmpty || _hora == null || _fechaInicio == null || _fechaFin == null) {
      _showErrorSnackBar('⚠️ Por favor completa todos los campos requeridos');
      return;
    }

    setState(() => _isSaving = true);

    final hora24 = _formatTimeOfDay(_hora!);

    // SE ENVÍA tiempoGraciaMinutos AL SERVICIO
    final error = await addMedService.addMedicine(
      nombre: _medicamentoController.text,
      dosis: _dosisController.text,
      nota: _notaController.text,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      hora: hora24,
      colorIndex: _selectedColor,
      tiempoGraciaMinutos: _minutosGracia, // Asegúrate de actualizar AddMedService para recibir esto
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      _showErrorSnackBar(error);
    } else {
      _showSuccessSnackBar('✅ Medicamento guardado correctamente');
      Navigator.pop(context);
    }
  }

  // Widgets auxiliares (simplificados para brevedad)
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );

  Widget _buildInputField(TextEditingController controller, String hint, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildDateField(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(text, style: const TextStyle(fontSize: 16)), Icon(icon, color: Colors.grey[600])],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: List.generate(_colors.length, (index) {
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = index),
          child: Container(
            margin: const EdgeInsets.only(right: 12, top: 12),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _colors[index], shape: BoxShape.circle,
              border: Border.all(color: _selectedColor == index ? Colors.black : Colors.transparent, width: 3),
            ),
            child: _selectedColor == index ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: _isSaving ? null : _guardarMedicamento,
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar", style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  // Métodos de pickers (sin cambios)
  String _formatTimeOfDay(TimeOfDay tod) => '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fechaFin = picked);
    }
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _hora = picked);
    }
  }
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));
}