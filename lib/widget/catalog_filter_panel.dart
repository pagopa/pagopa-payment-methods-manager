import 'package:flutter/material.dart';
import '../models/catalog_filters.dart';

class FilterField {
  final String keyName;
  final String label;
  final List<String>? options;
  final bool currency;

  const FilterField(this.keyName, this.label,
      {this.options, this.currency = false});
}

class CatalogFilterPanel extends StatefulWidget {
  final List<FilterField> fields;
  final ValueChanged<Map<String, String>> onApply;

  const CatalogFilterPanel(
      {super.key, required this.fields, required this.onApply});

  @override
  State<CatalogFilterPanel> createState() => _CatalogFilterPanelState();
}

class _CatalogFilterPanelState extends State<CatalogFilterPanel> {
  final _form = GlobalKey<FormState>();
  final Map<String, String> _values = {};
  int _revision = 0;
  Map<String, String> _applied = {};

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Filtri di ricerca'),
      subtitle: _applied.isEmpty
          ? null
          : Text(_applied.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' / ')),
      initiallyExpanded: false,
      children: [
        ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height < 800 ? 180 : 260),
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.fields.map((field) {
                          return SizedBox(
                            width: 240,
                            child: field.options == null
                                ? TextFormField(
                                    key:
                                        ValueKey('${field.keyName}-$_revision'),
                                    decoration:
                                        InputDecoration(labelText: field.label),
                                    onChanged: (value) =>
                                        _values[field.keyName] = value,
                                    validator: field.currency
                                        ? (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return null;
                                            }
                                            try {
                                              parseCents(value);
                                              return null;
                                            } on FormatException {
                                              return 'Importo non valido';
                                            }
                                          }
                                        : null,
                                  )
                                : DropdownButtonFormField<String>(
                                    key:
                                        ValueKey('${field.keyName}-$_revision'),
                                    initialValue: _values[field.keyName] ?? '',
                                    isExpanded: true,
                                    decoration:
                                        InputDecoration(labelText: field.label),
                                    items: ['', ...field.options!]
                                        .map((value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value.isEmpty
                                                ? 'Tutti'
                                                : value)))
                                        .toList(),
                                    onChanged: (value) =>
                                        _values[field.keyName] = value ?? '',
                                  ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _values.clear();
                                _applied = {};
                                _revision++;
                              });
                              widget.onApply({});
                            },
                            child: const Text('Resetta'),
                          ),
                          FilledButton(
                            onPressed: () {
                              if (_form.currentState!.validate()) {
                                final min = _values['minFee'] ?? '';
                                final max = _values['maxFee'] ?? '';
                                if (min.isNotEmpty &&
                                    max.isNotEmpty &&
                                    parseCents(min) > parseCents(max)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Commissione minima maggiore della massima.')),
                                  );
                                  return;
                                }
                                widget.onApply(Map.of(_values));
                                setState(() {
                                  _applied = Map.fromEntries(_values.entries
                                      .where((entry) =>
                                          entry.value.trim().isNotEmpty));
                                });
                              }
                            },
                            child: const Text('Applica'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
