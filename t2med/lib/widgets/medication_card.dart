import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/med_service.dart';

class MedicationCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final DateTime selectedDate;
  final MedService medService;

  const MedicationCard({
    super.key,
    required this.med,
    required this.selectedDate,
    required this.medService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot>(
        stream: medService.getTomaStream(med['id'], selectedDate),
        builder: (context, snapshot) {
          String estado = 'Pendiente';
          Color color = Colors.orange;

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final toma = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            if (toma['estado'] == 'confirmada') {
              estado = 'Completado';
              color = Colors.green;
            }
          }

          return ListTile(
            title: Text(med['nombre']),
            subtitle: Text(med['hora']),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text(estado, style: const TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }
}
