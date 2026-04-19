import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/services/appointment_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const Color _primaryBlue = Color(0xFF2196F3);

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final meds = await context.read<MedicationService>().getMedicines();
      final citas = await context.read<AppointmentService>().getAppointments();
      if (mounted) {
        setState(() {
          _medicines = meds;
          _appointments = citas;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _medsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _medicines.where((med) {
      try {
        if (med['fechaInicio'] == null || med['fechaFin'] == null) return false;
        final inicio = DateTime.parse(med['fechaInicio']);
        final fin = DateTime.parse(med['fechaFin']);
        final i = DateTime(inicio.year, inicio.month, inicio.day);
        final f = DateTime(fin.year, fin.month, fin.day);
        return !d.isBefore(i) && !d.isAfter(f);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _citasForDay(DateTime day) {
    return _appointments.where((cita) {
      try {
        final fecha = DateTime.parse(cita['fecha']);
        return DateUtils.isSameDay(fecha, day);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Object> _eventsForDay(DateTime day) {
    return [
      ..._medsForDay(day),
      ..._citasForDay(day),
    ];
  }

  bool _isFutureOrToday(DateTime day) {
    final today = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(today.year, today.month, today.day);
    return !d.isBefore(t);
  }

  @override
  Widget build(BuildContext context) {
    final medsSeleccionados = _medsForDay(_selectedDay);
    final citasSeleccionadas = _citasForDay(_selectedDay);
    final esFuturoOHoy = _isFutureOrToday(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        title: const Text(
          'Calendario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    locale: 'es_ES',
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    eventLoader: _eventsForDay,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() => _focusedDay = focused);
                    },
                    // ✅ USAMOS calendarBuilders PARA CREAR NUESTROS PROPIOS CÍRCULOS PEQUEÑOS
                    calendarBuilders: CalendarBuilders(
                      // Constructor del día seleccionado (círculo azul pequeño)
                      selectedBuilder: (context, day, focused) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      // Constructor del día actual (círculo con borde)
                      todayBuilder: (context, day, focused) {
                        final isSelected = isSameDay(day, _selectedDay);
                        if (isSelected) return null; // Usa selectedBuilder si está seleccionado
                        
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      // Constructor normal (sin círculo)
                      defaultBuilder: (context, day, focused) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
                                  ? const Color(0xFF8A9BB0)
                                  : const Color(0xFF1A2A3A),
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                      // Marcadores (dots) más pequeños
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        
                        // Limitar a máximo 3 puntos
                        final displayEvents = events.length > 3 ? events.take(3).toList() : events;
                        
                        return Positioned(
                          bottom: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(displayEvents.length, (index) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: const BoxDecoration(
                                  color: _primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      // Deshabilitamos los círculos por defecto
                      defaultDecoration: const BoxDecoration(),
                      weekendDecoration: const BoxDecoration(),
                      todayDecoration: const BoxDecoration(),
                      selectedDecoration: const BoxDecoration(),
                      // Ajustes de texto
                      defaultTextStyle: const TextStyle(fontSize: 14),
                      weekendTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A9BB0)),
                      outsideTextStyle: const TextStyle(fontSize: 12),
                      // Deshabilitamos marcadores por defecto
                      markersMaxCount: 0,
                      markerDecoration: const BoxDecoration(),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2A3A),
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF1A2A3A)),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF1A2A3A)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color(0xFF8A9BB0),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      weekendStyle: TextStyle(
                        color: Color(0xFF8A9BB0),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        _labelDia(_selectedDay),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A9BB0),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      if (!esFuturoOHoy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Día pasado',
                            style: TextStyle(fontSize: 12, color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: (medsSeleccionados.isEmpty && citasSeleccionadas.isEmpty)
                      ? _buildEmptyState(esFuturoOHoy)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            children: [
                              if (medsSeleccionados.isNotEmpty) ...[
                                _sectionLabel('MEDICAMENTOS', Icons.medication_outlined, _primaryBlue),
                                const SizedBox(height: 8),
                                ...medsSeleccionados.map(_buildMedCard),
                                const SizedBox(height: 12),
                              ],
                              if (citasSeleccionadas.isNotEmpty) ...[
                                _sectionLabel('CITAS MÉDICAS', Icons.calendar_month_outlined, const Color(0xFF7C3AED)),
                                const SizedBox(height: 8),
                                ...citasSeleccionadas.map(_buildCitaCard),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  String _labelDia(DateTime day) {
    final today = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = d.difference(t).inDays;

    if (diff == 0) return 'HOY';
    if (diff == 1) return 'MAÑANA';
    if (diff == -1) return 'AYER';
    return DateFormat('EEEE d \'de\' MMMM', 'es').format(day).toUpperCase();
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    final esFuturo = _isFutureOrToday(_selectedDay);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication_outlined, color: _primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                if (med['dosis'] != null && med['dosis'].toString().isNotEmpty)
                  Text(
                    med['dosis'],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8A9BB0)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF8A9BB0)),
                  const SizedBox(width: 4),
                  Text(
                    med['hora'] ?? '--:--',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8A9BB0)),
                  ),
                ],
              ),
              if (esFuturo && !isSameDay(_selectedDay, DateTime.now()))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Programado',
                      style: TextStyle(fontSize: 11, color: _primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita) {
    const Color purple = Color(0xFF7C3AED);
    final esFuturo = _isFutureOrToday(_selectedDay);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: esFuturo ? purple : const Color(0xFF8A9BB0),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_hospital_outlined, color: purple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita['especialidad'] ?? 'Cita médica',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                if (cita['lugar'] != null && cita['lugar'].toString().isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF8A9BB0)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          cita['lugar'],
                          style: const TextStyle(fontSize: 13, color: Color(0xFF8A9BB0)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF8A9BB0)),
                  const SizedBox(width: 4),
                  Text(
                    cita['hora'] ?? '--:--',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8A9BB0)),
                  ),
                ],
              ),
              if (esFuturo && !isSameDay(_selectedDay, DateTime.now()))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Programada',
                      style: TextStyle(fontSize: 11, color: purple, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool esFuturoOHoy) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            esFuturoOHoy ? Icons.event_available_outlined : Icons.history_outlined,
            size: 56,
            color: const Color(0xFFCDD5E0),
          ),
          const SizedBox(height: 16),
          Text(
            esFuturoOHoy ? 'Sin eventos para este día' : 'Sin registros para este día',
            style: const TextStyle(fontSize: 16, color: Color(0xFF8A9BB0)),
          ),
          const SizedBox(height: 6),
          Text(
            esFuturoOHoy
                ? 'Agrega medicamentos o citas desde la pantalla principal'
                : 'Los eventos pasados no se muestran aquí',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB0BBC8)),
          ),
        ],
      ),
    );
  }
}