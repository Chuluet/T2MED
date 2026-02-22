import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/med_service.dart';

class PastilleroPage extends StatefulWidget {
  const PastilleroPage({super.key});
  

  @override
  State<PastilleroPage> createState() => _PastilleroPageState();
  
}

class _PastilleroPageState extends State<PastilleroPage> {
  Map<String, dynamic>? _medSeleccionado;
  List<Map<String, dynamic>> medicamentos = [];
  
  final TextEditingController _cantidadController = TextEditingController();

  final int limiteBajo = 5;

  @override
  Widget build(BuildContext context) {
    final medService = context.watch<MedicationService>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Pastillero",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildAddSection(medService),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder(
              future: medService.getInventory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data as List<Map<String, dynamic>>;

                if (items.isEmpty) {
                  return const Center(
                    child: Text("No tienes pastillas registradas 💊"),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildCard(items[index], medService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  Widget _buildAddSection(MedicationService service) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [

        // 🔽 DROPDOWN en vez de TextField
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _medSeleccionado,
          decoration: const InputDecoration(
            labelText: "Seleccionar medicamento",
            border: OutlineInputBorder(),
          ),
          items: medicamentos.map((med) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: med,
              child: Text(med['nombre']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _medSeleccionado = value;
            });
          },
        ),

        const SizedBox(height: 10),

        _buildInput(
          _cantidadController,
          "Cantidad de pastillas",
          isNumber: true,
        ),

        const SizedBox(height: 15),

        ElevatedButton(
          onPressed: () => _agregarPastilla(service),
          child: const Text("Agregar al pastillero"),
        ),
      ],
    ),
  );
}

  Widget _buildInput(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

  Widget _buildCard(Map<String, dynamic> item, MedicationService service) {
    final bool stockBajo = item['cantidad'] <= limiteBajo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stockBajo ? Colors.red[50] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: stockBajo ? Colors.red : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['nombre'],
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Quedan ${item['cantidad']} pastillas",
            style: TextStyle(
              fontSize: 16,
              color: stockBajo ? Colors.red : Colors.grey[700],
            ),
          ),
          if (stockBajo)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "⚠️ Stock bajo",
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () =>
                    _restarPastilla(service, item['id'], item['cantidad']),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () =>
                    _sumarPastilla(service, item['id'], item['cantidad']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () =>
                    _eliminarItem(service, item['id']),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= LÓGICA =================
  @override
void initState() {
  super.initState();
  _cargarMedicamentos();
}

Future<void> _cargarMedicamentos() async {
  final meds = await context.read<MedicationService>().getMedicines();
  setState(() {
    medicamentos = meds;
  });
}

  Future<void> _agregarPastilla(MedicationService service) async {
  final cantidad = int.tryParse(_cantidadController.text.trim());

  if (_medSeleccionado == null) {
    _showSnackBar("⚠️ Selecciona un medicamento", Colors.red);
    return;
  }

  if (cantidad == null || cantidad <= 0) {
    _showSnackBar("⚠️ Ingresa una cantidad válida", Colors.red);
    return;
  }

  final error = await service.addInventoryItem({
    'medId': _medSeleccionado!['id'],       // 👈 CLAVE
    'nombre': _medSeleccionado!['nombre'],  // solo para mostrar
    'cantidad': cantidad,
    'limiteBajo': limiteBajo,
  });

  if (error != null) {
    _showSnackBar(error, Colors.red);
  } else {
    _cantidadController.clear();
    setState(() {
      _medSeleccionado = null;
    });
    _showSnackBar("✅ Agregado correctamente", Colors.green);
  }
}

  Future<void> _sumarPastilla(
      MedicationService service, String id, int cantidad) async {
    await service.updateInventoryItem(id, {
      'cantidad': cantidad + 1,
    });
    setState(() {});
  }

  Future<void> _restarPastilla(
      MedicationService service, String id, int cantidad) async {
    if (cantidad <= 0) return;

    await service.updateInventoryItem(id, {
      'cantidad': cantidad - 1,
    });
    setState(() {});
  }

  Future<void> _eliminarItem(
      MedicationService service, String id) async {
    await service.deleteInventoryItem(id);
    setState(() {});
  }

  void _showSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }
}