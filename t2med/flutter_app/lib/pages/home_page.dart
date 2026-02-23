import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:t2med/pages/profile_page.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/services/appointment_service.dart';
import 'package:t2med/services/notification_service.dart';

import 'addmed_page.dart';
import 'editmed_page.dart';
import 'addappointment_page.dart';
import 'editappointment_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  final List<Color> _colors = [Colors.orange, Colors.indigo, Colors.pink];

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _loadAppointments();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    try {
      final notificationService = context.read<NotificationService>();
      await notificationService.initNotification();
    } catch (_) {}
  }

  // ================= MEDICAMENTOS =================

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    final medService = context.read<MedicationService>();
    final data = await medService.getMedicines();

    if (mounted) {
      setState(() {
        _medicines = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToma(Map<String, dynamic> med) async {
    final confirmacion = await _mostrarDialogoConfirmacion(med);
    if (confirmacion == null || !mounted) return;

    final medService = context.read<MedicationService>();
    final estado = confirmacion ? 'Completada' : 'Omitida';
    final horaProgramada = med['hora'];

    final error = await medService.registrarToma(
      med['id'],
      _selectedDate,
      estado,
      horaProgramada,
      med['nombre'],
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      await _loadMedicines();
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion(Map<String, dynamic> med) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('¿Tomaste tu medicamento?'),
        content: Text(
          'Por favor, confirma si tomaste ${med['nombre']} (${med['dosis'] ?? ''}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Omitir', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarMed(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar el medicamento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final service = context.read<MedicationService>();
    final error = await service.deleteMedicine(id);

    if (error == null) {
      _loadMedicines();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicamento eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> _getMedicinesForSelectedDate() {
    return _medicines.where((med) {
      try {
        if (med['fechaInicio'] == null || med['fechaFin'] == null) return false;

        final inicio = DateTime.parse(med['fechaInicio']);
        final fin = DateTime.parse(med['fechaFin']);
        final seleccion = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

        return !seleccion.isBefore(DateTime(inicio.year, inicio.month, inicio.day)) &&
            !seleccion.isAfter(DateTime(fin.year, fin.month, fin.day));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ================= CITAS =================

  Future<void> _loadAppointments() async {
    final service = context.read<AppointmentService>();
    final data = await service.getAppointments();

    if (mounted) setState(() => _appointments = data);
  }

  List<Map<String, dynamic>> _getAppointmentsForSelectedDate() {
    return _appointments.where((cita) {
      try {
        final fecha = DateTime.parse(cita['fecha']);
        final d = DateTime(fecha.year, fecha.month, fecha.day);
        return DateUtils.isSameDay(d, _selectedDate);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _eliminarCita(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar la cita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final service = context.read<AppointmentService>();
    await service.deleteAppointment(id);
    _loadAppointments();
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('T2MED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
        ],
      ),
      body: Column(
        children: [
          _headerSection(),
          const SizedBox(height: 10),
          _buildDatePicker(),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ================= LISTA =================

  Widget _buildList() {
    final meds = _getMedicinesForSelectedDate();
    final citas = _getAppointmentsForSelectedDate();

    if (meds.isEmpty && citas.isEmpty) return _empty("No tienes registros para este día.");

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMedicines();
        await _loadAppointments();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...meds.map(_buildMedCardWrapper),
          ...citas.map(_buildAppointmentCard),
        ],
      ),
    );
  }

  Widget _buildMedCardWrapper(Map<String, dynamic> med) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: context
          .read<MedicationService>()
          .getTomaDelDia(med['id'], _selectedDate),
      builder: (context, snapshot) {
        String estado = "Pendiente";
        Color estadoColor = Colors.orange;
        bool puedeCambiar = true;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final toma = snapshot.data!;
          if (toma['estado'] == 'Completada') {
            estado = "Completado";
            estadoColor = Colors.green;
            puedeCambiar = false;
          } else if (toma['estado'] == 'Omitida') {
            estado = "Omitido";
            estadoColor = Colors.red;
            puedeCambiar = false;
          }
        }

        int colorIndex = med['colorIndex'] as int? ?? 0;
        final color = _colors[colorIndex % _colors.length];

        return Dismissible(
          key: Key(med['id']),
          background: _editBg(),
          secondaryBackground: _deleteBg(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditMedPage(med: med)),
              );
              if (result == true) _loadMedicines();
              return false;
            } else {
              await _eliminarMed(med['id']);
              return false;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        med['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: puedeCambiar ? () => _handleToma(med) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      med['hora'] ?? '--:--',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                if (med['nota'] != null &&
                    med['nota'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      med['nota'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> cita) {
    final color = Color(int.tryParse(cita['color']?.toString() ?? '') ?? Colors.indigo.value);

    return Dismissible(
      key: Key(cita['id']),
      background: _editBg(),
      secondaryBackground: _deleteBg(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditAppointmentPage(appointment: cita)));
          if (result == true) _loadAppointments();
          return false;
        } else {
          await _eliminarCita(cita['id']);
          return false;
        }
      },
      child: _card(color, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cita['especialidad'], style: _titleStyle),
          const SizedBox(height: 8),
          _rowIcon(Icons.access_time, cita['hora'] ?? "--:--"),
          const SizedBox(height: 6),
          Text(cita['lugar'], style: _textStyle),
        ],
      )),
    );
  }

  // ================= HEADER =================

  Widget _headerSection() {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat.yMMMMd().format(DateTime.now()), style: const TextStyle(fontSize: 18, color: Colors.black54)),
                  const Text('Hoy', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAppointmentPage())).then((_) => _loadAppointments());
                  },
                  style: _buttonStyle(),
                  child: const Text('+ CITAS', style: _buttonText),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddmedPage())).then((_) => _loadMedicines());
                  },
                  style: _buttonStyle(),
                  child: const Text('+ MED', style: _buttonText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildDatePicker() {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      child: DatePicker(
        DateTime.now(),
        height: 100,
        width: 80,
        initialSelectedDate: _selectedDate,
        selectionColor: Colors.deepPurple,
        selectedTextColor: Colors.white,
        onDateChange: (date) => setState(() => _selectedDate = date),
      ),
    );
  }

  Widget _card(Color color, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _rowIcon(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 6),
      Text(text, style: _textStyle),
    ],
  );

  Widget _editBg() => Container(
    color: Colors.blue,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: const Icon(Icons.edit, color: Colors.white),
  );

  Widget _deleteBg() => Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: const Icon(Icons.delete, color: Colors.white),
  );

  Widget _empty(String m) => Center(child: Text(m, style: const TextStyle(color: Colors.black54)));

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    elevation: 6,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  );

  static const _buttonText = TextStyle(fontSize: 20, color: Colors.white);
  static const _titleStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18);
  static const _textStyle = TextStyle(color: Colors.white70, fontSize: 15);
}