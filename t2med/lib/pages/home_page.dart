import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/med_service.dart';
import '../widgets/home_header.dart';
import '../widgets/date_picker_section.dart';
import '../widgets/medication_card.dart';
import '../widgets/empty_state.dart';
import 'profile_page.dart';
import 'addmed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  final MedService medService = MedService();

  @override
  void initState() {
    super.initState();
    _scheduleChecksForDate(selectedDate);
  }

  void _scheduleChecksForDate(DateTime date) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .get()
        .then((snapshot) {
          for (final doc in snapshot.docs) {
            final med = {'id': doc.id, ...doc.data()};
            final parts = med['hora'].split(':');

            final scheduledTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );

            medService.scheduleMedicationCheck(
              medId: med['id'],
              medicationName: med['nombre'],
              scheduledTime: scheduledTime,
            );
          }
        });
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
        title: const Text('T2MED', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          HomeHeader(
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddmedPage()),
            ),
          ),
          DatePickerSection(
            selectedDate: selectedDate,
            onDateChanged: (date) {
              setState(() => selectedDate = date);
              _scheduleChecksForDate(date);
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('medicamentos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final meds = snapshot.data!.docs.map((d) {
                  return {'id': d.id, ...d.data() as Map<String, dynamic>};
                }).toList();

                final filtered = meds.where((med) {
                  final start = DateTime.parse(med['fechaInicio']);
                  final end = DateTime.parse(med['fechaFin']);
                  final sel = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  );
                  return !sel.isBefore(start) && !sel.isAfter(end);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    text: 'No tienes medicamentos para hoy',
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => MedicationCard(
                    med: filtered[i],
                    selectedDate: selectedDate,
                    medService: medService,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
