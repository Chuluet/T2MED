import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _tomasHistorial = [];
  bool _isLoading = true;

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
      print('🔄 Cargando historial...');
      
      // Método alternativo sin collectionGroup
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

      // También obtener del historial si existe
      try {
        final historialSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tomasHistorial')
            .orderBy('timestamp', descending: true)
            .get();

        for (final histDoc in historialSnapshot.docs) {
          final data = histDoc.data();
          // Evitar duplicados
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

      // Ordenar por timestamp
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

      print('✅ Historial cargado: ${todasLasTomas.length} tomas');

    } catch (e) {
      print('❌ Error cargando historial: $e');
      setState(() {
        _isLoading = false;
      });
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
      body: _buildBody(),
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
      
      // Obtener fecha
      DateTime fecha;
      if (data['fecha'] != null && data['fecha'] is Timestamp) {
        fecha = (data['fecha'] as Timestamp).toDate();
      } else if (data['timestamp'] != null) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      } else {
        fecha = DateTime.now();
      }
      
      // Obtener hora REAL de la toma
      String horaFormatoReal = '';
      if (data['horaFormato'] != null) {
        horaFormatoReal = data['horaFormato'] as String;
      } else if (data['horaFormatoReal'] != null) {
        horaFormatoReal = data['horaFormatoReal'] as String;
      } else if (data['hora'] != null && data['minuto'] != null) {
        final hora = data['hora'] as int;
        final minuto = data['minuto'] as int;
        horaFormatoReal = '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
      } else {
        horaFormatoReal = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      }
      
      // Obtener hora programada (asegurar formato HH:mm)
      String horaProgramada = '';
      if (data['horaProgramada'] != null) {
        final horaProg = data['horaProgramada'];
        if (horaProg is String) {
          // Ya es string, verificar formato
          if (horaProg.contains(':')) {
            horaProgramada = horaProg;
          } else {
            // Solo tiene la hora, agregar ":00"
            horaProgramada = '${horaProg.padLeft(2, '0')}:00';
          }
        } else if (horaProg is int) {
          // Es solo la hora como número
          horaProgramada = '${horaProg.toString().padLeft(2, '0')}:00';
        }
      } else if (data['horaFormatoProgramada'] != null) {
        horaProgramada = data['horaFormatoProgramada'] as String;
      } else {
        horaProgramada = 'No especificada';
      }
      
      // Asegurar que la hora programada tenga formato HH:mm
      if (horaProgramada != 'No especificada' && !horaProgramada.contains(':')) {
        horaProgramada = '${horaProgramada.padLeft(2, '0')}:00';
      }
      
      // Obtener día
      String dia = data['dia'] ?? _obtenerDia(fecha.weekday);
      
      // Formatear fecha
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
              // Nombre del medicamento
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Fecha y día
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(fechaStr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(dia, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Hora real de la toma
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
              
              // Hora programada
              if (horaProgramada != 'No especificada')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Programado: $horaProgramada',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Estado
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
              
              // Información adicional de debug
              if (data['esHistorial'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Desde historial',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
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

  String _obtenerDia(int weekday) {
    final List<String> diasSemana = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 
      'Jueves', 'Viernes', 'Sábado'
    ];
    return diasSemana[weekday - 1];
  }
}