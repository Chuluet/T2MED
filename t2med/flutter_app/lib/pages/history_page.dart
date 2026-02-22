import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/services/pdf_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _tomasHistorial = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) return DateTime.now();
    if (fecha is DateTime) return fecha;
    if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (_) {}
    }
    if (fecha is Map && fecha.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        fecha['_seconds'] * 1000 + (fecha['_nanoseconds'] ?? 0) ~/ 1000000,
      );
    }
    return DateTime.now();
  }

  Future<void> _cargarHistorial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final medService = context.read<MedicationService>();

      // Obtener historial completo (el backend ya incluye nombreMedicamento)
      final historial = await medService.getHistorial();

      // Asegurar que cada toma tenga un campo 'fecha' en formato String ISO para ordenar
      final historialProcesado = historial.map((toma) {
        // Si la fecha viene en formato Timestamp, la convertimos a String ISO
        if (toma['fecha'] is Map && toma['fecha'].containsKey('_seconds')) {
          final seconds = toma['fecha']['_seconds'];
          final nanoseconds = toma['fecha']['_nanoseconds'] ?? 0;
          final date = DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + nanoseconds ~/ 1000000,
          );
          toma['fecha'] = date.toIso8601String();
        }
        return toma;
      }).toList();

      // Ordenar por fecha descendente
      historialProcesado.sort((a, b) {
        final aTime = DateTime.parse(a['fecha']);
        final bTime = DateTime.parse(b['fecha']);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _tomasHistorial = historialProcesado;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando historial: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPdf(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, introduce una dirección de correo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final pdfService = context.read<PdfService>();
      final error = await pdfService.generateAndSendPdf(email);

      if (!mounted) return;

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Correo enviado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Tomas',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
            color: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isSending)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Enviando correo...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSending ? null : _showExportDialog,
        backgroundColor: _isSending ? Colors.grey : Theme.of(context).primaryColor,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }

  void _showExportDialog() {
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exportar y Enviar PDF'),
          content: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico del destinatario',
              hintText: 'ejemplo@correo.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = _emailController.text;
                Navigator.of(context).pop();
                _sendPdf(email);
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tomasHistorial.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No hay historial de tomas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Text(
              'Confirma u omite algunas tomas para ver el historial',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tomasHistorial.length,
      itemBuilder: (context, index) {
        final data = _tomasHistorial[index];
        return _buildTomaItem(data);
      },
    );
  }

  Widget _buildTomaItem(Map<String, dynamic> data) {
    try {
      final nombre = data['nombreMedicamento'] ?? 'Medicamento';
      final estado = data['estado'] ?? 'Pendiente';

      DateTime fecha;
      if (data['fecha'] is String) {
        fecha = DateTime.parse(data['fecha']);
      } else {
        fecha = DateTime.now();
      }

      final fechaStr = DateFormat('dd/MM/yyyy').format(fecha);
      final horaReal = DateFormat('HH:mm').format(fecha);

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color.fromARGB(255, 97, 97, 97)),
                  const SizedBox(width: 8),
                  Text(fechaStr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Hora de toma: $horaReal',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              if (data['horaProgramada'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Programada: ${data['horaProgramada']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estado == 'Completada'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: estado == 'Completada' ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estado == 'Completada' ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: estado == 'Completada' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estado,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: estado == 'Completada' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error al construir item: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      );
    }
  }
}