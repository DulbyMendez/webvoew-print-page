// Widget para el diálogo de configuración de caracteres de la impresora.

import 'package:flutter/material.dart';

/// Un diálogo que permite al usuario seleccionar y probar configuraciones
/// de codificación de caracteres para la impresora.
class CharacterDialog extends StatefulWidget {
  const CharacterDialog({
    Key? key,
    required this.initialCodeTable,
    required this.initialNormalize,
    required this.initialFullNormalize,
    required this.onConfigSaved,
  }) : super(key: key);

  final String initialCodeTable;
  final bool initialNormalize;
  final bool initialFullNormalize;
  final Function(String, bool, bool) onConfigSaved;

  @override
  _CharacterDialogState createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<CharacterDialog> {
  late String _selectedCodeTable;
  late bool _normalizeChars;
  late bool _fullNormalization;

  // Lista de configuraciones de caracteres disponibles
  final List<Map<String, String>> _codeTables = [
    {'name': 'CP1252 (Latin 1 - RECOMENDADO)', 'value': 'CP1252'},
    {'name': 'CP850 (Multilingual)', 'value': 'CP850'},
    {'name': 'CP437 (Estándar USA)', 'value': 'CP437'},
    {'name': 'CP858 (Europa)', 'value': 'CP858'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCodeTable = widget.initialCodeTable;
    _normalizeChars = widget.initialNormalize;
    _fullNormalization = widget.initialFullNormalize;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración de Caracteres'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Consejos:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• CP1252 es la mejor opción para español.\n'
                      '• Si los caracteres se ven mal, activa la normalización.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...(_codeTables
                  .map(
                    (codeTable) => RadioListTile<String>(
                      title: Text(codeTable['name']!),
                      value: codeTable['value']!,
                      groupValue: _selectedCodeTable,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _selectedCodeTable = value);
                        }
                      },
                    ),
                  )
                  .toList()),
              const Divider(),
              CheckboxListTile(
                title: const Text('Normalizar caracteres'),
                subtitle: const Text('Reemplazar á, ñ, etc., por a, n'),
                value: _normalizeChars,
                onChanged: (bool? value) {
                  setState(() => _normalizeChars = value ?? true);
                },
              ),
              // Se puede añadir el de normalización completa si se necesita de nuevo
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfigSaved(
              _selectedCodeTable,
              _normalizeChars,
              _fullNormalization,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Guardar y Probar'),
        ),
      ],
    );
  }
}
