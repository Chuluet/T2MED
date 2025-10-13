import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t2med/services/addmed_service.dart';

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

  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];

  final AddMedService addMedService = AddMedService();

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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Medicamento"),
              _buildInputField(
                  _medicamentoController, 'Nombre del medicamento'),

              _label("Dosis"),
              _buildInputField(_dosisController, 'Ej: 500 mg'),

              _label("Notas (opcional)"),
              _buildInputField(_notaController, 'Agrega una nota...'),

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
                  _hora == null ? 'Seleccionar hora' : _hora!.format(context),
                  Icons.access_time,
                ),
              ),

              _label("Color"),
              Row(
                children: List.generate(_colors.length, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12, top: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == index
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _selectedColor == index
                          ? const Icon(Icons.check, color: Colors.white,
                          size: 20)
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _guardarMedicamento,
                    child: const Text(
                      "Guardar",
                      style:
                      TextStyle(color: Colors.white,
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

  Widget _label(String text) =>
      Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );

  Widget _buildInputField(TextEditingController controller, String hint) {
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
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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

  void _guardarMedicamento() async {
    if (_medicamentoController.text.isEmpty || _hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Por favor completa los campos obligatorios')),
      );
      return;
    }


    final error = await addMedService.addMedicine(
      nombre: _medicamentoController.text,
      dosis: _dosisController.text,
      nota: _notaController.text,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      hora: _hora!.format(context),
      colorIndex: _selectedColor,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Medicamento guardado correctamente')),
      );
      Navigator.pop(context, {
        'nombre': _medicamentoController.text,
        'dosis': _dosisController.text,
        'nota': _notaController.text,
        'fechaInicio': _fechaInicio,
        'fechaFin': _fechaFin,
        'hora': _hora!.format(context),
        'colorIndex': _selectedColor,
      });
    }
  }
}
