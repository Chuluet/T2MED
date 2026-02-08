import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const HomeHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.yMMMMd().format(DateTime.now())),
                const Text('Hoy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('+ MED'),
            ),
          ],
        ),
      ),
    );
  }
}
