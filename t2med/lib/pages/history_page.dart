import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Tomas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRef.snapshots(),
        builder: (context, medsSnapshot) {
          if (medsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!medsSnapshot.hasData || medsSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay medicamentos.'));
          }

          final meds = medsSnapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: meds.map((medDoc) {
              final medData = medDoc.data() as Map<String, dynamic>;
              final nombreMed = medData['nombre'] ?? 'Medicamento';

              return StreamBuilder<QuerySnapshot>(
                stream: medDoc.reference
                    .collection('tomas')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, tomasSnapshot) {
                  if (!tomasSnapshot.hasData ||
                      tomasSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final tomas = tomasSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          nombreMed,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...tomas.map((tomaDoc) {
                        final data =
                            tomaDoc.data() as Map<String, dynamic>;

                        final fecha = data['fecha'] ?? '';
                        final hora = data['hora'] ?? '';
                        final estado = data['estado'] ?? 'pendiente';

                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('$fecha $hora'),
                            subtitle: Text('Estado: $estado'),
                            leading: Icon(
                              estado == 'completada'
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              color: estado == 'completada'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        );
                      }),
                      const Divider(),
                    ],
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
