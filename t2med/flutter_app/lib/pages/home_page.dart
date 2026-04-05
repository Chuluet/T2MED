import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  static const Color _primaryBlue = Color(0xFF2196F3);

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
    final error = await medService.registrarToma(
      med['id'],
      _selectedDate,
      estado,
      med['hora'],
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Medicamento eliminado")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  List<Map<String, dynamic>> _getMedicinesForSelectedDate() {
    return _medicines.where((med) {
      try {
        if (med['fechaInicio'] == null || med['fechaFin'] == null) return false;
        final inicio = DateTime.parse(med['fechaInicio']);
        final fin = DateTime.parse(med['fechaFin']);
        final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        return !sel.isBefore(DateTime(inicio.year, inicio.month, inicio.day)) &&
            !sel.isAfter(DateTime(fin.year, fin.month, fin.day));
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
        return DateUtils.isSameDay(
            DateTime(fecha.year, fecha.month, fecha.day), _selectedDate);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inicio'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: _primaryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: _primaryBlue, size: 24),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido de vuelta',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : _buildScrollableContent(),
    );
  }

  // ================= ACTION BUTTONS =================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: '+ Medicamento',
            icon: Icons.medication_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddmedPage()),
            ).then((_) => _loadMedicines()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
            label: '+ Cita Médica',
            icon: Icons.calendar_month_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAppointmentPage()),
            ).then((_) => _loadAppointments()),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SCROLLABLE CONTENT =================

  Widget _buildScrollableContent() {
    final meds = _getMedicinesForSelectedDate();
    final citas = _getAppointmentsForSelectedDate();

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMedicines();
        await _loadAppointments();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionBubble(
            title: 'Medicamentos',
            icon: Icons.medication_outlined,
            emptyMessage: 'Sin medicamentos para este día',
            isEmpty: meds.isEmpty,
            children: meds.map(_buildMedCardWrapper).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionBubble(
            title: 'Citas Médicas',
            icon: Icons.calendar_month_outlined,
            emptyMessage: 'Sin citas para este día',
            isEmpty: citas.isEmpty,
            children: citas.map(_buildAppointmentCard).toList(),
          ),
        ],
      ),
    );
  }

  // ================= SECTION BUBBLE =================

  Widget _buildSectionBubble({
    required String title,
    required IconData icon,
    required String emptyMessage,
    required bool isEmpty,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryBlue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
                Icon(icon, color: _primaryBlue, size: 24),
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(emptyMessage,
                  style: const TextStyle(
                      color: Color(0xFF8A9BB0), fontSize: 16)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  // ================= MED CARD =================

  Widget _buildMedCardWrapper(Map<String, dynamic> med) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: context
          .read<MedicationService>()
          .getTomaDelDia(med['id'], _selectedDate),
      builder: (context, snapshot) {
        String estado = "Marcar";
        Color estadoBg = _primaryBlue;
        bool puedeCambiar = true;
        bool completada = false;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          final toma = snapshot.data!;
          if (toma['estado'] == 'Completada') {
            estado = "Completada";
            estadoBg = Colors.green;
            puedeCambiar = false;
            completada = true;
          } else if (toma['estado'] == 'Omitida') {
            estado = "Omitida";
            estadoBg = Colors.red;
            puedeCambiar = false;
          }
        }

        final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

        return Dismissible(
          key: Key(med['id']),
          background: _editBg(),
          secondaryBackground: _deleteBg(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditMedPage(med: med)));
              if (result == true) _loadMedicines();
              return false;
            } else {
              await _eliminarMed(med['id']);
              return false;
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE8F5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: completada
                            ? Colors.green.shade100
                            : const Color(0xFFD6E8FB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        completada
                            ? Icons.check_circle_outline
                            : Icons.medication_outlined,
                        color: completada ? Colors.green : _primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF1A2A3A),
                            ),
                          ),
                          if (med['dosis'] != null &&
                              med['dosis'].toString().isNotEmpty)
                            Text(med['dosis'],
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF8A9BB0))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: puedeCambiar ? () => _handleToma(med) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: puedeCambiar
                              ? estadoBg
                              : estadoBg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: puedeCambiar ? Colors.white : estadoBg,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 16, color: Color(0xFF8A9BB0)),
                    const SizedBox(width: 5),
                    Text(med['hora'] ?? '--:--',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF8A9BB0))),
                    const SizedBox(width: 20),
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF8A9BB0)),
                    const SizedBox(width: 5),
                    Text(formattedDate,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF8A9BB0))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= APPOINTMENT CARD =================

  Widget _buildAppointmentCard(Map<String, dynamic> cita) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Dismissible(
      key: Key(cita['id']),
      background: _editBg(),
      secondaryBackground: _deleteBg(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditAppointmentPage(appointment: cita)),
          );
          if (result == true) _loadAppointments();
          return false;
        } else {
          await _eliminarCita(cita['id']);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE8F5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6E8FB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_outlined,
                      color: _primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cita['especialidad'] ?? 'Cita médica',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 16, color: Color(0xFF8A9BB0)),
                const SizedBox(width: 5),
                Text(cita['hora'] ?? '--:--',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF8A9BB0))),
                const SizedBox(width: 20),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Color(0xFF8A9BB0)),
                const SizedBox(width: 5),
                Text(formattedDate,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF8A9BB0))),
              ],
            ),
            if (cita['lugar'] != null && cita['lugar'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF8A9BB0)),
                    const SizedBox(width: 5),
                    Text(cita['lugar'],
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF8A9BB0))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _editBg() => Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      );

  Widget _deleteBg() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      );
}