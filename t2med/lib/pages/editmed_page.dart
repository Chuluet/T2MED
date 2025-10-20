import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EditMedPage extends StatefulWidget {
  final Map<String, dynamic> med;

  const EditMedPage({super.key, required this.med});

  @override
  State<EditMedPage> createState() => _EditMedPageState();
}

class _EditMedPageState extends State<EditMedPage> {
  late TextEditingController _medicamentoController;
  late TextEditingController _dosisController;
  late TextEditingController _notaController;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _hora;
  int _selectedColor = 0;

  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];

  @override
  void initState() {
    super.initState();
    _medicamentoController = TextEditingController(text: widget.med['nombre']);
    _dosisController = TextEditingController(text: widget.med['dosis']);
    _notaController = TextEditingController(text: widget.med['nota']);
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
      final parts = hora.split(':');
      final hour = int.parse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
      final minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Medicamento"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Medicamento"),
            _input(_medicamentoController, "Nombre del medicamento"),
            _label("Dosis"),
            _input(_dosisController, "Ej: 500", isNumeric: true),
            _label("Notas (opcional)"),
            _input(_notaController, "Agrega una nota..."),
            _label("Fecha inicio"),
            GestureDetector(
              onTap: _pickFechaInicio,
              child: _dateField(_fechaInicio == null
                  ? "Seleccionar fecha"
                  : DateFormat('dd/MM/yyyy').format(_fechaInicio!)),
            ),
            _label("Fecha fin"),
            GestureDetector(
              onTap: _pickFechaFin,
              child: _dateField(_fechaFin == null
                  ? "Seleccionar fecha"
                  : DateFormat('dd/MM/yyyy').format(_fechaFin!)),
            ),
            _label("Hora"),
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _hora ?? TimeOfDay.now(),
                );
                if (time != null) setState(() => _hora = time);
              },
              child: _dateField(
                  _hora == null ? "Seleccionar hora" : _hora!.format(context)),
            ),
            _label("Color"),
            Row(
              children: List.generate(_colors.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, top: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == i
                            ? Colors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _selectedColor == i
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Guardar Cambios",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _pickFechaInicio() async {
    final today = DateTime.now();
    final initialPickerDate =
        (_fechaInicio != null && _fechaInicio!.isAfter(today))
            ? _fechaInicio!
            : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      });
    }
  }

  Future<void> _pickFechaFin() async {
    final today = DateTime.now();
    final firstSelectableDate =
        _fechaInicio != null && _fechaInicio!.isAfter(today)
            ? _fechaInicio!
            : today;
    final initialPickerDate =
        (_fechaFin != null && _fechaFin!.isAfter(firstSelectableDate))
            ? _fechaFin!
            : firstSelectableDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaFin = picked);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      );

  Widget _input(TextEditingController c, String hint,
      {bool isNumeric = false}) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : [],
    );
  }

  Widget _dateField(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text),
      );

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _guardarCambios() {
    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty ||
        _hora == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      _showErrorSnackBar('⚠️ Por favor completa todos los campos requeridos');
      return;
    }

    final dose = int.tryParse(_dosisController.text);
    if (dose == null || dose <= 0) {
      _showErrorSnackBar('⚠️ La dosis debe ser un número mayor que cero.');
      return;
    }

    final actualizado = {
      'nombre': _medicamentoController.text,
      'dosis': _dosisController.text,
      'nota': _notaController.text,
      'fechaInicio': _fechaInicio,
      'fechaFin': _fechaFin,
      'hora': _hora?.format(context) ?? '',
      'colorIndex': _selectedColor,
      'completado': widget.med['completado'] ?? false,
    };
    Navigator.pop(context, actualizado);
  }
}
