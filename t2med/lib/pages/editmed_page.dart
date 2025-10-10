import 'package:flutter/material.dart';
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
    _fechaInicio = widget.med['fechaInicio'];
    _fechaFin = widget.med['fechaFin'];
    _hora = _parseHora(widget.med['hora']);
    _selectedColor = _colors.indexOf(widget.med['color']);
    if (_selectedColor < 0) _selectedColor = 0;
  }

  /// ✅ Método mejorado para convertir texto en TimeOfDay de forma segura
  TimeOfDay _parseHora(String? hora) {
    if (hora == null || hora.isEmpty) {
      return TimeOfDay.now();
    }

    try {
      String timeString = hora.trim();

      // Detecta si contiene AM o PM
      bool isPM = timeString.toUpperCase().contains('PM');
      bool isAM = timeString.toUpperCase().contains('AM');

      // Elimina cualquier cosa que no sea número o ':'
      timeString = timeString.replaceAll(RegExp(r'[^0-9:]'), '');

      // Divide la hora y los minutos
      final parts = timeString.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts.length > 1 ? parts[1] : '0');

      // Convierte a formato 24h si es necesario
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Si algo falla, retorna la hora actual
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
            _input(_medicamentoController),

            _label("Dosis"),
            _input(_dosisController),

            _label("Notas"),
            _input(_notaController),

            _label("Fecha inicio"),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _fechaInicio = date);
              },
              child: _dateField(_fechaInicio == null
                  ? "Seleccionar fecha"
                  : DateFormat('dd/MM/yyyy').format(_fechaInicio!)),
            ),

            _label("Fecha fin"),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaFin ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _fechaFin = date);
              },
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      );

  Widget _input(TextEditingController c) => TextField(
        controller: c,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _dateField(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text),
      );

  void _guardarCambios() {
    final actualizado = {
      'nombre': _medicamentoController.text,
      'dosis': _dosisController.text,
      'nota': _notaController.text,
      'fechaInicio': _fechaInicio,
      'fechaFin': _fechaFin,
      'hora': _hora?.format(context) ?? '',
      'color': _colors[_selectedColor],
      'completado': widget.med['completado'] ?? false,
    };
    Navigator.pop(context, actualizado);
  }
}
