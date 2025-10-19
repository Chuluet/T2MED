import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addmed_page.dart';
import 'editmed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🎨 Lista de colores (igual que en AddmedPage)
  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
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
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: DatePicker(
              DateTime.now(),
              height: 100,
              width: 80,
              initialSelectedDate: DateTime.now(),
              selectionColor: Colors.deepPurple,
              selectedTextColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
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
                      "No hay medicamentos agregados",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final meds = snapshot.data!.docs;

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    final med = meds[index].data() as Map<String, dynamic>;
                    med['id'] = meds[index].id; // Guardar el ID
                    bool completado = med['completado'] ?? false;

                    return Dismissible(
                      key: Key(med['id']),
                      background: _editBackground(),
                      secondaryBackground: _deleteBackground(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Editar
                          final updatedMed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMedPage(med: med),
                            ),
                          );

                          if (updatedMed != null) {
                            await _firestore
                                .collection('users')
                                .doc(user.uid)
                                .collection('medicamentos')
                                .doc(med['id'])
                                .update(updatedMed);
                          }

                          return false;
                        } else if (direction ==
                            DismissDirection.endToStart) {
                          // Eliminar
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
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _firestore
                                .collection('users')
                                .doc(user.uid)
                                .collection('medicamentos')
                                .doc(med['id'])
                                .delete();
                            return true;
                          }
                          return false;
                        }
                        return false;
                      },
                      child: GestureDetector(
                        onTap: () async {
                          med['completado'] = !completado;
                          await _firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('medicamentos')
                              .doc(med['id'])
                              .update({'completado': med['completado']});
                        },
                        child: _buildMedCard(med),
                      ),
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

  Widget _buildMedCard(Map<String, dynamic> med) {
    bool completado = med['completado'] ?? false;

    // 🎨 Obtener color según el índice guardado
    int colorIndex = (med['colorIndex'] ?? 0).clamp(0, _colors.length - 1);
    final cardColor = _colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                med['nombre'] ?? '',
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
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                med['hora'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
          if (med['nota'] != null && med['nota'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                med['nota'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}
