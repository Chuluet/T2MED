import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t2med/services/pdf_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _tomasHistorial = [];
  bool _isLoading = true;
  bool _isSending = false; // State for sending email
  final PdfService _pdfService = PdfService();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medicamentosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .get();

      List<Map<String, dynamic>> todasLasTomas = [];

      for (final medDoc in medicamentosSnapshot.docs) {
        final tomasSnapshot = await medDoc.reference
            .collection('tomas')
            .orderBy('timestamp', descending: true)
            .get();

        for (final tomaDoc in tomasSnapshot.docs) {
          final data = tomaDoc.data();
          todasLasTomas.add({
            'id': tomaDoc.id,
            'medicamentoId': medDoc.id,
            ...data,
          });
        }
      }

      try {
        final historialSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tomasHistorial')
            .orderBy('timestamp', descending: true)
            .get();

        for (final histDoc in historialSnapshot.docs) {
          final data = histDoc.data();
          if (!todasLasTomas.any((toma) => 
              toma['timestamp'] == data['timestamp'] && 
              toma['medId'] == data['medId'])) {
            todasLasTomas.add({
              'id': histDoc.id,
              'esHistorial': true,
              ...data,
            });
          }
        }
      } catch (e) {
        print('⚠️ No se pudo cargar tomasHistorial: $e');
      }

      todasLasTomas.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime);
      });

      setState(() {
        _tomasHistorial = todasLasTomas;
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error cargando historial: $e');
      setState(() {
        _isLoading = false;
      });
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

    setState(() {
      _isSending = true;
    });

    try {
      await _pdfService.generateAndSendPdf(_tomasHistorial, email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Correo enviado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
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
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
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
                    Text('Enviando correo...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSending ? null : _showExportDialog, // Disable button while sending
        backgroundColor: _isSending ? Colors.grey : Theme.of(context).primaryColor,
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }

  void _showExportDialog() {
    // Pre-fill with user's email if available
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = _emailController.text;
                Navigator.of(context).pop(); // Close dialog
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
    // ... (El resto del código de _buildBody, _buildTomaItem, etc. permanece igual)
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
      if (data['timestamp'] != null) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      } else {
        fecha = DateTime.now();
      }
      
      String horaFormatoReal = data['horaFormato'] ?? '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      
      final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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
                    'Tomado a las: $horaFormatoReal',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
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