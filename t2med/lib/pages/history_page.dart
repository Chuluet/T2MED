import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t2med/services/med_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MedService _medService = MedService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tomas'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _medService.getTomasHistorial(), // Sin medId para obtener todos
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay historial de tomas.', style: TextStyle(fontSize: 16)));
          }

          final tomas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tomas.length,
            itemBuilder: (context, index) {
              final data = tomas[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('${data['nombreMedicamento']} - ${data['estado']}'),
                  subtitle: Text('${data['fecha'].split('T')[0]} ${data['hora']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}