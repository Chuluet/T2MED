import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t2med/services/med_service.dart';

import 'addmed_page.dart';
import 'editmed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];
  final MedService _medService = MedService();

  // Muestra el diálogo de confirmación para una toma
  Future<void> _handleToma(Map<String, dynamic> med) async {
    final confirmacion = await _mostrarDialogoConfirmacion(med);

    if (confirmacion == null || !mounted) return; // Si el usuario cierra el diálogo

    final fechaTomaISO = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).toIso8601String();

    await _medService.actualizarEstadoToma(
      med['id'],
      fechaTomaISO,
      confirmacion,
    );
  }

  // Diálogo para confirmar o omitir la toma
  Future<bool?> _mostrarDialogoConfirmacion(Map<String, dynamic> med) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // Permitir cerrar tocando fuera
      builder: (context) => AlertDialog(
        title: const Text('¿Tomaste tu medicamento?'),
        content: Text(
          'Por favor, confirma si tomaste ${med['nombre']} (${med['dosis']}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Omitir
            child: const Text('Omitir', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirmar
            child: const Text('Confirmar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'T2MED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _headerSection(context),
          const SizedBox(height: 10),
          _buildDatePicker(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('medicamentos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("No hay medicamentos registrados.");
                }

                final todosMeds = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {'id': doc.id, ...data};
                }).toList();

                final medsDelDia = todosMeds.where((med) {
                   try {
                    if (med['fechaInicio'] == null || med['fechaFin'] == null) return false;

                    final inicio = DateTime.parse(med['fechaInicio']);
                    final fin = DateTime.parse(med['fechaFin']);
                    final seleccion = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                    
                    return !seleccion.isBefore(DateTime(inicio.year, inicio.month, inicio.day)) && 
                           !seleccion.isAfter(DateTime(fin.year, fin.month, fin.day));

                  } catch (e) {
                    debugPrint("Error filtrando medicamento: $e");
                    return false;
                  }
                }).toList();

                if (medsDelDia.isEmpty) {
                  return _buildEmptyState("No tienes medicamentos para hoy.");
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: medsDelDia.length,
                  itemBuilder: (context, index) {
                    final med = medsDelDia[index];
                    return _buildMedCard(med);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    int colorIndex = med['colorIndex'] as int? ?? 0;
    final color = _colors[colorIndex % _colors.length];

    return Dismissible(
      key: Key(med['id']),
      background: _editBackground(),
      secondaryBackground: _deleteBackground(),
      confirmDismiss: (direction) async {
         if (direction == DismissDirection.startToEnd) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => EditMedPage(med: med)));
            return false; 
          } else {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: const Text('¿Seguro que desea eliminar el medicamento?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              await _eliminarMed(med['id']);
            }
            return false; // No se elimina el widget automáticamente
          }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _medService.getTomaStream(med['id'], _selectedDate),
          builder: (context, snapshot) {
            String estado = "Pendiente";
            Color estadoColor = Colors.orange;

            if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final toma = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              if (toma['estado'] == 'confirmada') {
                estado = "Completado";
                estadoColor = Colors.green;
              } else {
                estado = "Omitido";
                estadoColor = Colors.grey;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        med['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (estado == "Pendiente") {
                          _handleToma(med);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: estadoColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(estado, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(med['hora'] ?? '--:--', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
                if (med['nota'] != null && med['nota'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(med['nota'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Refactor del resto de widgets y métodos...
  Widget _headerSection(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat.yMMMMd().format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                  const Text('Hoy', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddmedPage())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 6,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('+ MED', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      child: DatePicker(
        DateTime.now(),
        height: 100,
        width: 80,
        initialSelectedDate: _selectedDate,
        selectionColor: Colors.deepPurple,
        selectedTextColor: Colors.white,
        onDateChange: (date) => setState(() => _selectedDate = date),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.black54)));
  }

  Future<void> _eliminarMed(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('medicamentos').doc(id).delete();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Medicamento eliminado")));
    } catch (e) {
      debugPrint("Error al eliminar: $e");
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("No se pudo eliminar el medicamento")));
    }
  }

  Widget _editBackground() => Container(color: Colors.blue, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.edit, color: Colors.white, size: 28));
  Widget _deleteBackground() => Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white, size: 28));
}
