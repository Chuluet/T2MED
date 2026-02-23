import 'package:flutter/material.dart';

class BuildConditionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController controller;
  final bool isEditing;

  const BuildConditionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> items = controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Título con ícono
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// 🔹 MODO EDICIÓN
            if (isEditing)
              TextFormField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Escribe los datos separados por comas",
                  border: OutlineInputBorder(),
                ),
              )

            /// 🔹 MODO VISUALIZACIÓN
            else if (items.isEmpty)
              const Text(
                "No hay información registrada",
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}