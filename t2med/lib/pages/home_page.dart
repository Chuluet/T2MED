import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t2med/services/notification_service.dart';

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
 final NotificationService _notificationService = NotificationService();
 
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () {
              _notificationService.showNotification(
                1, 
                'Notificación de Prueba', 
                'Esta es una prueba de notificación inmediata.'
              );
            },
          ),
        ],
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
                  return const Center(
                    child: Text(
                      "No hay medicamentos registrados.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final todosMeds = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    ...data,
                  };
                }).toList();

                // 📅 Filtro por fecha seleccionada
                final medsDelDia = todosMeds.where((med) {
                  try {
                    if (med['fechaInicio'] == null || med['fechaFin'] == null) {
                      return false;
                    }

                    final inicio = DateTime.parse(med['fechaInicio']);
                    final fin = DateTime.parse(med['fechaFin']);

                    // Normalizamos las fechas (sin hora)
                    final sinHoraInicio =
                        DateTime(inicio.year, inicio.month, inicio.day);
                    final sinHoraFin =
                        DateTime(fin.year, fin.month, fin.day);
                    final seleccion = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                    );

                    return seleccion.isAtSameMomentAs(sinHoraInicio) ||
                        seleccion.isAtSameMomentAs(sinHoraFin) ||
                        (seleccion.isAfter(sinHoraInicio) &&
                            seleccion.isBefore(sinHoraFin));
                  } catch (e) {
                    debugPrint("Error filtrando medicamento: $e");
                    return false;
                  }
                }).toList();

                if (medsDelDia.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay medicamentos activos para esta fecha.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: medsDelDia.length,
                  itemBuilder: (context, index) {
                    final med = medsDelDia[index];
                    return Dismissible(
                      key: Key(med['id']),
                      background: _editBackground(),
                      secondaryBackground: _deleteBackground(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // ✏️ Editar medicamento
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMedPage(med: med),
                            ),
                          );
                          return false;
                        } else if (direction ==
                            DismissDirection.endToStart) {
                          // 🗑 Confirmar eliminación
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: const Text(
                                  '¿Seguro que desea eliminar el medicamento?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar',
                                      style:
                                          TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _eliminarMed(med['id']);
                          }
                          return false;
                        }
                        return false;
                      },
                      child: _buildMedCard(med),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🧭 Encabezado con fecha y botón agregar
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
                  Text(
                    DateFormat.yMMMMd().format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const Text(
                    'Hoy',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddmedPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 6,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                '+ MED',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 Selector de fecha
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
        onDateChange: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  // 🧱 Fondos para deslizar editar/eliminar
  Widget _editBackground() => Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      );

  Widget _deleteBackground() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      );

  // 🗑 Eliminar medicamento en Firestore
  Future<void> _eliminarMed(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicamento eliminado")),
      );
    } catch (e) {
      debugPrint("Error al eliminar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No se pudo eliminar el medicamento")),
      );
    }
  }

  // 💊 Tarjeta de medicamento
  Widget _buildMedCard(Map<String, dynamic> med) {
    bool completado = med['completado'] ?? false;

    int colorIndex = 0;
    if (med['colorIndex'] is int) {
      colorIndex = med['colorIndex'];
    } else if (med['colorIndex'] is String) {
      colorIndex = int.tryParse(med['colorIndex']) ?? 0;
    }

    final color = _colors[colorIndex % _colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                med['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completado ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  completado ? "Completado" : "Pendiente",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Hora
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                med['hora'] ?? '--:--',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),

          // Nota (si existe)
          if (med['nota'] != null && med['nota'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                med['nota'],
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}
