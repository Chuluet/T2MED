import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:t2med/services/addmed_service.dart';

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
  int _selectedColor = 0;
  bool _loading = false;

  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];
  final AddMedService _addMedService = AddMedService();

  @override
  void initState() {
    super.initState();
    _medicamentoController = TextEditingController(text: widget.med['nombre']);
    _dosisController = TextEditingController(text: widget.med['dosis']);
    _notaController = TextEditingController(text: widget.med['nota'] ?? '');
    _fechaInicio = _parseDate(widget.med['fechaInicio']);
    _fechaFin = _parseDate(widget.med['fechaFin']);
    _hora = _parseHora(widget.med['hora']);
    _selectedColor = widget.med['colorIndex'] ?? 0;
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    if (date is DateTime) return date;
    return null;
  }

  TimeOfDay _parseHora(String? hora) {
    if (hora == null || hora.isEmpty) return TimeOfDay.now();
    try {
      // Manejar formato HH:mm (24 horas)
      final parts = hora.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
      return TimeOfDay.now();
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
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
          'Editar Medicamento',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Medicamento"),
                    _buildInputField(
                      _medicamentoController,
                      'Nombre del medicamento',
                    ),
                    _label("Dosis"),
                    _buildInputField(
                      _dosisController,
                      'Ej: 500',
                      isNumeric: true,
                    ),
                    _label("Notas (opcional)"),
                    _buildInputField(
                      _notaController,
                      'Agrega una nota...',
                    ),
                    _label("Fecha de inicio"),
                    GestureDetector(
                      onTap: _pickFechaInicio,
                      child: _buildDateField(
                        _fechaInicio == null
                            ? 'Seleccionar fecha'
                            : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                        Icons.calendar_today,
                      ),
                    ),
                    _label("Fecha de fin"),
                    GestureDetector(
                      onTap: _pickFechaFin,
                      child: _buildDateField(
                        _fechaFin == null
                            ? 'Seleccionar fecha'
                            : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                        Icons.event,
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
                    _label("Color"),
                    Row(
                      children: List.generate(_colors.length, (index) {
                        final color = _colors[index];
                        final isSelected = _selectedColor == index;
                        return GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() => _selectedColor = index);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12, top: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _loading ? null : _guardarCambios,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Guardar Cambios",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : [],
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

  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _fechaFin = picked);
    }
  }

  Future<void> _pickHora() async {
    final picked =
        await showTimePicker(context: context, initialTime: _hora ?? TimeOfDay.now());
    if (picked != null && mounted) {
      setState(() => _hora = picked);
    }
  }

  void _showSnack(String message, {Color color = Colors.redAccent}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Future<void> _guardarCambios() async {
    if (_loading) return; // Prevenir múltiples taps
    
    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty ||
        _hora == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      _showSnack('⚠️ Por favor completa todos los campos requeridos');
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    // Convertir la hora a formato 24 horas (HH:mm)
    final hora24 = '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';

    final error = await _addMedService.updateMedicine(
      id: widget.med['id'],
      nombre: _medicamentoController.text,
      dosis: _dosisController.text,
      nota: _notaController.text,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      hora: hora24,
      colorIndex: _selectedColor,
    );

    if (!mounted) return; // Si el widget ya no está montado, no hacer nada

    setState(() => _loading = false);

    if (error == null) {
      _showSnack('✅ Medicamento actualizado exitosamente',
          color: Colors.greenAccent);
      Navigator.pop(context, true);
    } else {
      _showSnack(error);
    }
  }
}