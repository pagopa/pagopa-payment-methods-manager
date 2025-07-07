// lib/widgets/dynamic_key_value_fields.dart
import 'package:flutter/material.dart';

class DynamicKeyValueFields extends StatefulWidget {
  final String title;
  final Map<String, String> mapData;
  final Function(Map<String, String>) onChanged;
  final FormFieldValidator<Map<String, String>>? validator;

  const DynamicKeyValueFields({
    super.key, // Usa super.key per i costruttori
    required this.title,
    required this.mapData,
    required this.onChanged,
    this.validator,
  });

  @override
  __DynamicKeyValueFieldsState createState() => __DynamicKeyValueFieldsState();
}

class __DynamicKeyValueFieldsState extends State<DynamicKeyValueFields> {
  late List<MapEntry<TextEditingController, TextEditingController>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.mapData.entries
        .map((e) => MapEntry(TextEditingController(text: e.key),
        TextEditingController(text: e.value)))
        .toList();

    // Aggiungi un listener a ogni controller per aggiornare il parent
    for (var entry in _entries) {
      entry.key.addListener(_updateParent);
      entry.value.addListener(_updateParent);
    }
  }

  // --- RIMUOVI COMPLETAMENTE IL METODO didUpdateWidget ---
  /*
  @override
  void didUpdateWidget(covariant DynamicKeyValueFields oldWidget) {
    // QUESTA LOGICA È LA CAUSA DEL BUG E VA RIMOSSA
  }
  */

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.key.removeListener(_updateParent);
      entry.value.removeListener(_updateParent);
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  void _updateParent() {
    final newMap = <String, String>{};
    for (var entry in _entries) {
      if (entry.key.text.trim().isNotEmpty) {
        newMap[entry.key.text.trim()] = entry.value.text;
      }
    }
    widget.onChanged(newMap);
  }

  void _addRow() {
    setState(() {
      final keyController = TextEditingController();
      final valueController = TextEditingController();

      // Aggiungi i listener ai nuovi controller
      keyController.addListener(_updateParent);
      valueController.addListener(_updateParent);

      _entries.add(MapEntry(keyController, valueController));

      // Chiamiamo _updateParent qui se vogliamo che il genitore sappia subito
      // dell'esistenza della riga (anche se vuota e non valida)
      // ma è meglio attendere l'input dell'utente, i listener faranno il lavoro.
    });
  }

  void _removeRow(int index) {
    setState(() {
      // Rimuovi i listener e fai il dispose prima di rimuovere dalla lista
      final entry = _entries.removeAt(index);
      entry.key.removeListener(_updateParent);
      entry.value.removeListener(_updateParent);
      entry.key.dispose();
      entry.value.dispose();

      // Notifica il genitore della rimozione
      _updateParent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormField<Map<String, String>>(
        initialValue: widget.mapData,
        validator: widget.validator,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _entries[index].key,
                                decoration:
                                const InputDecoration(labelText: 'Chiave'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextFormField(
                                controller: _entries[index].value,
                                decoration:
                                const InputDecoration(labelText: 'Valore'))),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _removeRow(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                  onPressed: _addRow,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}