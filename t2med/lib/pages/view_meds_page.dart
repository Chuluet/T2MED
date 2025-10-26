
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/pages/editmed_page.dart';
import 'package:t2med/services/addmed_service.dart';

class ViewMedsPage extends StatefulWidget {
  const ViewMedsPage({super.key});

  @override
  _ViewMedsPageState createState() => _ViewMedsPageState();
}

class _ViewMedsPageState extends State<ViewMedsPage> {
  late Future<List<Map<String, dynamic>>> _medicines;

  @override
  void initState() {
    super.initState();
    _medicines = Provider.of<AddMedService>(context, listen: false).getMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _medicines,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los medicamentos'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay medicamentos registrados'));
          } else {
            final medicines = snapshot.data!;
            return ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                return ListTile(
                  title: Text(medicine['nombre']),
                  subtitle: Text(medicine['dosis']),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMedPage(med: medicine),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
