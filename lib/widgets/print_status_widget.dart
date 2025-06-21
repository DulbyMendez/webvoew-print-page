import 'package:flutter/material.dart';
import '../services/print_job_manager.dart';

/// Widget that displays the current print status and configuration.
class PrintStatusWidget extends StatelessWidget {
  final PrintJobManager printJobManager;
  final String selectedCodeTable;
  final bool normalizeCharacters;

  const PrintStatusWidget({
    Key? key,
    required this.printJobManager,
    required this.selectedCodeTable,
    required this.normalizeCharacters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                printJobManager.isPrinting ? Icons.print : Icons.print_outlined,
                color: printJobManager.isPrinting ? Colors.orange : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Estado de Impresión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            printJobManager.getStatusSummary(),
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.settings, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Configuración: $selectedCodeTable',
                style: TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ],
          ),
          if (normalizeCharacters)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.text_fields, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Normalización activada',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
