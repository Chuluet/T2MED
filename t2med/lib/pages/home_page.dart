import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'addmed_page.dart';
import 'editmed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _meds = [];

  @override
  Widget build(BuildContext context) {
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
            child: _meds.isEmpty
                ? const Center(
                    child: Text(
                      "No hay medicamentos agregados",
                      style:
                          TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _meds.length,
                    itemBuilder: (context, index) {
                      final med = _meds[index];
                      return Dismissible(
                        key: Key(med['nombre'] + index.toString()),
                        background: _editBackground(),
                        secondaryBackground: _deleteBackground(),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            final updatedMed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditMedPage(med: med),
                              ),
                            );
                            if (updatedMed != null) {
                              setState(() {
                                _meds[index] = updatedMed;
                              });
                            }
                            return false; // no eliminar
                          } else if (direction == DismissDirection.endToStart) {
                            _eliminarMed(index);
                            return true;
                          }
                          return false;
                        },
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              med['completado'] = !(med['completado'] ?? false);
                            });
                          },
                          child: _buildMedCard(med),
                        ),
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
                final newMed = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddmedPage()),
                );
                if (newMed != null) {
                  setState(() {
                    _meds.add(newMed);
                  });
                }
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

  void _eliminarMed(int index) {
    setState(() {
      _meds.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Medicamento eliminado")),
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    bool completado = med['completado'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: med['color'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                med['nombre'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                med['hora'],
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
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
