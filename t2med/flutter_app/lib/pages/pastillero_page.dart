import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/med_service.dart';

class PastilleroPage extends StatefulWidget {
  const PastilleroPage({super.key});

  @override
  State<PastilleroPage> createState() => _PastilleroPageState();
}

class _PastilleroPageState extends State<PastilleroPage> {
  Map<String, dynamic>? _medSeleccionado;
  List<Map<String, dynamic>> medicamentos = [];
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _limiteController = TextEditingController();
  final int limiteBajo = 5;

  static const Color _primaryBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  Future<void> _cargarMedicamentos() async {
    final meds = await context.read<MedicationService>().getMedicines();
    setState(() => medicamentos = meds);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final medService = context.watch<MedicationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        title: const Text(
          'Pastillero',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: FutureBuilder(
                future: medService.getInventory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data as List<Map<String, dynamic>>;
                  final porAgotarse =
                      items.where((i) => i['cantidad'] <= limiteBajo).toList();

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        // ── Stats ──
                        _buildStatsRow(items, porAgotarse),
                        const SizedBox(height: 16),

                        // ── Alerta stock bajo ──
                        if (porAgotarse.isNotEmpty)
                          _buildAlertBanner(porAgotarse),

                        if (porAgotarse.isNotEmpty) const SizedBox(height: 16),

                        // ── Lista inventario ──
                        if (items.isEmpty)
                          _buildEmptyState()
                        else ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'INVENTARIO ACTIVO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...items.map(
                              (item) => _buildCard(item, medService)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryBlue,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= STATS ROW =================

  Widget _buildStatsRow(
      List<Map<String, dynamic>> items, List<Map<String, dynamic>> porAgotarse) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            value: '${items.length}',
            label: 'Medicamentos',
            valueColor: const Color(0xFF1A2A3A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            value: '${porAgotarse.length}',
            label: 'Por agotarse',
            valueColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      {required String value,
      required String label,
      required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF8A9BB0))),
        ],
      ),
    );
  }

  // ================= ALERT BANNER =================

  Widget _buildAlertBanner(List<Map<String, dynamic>> porAgotarse) {
    final nombres =
        porAgotarse.map((i) => '${i['nombre']} — quedan solo ${i['cantidad']} unidades').join('\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicamento próximo a agotarse',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombres,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= INVENTORY CARD =================

  Widget _buildCard(Map<String, dynamic> item, MedicationService service) {
    final bool stockBajo = item['cantidad'] <= limiteBajo;
    final int total = item['total'] as int? ?? 50;
    final int cantidad = item['cantidad'] as int? ?? 0;
    final double progreso = total > 0 ? (cantidad / total).clamp(0.0, 1.0) : 0;

    Color progressColor;
    String estadoLabel;
    Color estadoBg;
    Color estadoText;

    if (stockBajo) {
      progressColor = Colors.orange;
      estadoLabel = 'Stock bajo';
      estadoBg = const Color(0xFFFFF3CD);
      estadoText = const Color(0xFF856404);
    } else {
      progressColor = Colors.green;
      estadoLabel = 'Disponible';
      estadoBg = const Color(0xFFD1FAE5);
      estadoText = const Color(0xFF065F46);
    }

    // dosis y frecuencia opcionales
    final String dosis = item['dosis']?.toString() ?? '';
    final String frecuencia = item['frecuencia']?.toString() ?? '';
    final String subtitulo = [dosis, frecuencia].where((s) => s.isNotEmpty).join(' · ');

    return Dismissible(
      key: Key(item['id']),
      background: _editBg(),
      secondaryBackground: _deleteBg(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return false; // editar si quieres implementarlo
        } else {
          await _eliminarItem(service, item['id']);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Barra de color izquierda
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nombre'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2A3A),
                        ),
                      ),
                      if (subtitulo.isNotEmpty)
                        Text(subtitulo,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8A9BB0))),
                    ],
                  ),
                ),
                // Badge de estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(estadoLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estadoText)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: const Color(0xFFE8EDF2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            // Contador + botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$cantidad / $total und.',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8A9BB0)),
                ),
                Row(
                  children: [
                    _iconBtn(
                      icon: Icons.remove,
                      color: Colors.red,
                      onTap: () => _restarPastilla(
                          service, item['id'], cantidad),
                    ),
                    const SizedBox(width: 4),
                    _iconBtn(
                      icon: Icons.add,
                      color: Colors.green,
                      onTap: () => _sumarPastilla(
                          service, item['id'], cantidad),
                    ),
                    const SizedBox(width: 4),
                    _iconBtn(
                      icon: Icons.delete_outline,
                      color: const Color(0xFF8A9BB0),
                      onTap: () => _eliminarItem(service, item['id']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ================= EMPTY STATE =================

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.medication_outlined, size: 60, color: Color(0xFFCDD5E0)),
            SizedBox(height: 16),
            Text(
              'No tienes pastillas registradas',
              style: TextStyle(fontSize: 16, color: Color(0xFF8A9BB0)),
            ),
            SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar',
              style: TextStyle(fontSize: 13, color: Color(0xFFB0BBC8)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOG AGREGAR =================

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE3EA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Agregar al inventario',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2A3A)),
                  ),
                  const SizedBox(height: 20),
                  // Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _medSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Medicamento',
                      filled: true,
                      fillColor: const Color(0xFFF2F5F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: medicamentos.map((med) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: med,
                        child: Text(med['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => _medSeleccionado = value);
                      setState(() => _medSeleccionado = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Cantidad
                  TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Cantidad de pastillas',
                      filled: true,
                      fillColor: const Color(0xFFF2F5F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Total (capacidad máxima)
                  TextField(
                    controller: _limiteController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Capacidad total (ej: 50)',
                      filled: true,
                      fillColor: const Color(0xFFF2F5F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _agregarPastilla(
                            context.read<MedicationService>());
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Agregar al pastillero',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= LÓGICA =================

  Future<void> _agregarPastilla(MedicationService service) async {
    final cantidad = int.tryParse(_cantidadController.text.trim());
    final total = int.tryParse(_limiteController.text.trim()) ?? 50;

    if (_medSeleccionado == null) {
      _showSnackBar('⚠️ Selecciona un medicamento', Colors.red);
      return;
    }
    if (cantidad == null || cantidad <= 0) {
      _showSnackBar('⚠️ Ingresa una cantidad válida', Colors.red);
      return;
    }

    final error = await service.addInventoryItem({
      'medId': _medSeleccionado!['id'],
      'nombre': _medSeleccionado!['nombre'],
      'dosis': _medSeleccionado!['dosis'] ?? '',
      'cantidad': cantidad,
      'total': total,
      'limiteBajo': limiteBajo,
    });

    if (error != null) {
      _showSnackBar(error, Colors.red);
    } else {
      _cantidadController.clear();
      _limiteController.clear();
      setState(() => _medSeleccionado = null);
      _showSnackBar('✅ Agregado correctamente', Colors.green);
    }
  }

  Future<void> _sumarPastilla(
      MedicationService service, String id, int cantidad) async {
    await service.updateInventoryItem(id, {'cantidad': cantidad + 1});
    setState(() {});
  }

  Future<void> _restarPastilla(
      MedicationService service, String id, int cantidad) async {
    if (cantidad <= 0) return;
    await service.updateInventoryItem(id, {'cantidad': cantidad - 1});
    setState(() {});
  }

  Future<void> _eliminarItem(MedicationService service, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Seguro que deseas eliminar este item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await service.deleteInventoryItem(id);
    setState(() {});
  }

  void _showSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

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
}