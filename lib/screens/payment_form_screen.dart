// lib/screens/payment_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/payment_method.dart';
import '../providers/payment_provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  const PaymentFormScreen({super.key, this.paymentMethod});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.paymentMethod != null;

  // Controllers e dati per il form
  late TextEditingController _paymentMethodIdController;
  late TextEditingController _paymentMethodAssetController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  // Dati per i campi complessi
  late Map<String, String> _nameMap;
  late Map<String, String> _descriptionMap;
  late Map<String, String> _metadataMap;
  late Map<String, String> _brandAssetsMap;
  late List<String> _targetList;
  late Set<String> _selectedTouchpoints;
  late Set<String> _selectedDevices;

  // Dati per i dropdown
  String? _selectedGroup;
  String? _selectedStatus;
  String? _selectedMethodManagement;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final pm = widget.paymentMethod;

    _paymentMethodIdController = TextEditingController(text: pm?.paymentMethodId);
    _paymentMethodAssetController = TextEditingController(text: pm?.paymentMethodAsset);
    _minAmountController = TextEditingController(text: pm?.rangeAmount?.min.toString());
    _maxAmountController = TextEditingController(text: pm?.rangeAmount?.max.toString());

    _nameMap = Map.from(pm?.name ?? {'IT': '', 'EN': ''});
    _descriptionMap = Map.from(pm?.description ?? {'IT': '', 'EN': ''});
    _metadataMap = Map.from(pm?.metadata ?? {});
    _brandAssetsMap = Map.from(pm?.paymentMethodsBrandAssets ?? {});
    _targetList = List.from(pm?.target ?? []);

    _selectedTouchpoints = Set.from(pm?.userTouchpoint ?? {});
    _selectedDevices = Set.from(pm?.userDevice ?? {});

    _selectedGroup = pm?.group;
    _selectedStatus = pm?.status;
    _selectedMethodManagement = pm?.methodManagement;
    _selectedDate = pm?.validityDateFrom;
  }

  @override
  void dispose() {
    _paymentMethodIdController.dispose();
    _paymentMethodAssetController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<PaymentProvider>(context, listen: false);

      _nameMap.removeWhere((key, value) => value.trim().isEmpty);
      _descriptionMap.removeWhere((key, value) => value.trim().isEmpty);
      _metadataMap.removeWhere((key, value) => key.trim().isEmpty || value.trim().isEmpty);
      _brandAssetsMap.removeWhere((key, value) => key.trim().isEmpty || value.trim().isEmpty);
      _targetList.removeWhere((element) => element.trim().isEmpty);

      final newMethod = PaymentMethod(
        id: widget.paymentMethod?.id,
        paymentMethodId: _paymentMethodIdController.text,
        paymentMethodAsset: _paymentMethodAssetController.text,
        rangeAmount: FeeRange(
          min: int.parse(_minAmountController.text),
          max: int.parse(_maxAmountController.text),
        ),
        name: _nameMap,
        description: _descriptionMap,
        metadata: _metadataMap.isNotEmpty ? _metadataMap : null,
        paymentMethodsBrandAssets: _brandAssetsMap.isNotEmpty ? _brandAssetsMap : null,
        target: _targetList.isNotEmpty ? _targetList : null,
        userTouchpoint: _selectedTouchpoints.toList(),
        userDevice: _selectedDevices.toList(),
        group: _selectedGroup,
        status: _selectedStatus,
        methodManagement: _selectedMethodManagement,
        validityDateFrom: _selectedDate,
      );

      try {
        if (_isEditing) {
          await provider.updateExistingPaymentMethod(widget.paymentMethod!.paymentMethodId!, newMethod);
        } else {
          await provider.addPaymentMethod(newMethod);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel salvataggio: $e')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Per favore, compila tutti i campi obbligatori.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Dettaglio metodo' : 'Nuovo metodo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Barra con titolo e bottoni di azione
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Modifica metodo di pagamento' : 'Crea metodo di pagamento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annulla'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sezione Principale
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildSection(
                    title: 'Informazioni Principali (Obbligatorie)',
                    children: [
                      _buildMapField('Nome (IT)', 'IT', _nameMap, isRequired: true),
                      _buildMapField('Nome (EN)', 'EN', _nameMap),
                      _buildMapField('Descrizione (IT)', 'IT', _descriptionMap, isRequired: true),
                      _buildMapField('Descrizione (EN)', 'EN', _descriptionMap),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentMethodIdController,
                        decoration: const InputDecoration(labelText: 'Payment Method ID'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Campo obbligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(['CP', 'MYBK', 'BPAY', 'PPAL', 'RPIC', 'RBPS', 'SATY', 'APPL', 'RICO'], 'Gruppo', _selectedGroup, (val) => setState(() => _selectedGroup = val), isRequired: true),
                      const SizedBox(height: 16),
                      _buildDropdown(['ENABLED', 'DISABLED', 'MAINTENANCE'], 'Stato', _selectedStatus, (val) => setState(() => _selectedStatus = val), isRequired: true),
                      const SizedBox(height: 16),
                      _buildDropdown(['ONBOARDABLE', 'ONBOARDABLE_ONLY', 'NOT_ONBOARDABLE', 'REDIRECT'], 'Gestione Metodo', _selectedMethodManagement, (val) => setState(() => _selectedMethodManagement = val), isRequired: true),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentMethodAssetController,
                        decoration: const InputDecoration(labelText: 'Payment Method Asset'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Campo obbligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(isRequired: true),
                      const SizedBox(height: 16),
                      _buildAmountRange(isRequired: true),
                      _buildCheckboxGroup('User Touchpoint', ['IO', 'CHECKOUT', 'CHECKOUT_CART'], _selectedTouchpoints, isRequired: true),
                      _buildCheckboxGroup('User Device', ['IOS', 'ANDROID', 'WEB'], _selectedDevices, isRequired: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sezione Aggiuntiva
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildSection(
                    title: 'Campi Aggiuntivi (Opzionali)',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _DynamicKeyValueFields(
                          title: 'Metadata',
                          mapData: _metadataMap,
                          onChanged: (newMap) => setState(() => _metadataMap = newMap),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DynamicKeyValueFields(
                        title: 'Payment Methods Brand Assets',
                        mapData: _brandAssetsMap,
                        onChanged: (newMap) => setState(() => _brandAssetsMap = newMap),
                      ),
                      const SizedBox(height: 16),
                      _DynamicStringListFields(
                        title: 'Target',
                        listData: _targetList,
                        onChanged: (newList) => setState(() => _targetList = newList),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Qui sotto i metodi _build... (rimangono uguali)
  // ...
  // L'unica modifica è rimuovere ExpansionTile da _buildSection
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        const Divider(height: 24),
        ...children,
      ],
    );
  }
  Widget _buildMapField(String label, String langCode, Map<String, String> map, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        initialValue: map[langCode],
        decoration: InputDecoration(labelText: label),
        onChanged: (value) => setState(() => map[langCode] = value),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Campo obbligatorio';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String label, String? currentValue, ValueChanged<String?> onChanged, {bool isRequired = false}) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && value == null) {
          return 'Selezionare un valore';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker({bool isRequired = false}) {
    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (value) {
        if (isRequired && value == null) {
          return 'Selezionare una data';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(state.value == null ? 'Seleziona data di validità' : 'Valido dal: ${DateFormat('dd/MM/yyyy').format(state.value!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  state.didChange(date);
                }
              },
            ),
            if (state.hasError) Padding(padding: const EdgeInsets.only(left: 16.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
          ],
        );
      },
    );
  }

  Widget _buildAmountRange({bool isRequired = false}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _minAmountController,
            decoration: const InputDecoration(labelText: 'Importo Min'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) return 'Obbligatorio';
              if (value != null && value.isNotEmpty && int.tryParse(value) == null) return 'Numero non valido';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _maxAmountController,
            decoration: const InputDecoration(labelText: 'Importo Max'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) return 'Obbligatorio';
              if (value != null && value.isNotEmpty && int.tryParse(value) == null) return 'Numero non valido';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxGroup(String title, List<String> options, Set<String> selectedValues, {bool isRequired = false}) {
    return FormField<Set<String>>(
      initialValue: selectedValues,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Selezionare almeno un\'opzione';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            ...options.map((option) => CheckboxListTile(
              title: Text(option),
              value: state.value!.contains(option),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    state.value!.add(option);
                  } else {
                    state.value!.remove(option);
                  }
                  state.didChange(state.value); // Notifica al FormField il cambiamento
                });
              },
            )).toList(),
            if (state.hasError) Padding(padding: const EdgeInsets.only(left: 16.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
          ],
        );
      },
    );
  }
}

// --- WIDGETS DINAMICI RIUTILIZZABILI (il loro codice non cambia) ---
// ... (copia e incolla i widget _DynamicStringListFields e _DynamicKeyValueFields dalla risposta precedente)
// --- WIDGETS DINAMICI RIUTILIZZABILI ---

// Widget per gestire una lista di stringhe (es. Target)
class _DynamicStringListFields extends StatefulWidget {
  final String title;
  final List<String> listData;
  final Function(List<String>) onChanged;
  final FormFieldValidator<List<String>>? validator;

  const _DynamicStringListFields({
    required this.title,
    required this.listData,
    required this.onChanged,
    this.validator,
  });

  @override
  __DynamicStringListFieldsState createState() => __DynamicStringListFieldsState();
}

class __DynamicStringListFieldsState extends State<_DynamicStringListFields> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.listData.map((item) => TextEditingController(text: item)).toList();
  }

  @override
  void didUpdateWidget(covariant _DynamicStringListFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listData.length != _controllers.length) {
      _controllers = widget.listData.map((item) => TextEditingController(text: item)).toList();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateParent() {
    widget.onChanged(_controllers.map((c) => c.text).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
        initialValue: widget.listData,
        validator: widget.validator,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
              ...List.generate(_controllers.length, (index) {
                return Row(
                  children: [
                    Expanded(child: TextFormField(controller: _controllers[index], onChanged: (_) => _updateParent())),
                    IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () {
                      setState(() {
                        _controllers.removeAt(index).dispose();
                        _updateParent();
                      });
                    }),
                  ],
                );
              }),
              if (state.hasError) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
              TextButton.icon(icon: const Icon(Icons.add), label: const Text('Aggiungi'), onPressed: () {
                setState(() => _controllers.add(TextEditingController()));
                _updateParent();
              }),
            ],
          );
        });
  }
}


// Widget per gestire una mappa chiave-valore (es. Metadata)
class _DynamicKeyValueFields extends StatefulWidget {
  final String title;
  final Map<String, String> mapData;
  final Function(Map<String, String>) onChanged;
  final FormFieldValidator<Map<String, String>>? validator;

  const _DynamicKeyValueFields({
    required this.title,
    required this.mapData,
    required this.onChanged,
    this.validator,
  });

  @override
  __DynamicKeyValueFieldsState createState() => __DynamicKeyValueFieldsState();
}

class __DynamicKeyValueFieldsState extends State<_DynamicKeyValueFields> {
  late List<MapEntry<TextEditingController, TextEditingController>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.mapData.entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();
  }

  @override
  void didUpdateWidget(covariant _DynamicKeyValueFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapData.length != _entries.length) {
      _entries = widget.mapData.entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();
    }
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  void _updateParent() {
    final newMap = <String, String>{};
    for (var entry in _entries) {
      if (entry.key.text.isNotEmpty) {
        newMap[entry.key.text] = entry.value.text;
      }
    }
    widget.onChanged(newMap);
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
                Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                ...List.generate(_entries.length, (index) {
                  return Row(
                    children: [
                      Expanded(child: TextFormField(controller: _entries[index].key, decoration: const InputDecoration(labelText: 'Chiave'), onChanged: (_) => _updateParent())),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: _entries[index].value, decoration: const InputDecoration(labelText: 'Valore'), onChanged: (_) => _updateParent())),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () {
                        setState(() {
                          _entries.removeAt(index);
                          _updateParent();
                        });
                      }),
                    ],
                  );
                }),
                if (state.hasError) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
                TextButton.icon(icon: const Icon(Icons.add), label: const Text('Aggiungi'), onPressed: () {
                  setState(() => _entries.add(MapEntry(TextEditingController(), TextEditingController())));
                  _updateParent();
                }),
              ],
            );
          }),
    );
  }
}