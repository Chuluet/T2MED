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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5), width: 1.5),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF4FF),
                ),
                child: Icon(icon, color: const Color(0xFF1E88E5), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2A3A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (isEditing)
            TextFormField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A2A3A),
              ),
              decoration: InputDecoration(
                hintText: 'Escribe los datos separados por comas',
                hintStyle: const TextStyle(
                  color: Color(0xFF8A9BB0),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F8FC),
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFDDE3EA), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF1E88E5), width: 1.5),
                ),
              ),
            )
          else if (items.isEmpty)
            const Text(
              'No hay información registrada',
              style: TextStyle(
                color: Color(0xFF8A9BB0),
                fontSize: 13,
              ),
            )
          else
            Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A2A3A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
