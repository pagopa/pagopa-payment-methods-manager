// lib/screens/payment_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import '../widget/DynamicKeyValueFields.dart';
import '../widget/DynamicMultilangField.dart';
import '../widget/DynamicStringListFields.dart';

// DX: Spostare le opzioni statiche in costanti per migliore manutenibilità e leggibilità.
const _groupOptions = [
  'CP',
  'MYBK',
  'BPAY',
  'PPAL',
  'RPIC',
  'RBPS',
  'SATY',
  'APPL',
  'RICO'
];
const _statusOptions = ['ENABLED', 'DISABLED', 'MAINTENANCE'];
const _methodManagementOptions = [
  'ONBOARDABLE',
  'ONBOARDABLE_ONLY',
  'NOT_ONBOARDABLE',
  'REDIRECT'
];
const _touchpointOptions = ['IO', 'CHECKOUT', 'CHECKOUT_CART'];
const _deviceOptions = ['IOS', 'ANDROID', 'WEB'];

class PaymentFormScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod;

  const PaymentFormScreen({super.key, this.paymentMethod});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  // DX: Chiavi separate per ogni step del form per una validazione granulare.
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  bool get _isEditing => widget.paymentMethod != null;

  // UX: Stato per lo stepper e per il caricamento
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers e dati per il form (invariati)
  late TextEditingController _paymentMethodIdController;
  late TextEditingController _paymentMethodAssetController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late Map<String, String> _nameMap;
  late Map<String, String> _descriptionMap;
  late Map<String, String> _metadataMap;
  late Map<String, String> _brandAssetsMap;
  late List<String> _targetList;
  late Set<String> _selectedTouchpoints;
  late Set<String> _selectedDevices;
  String? _selectedGroup;
  String? _selectedStatus;
  String? _selectedMethodManagement;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final pm = widget.paymentMethod;

    _paymentMethodIdController =
        TextEditingController(text: pm?.paymentMethodId);
    _paymentMethodAssetController =
        TextEditingController(text: pm?.paymentMethodAsset);
    _minAmountController =
        TextEditingController(text: pm?.rangeAmount?.min.toString());
    _maxAmountController =
        TextEditingController(text: pm?.rangeAmount?.max.toString());

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
    // UX: Validare tutti gli step prima di procedere
    bool allFormsValid = true;
    for (var formKey in _formKeys) {
      if (!formKey.currentState!.validate()) {
        allFormsValid = false;
      }
    }

    if (!allFormsValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Per favore, compila tutti i campi obbligatori segnalati.')));
      return;
    }

    setState(() => _isLoading = true);

    // Salvataggio e pulizia dati (logica invariata)
    _formKeys.forEach((key) => key.currentState!.save());
    final provider = Provider.of<PaymentProvider>(context, listen: false);

    _nameMap.removeWhere((key, value) => value.trim().isEmpty);
    _descriptionMap.removeWhere((key, value) => value.trim().isEmpty);
    _metadataMap.removeWhere(
        (key, value) => key.trim().isEmpty || value.trim().isEmpty);
    _brandAssetsMap.removeWhere(
        (key, value) => key.trim().isEmpty || value.trim().isEmpty);
    _targetList.removeWhere((element) => element.trim().isEmpty);

    final newMethod = PaymentMethod(
      id: widget.paymentMethod?.id,
      paymentMethodId: _paymentMethodIdController.text,
      paymentMethodAsset: _paymentMethodAssetController.text,
      rangeAmount: FeeRange(
        min: int.tryParse(_minAmountController.text) ?? 0,
        max: int.tryParse(_maxAmountController.text) ?? 0,
      ),
      name: _nameMap,
      description: _descriptionMap,
      metadata: _metadataMap.isNotEmpty ? _metadataMap : null,
      paymentMethodsBrandAssets:
          _brandAssetsMap.isNotEmpty ? _brandAssetsMap : null,
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
        await provider.updateExistingPaymentMethod(
            widget.paymentMethod!.paymentMethodId!, newMethod);
      } else {
        await provider.addPaymentMethod(newMethod);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nel salvataggio: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // UX: Funzioni di controllo per lo Stepper
  void _onStepContinue() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < _getSteps().length - 1) {
        setState(() => _currentStep += 1);
      } else {
        // Siamo all'ultimo step, esegui il submit
        _submitForm();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.of(context)
          .pop(); // Se sono al primo step, "Annulla" chiude la schermata
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Dettaglio metodo' : 'Nuovo metodo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // UX: Un'icona 'close' è più chiara per annullare
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stepper(
        // DX: Lo stepper organizza il form in modo pulito
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        onStepTapped: (step) => setState(() => _currentStep = step),
        type: StepperType.vertical,
        steps: _getSteps(),
        // UX: Personalizzazione dei bottoni dello stepper
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child:
                      _isLoading && details.stepIndex == _getSteps().length - 1
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(details.stepIndex == _getSteps().length - 1
                              ? 'Salva'
                              : 'Continua'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(details.stepIndex == 0 ? 'Annulla' : 'Indietro'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // DX: La lista di Step è generata da una funzione per rendere il build method più pulito.
  List<Step> _getSteps() => [
        Step(
          title: const Text('Informazioni di Base'),
          content: Form(
            key: _formKeys[0],
            child: Column(
              children: [
                // UX: Sostituzione con il nuovo widget dinamico
                DynamicMultilangField(
                  label: 'Nome Metodo',
                  initialData: _nameMap,
                  onChanged: (newMap) => setState(() => _nameMap = newMap),
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                // UX: Sostituzione con il nuovo widget dinamico
                DynamicMultilangField(
                  label: 'Descrizione',
                  initialData: _descriptionMap,
                  onChanged: (newMap) =>
                      setState(() => _descriptionMap = newMap),
                  isMultiline: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentMethodIdController,
                  decoration: const InputDecoration(
                      labelText: 'Payment Method ID',
                      helperText: 'ID tecnico univoco del metodo',
                      prefixIcon: Icon(Icons.vpn_key_outlined)),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(_groupOptions, 'Gruppo', _selectedGroup,
                    (val) => setState(() => _selectedGroup = val),
                    isRequired: true),
                const SizedBox(height: 16),
                _buildDropdown(_statusOptions, 'Stato', _selectedStatus,
                    (val) => setState(() => _selectedStatus = val),
                    isRequired: true),
              ],
            ),
          ),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Regole e Configurazione'),
          content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildDatePicker(isRequired: true),
                  const SizedBox(height: 16),
                  _buildAmountRange(isRequired: true),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      _methodManagementOptions,
                      'Gestione Metodo',
                      _selectedMethodManagement,
                      (val) => setState(() => _selectedMethodManagement = val),
                      isRequired: true),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paymentMethodAssetController,
                    decoration: const InputDecoration(
                        labelText: 'Payment Method Asset',
                        prefixIcon: Icon(Icons.image_outlined)),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Campo obbligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceChipGroup('User Touchpoint', _touchpointOptions,
                      _selectedTouchpoints,
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildChoiceChipGroup(
                      'User Device', _deviceOptions, _selectedDevices,
                      isRequired: true),
                ],
              )),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Dati Avanzati (Opzionali)'),
          content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  DynamicKeyValueFields(
                    title: 'Metadata',
                    mapData: _metadataMap,
                    onChanged: (newMap) =>
                        setState(() => _metadataMap = newMap),
                  ),
                  const SizedBox(height: 16),
                  DynamicKeyValueFields(
                    title: 'Payment Methods Brand Assets',
                    mapData: _brandAssetsMap,
                    onChanged: (newMap) =>
                        setState(() => _brandAssetsMap = newMap),
                  ),
                  const SizedBox(height: 16),
                  DynamicStringListFields(
                    title: 'Target',
                    listData: _targetList,
                    onChanged: (newList) =>
                        setState(() => _targetList = newList),
                  ),
                ],
              )),
          isActive: _currentStep >= 2,
        ),
      ];

  // --- NUOVI WIDGET DI BUILD MIGLIORATI ---

  // UX: Widget compatto per campi multilingua
  Widget _buildMultilangField(
      {required String label,
      required Map<String, String> map,
      bool isRequired = false,
      bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: map['IT'],
          maxLines: isMultiline ? 3 : 1,
          decoration: const InputDecoration(
            labelText: 'Italiano',
            prefixIcon: Icon(Icons.flag_circle),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => map['IT'] = value),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Campo obbligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: map['EN'],
          maxLines: isMultiline ? 3 : 1,
          decoration: const InputDecoration(
            labelText: 'Inglese',
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => map['EN'] = value),
        ),
      ],
    );
  }

  // UX: Sostituisce i Checkbox con i ChoiceChip, più moderni e compatti.
  Widget _buildChoiceChipGroup(
      String title, List<String> options, Set<String> selectedValues,
      {bool isRequired = false}) {
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
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: options.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: state.value!.contains(option),
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        state.value!.add(option);
                      } else {
                        state.value!.remove(option);
                      }
                      state.didChange(state.value);
                    });
                  },
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(state.errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12))),
          ],
        );
      },
    );
  }

  // Widget originali leggermente adattati
  Widget _buildDropdown(List<String> items, String label, String? currentValue,
      ValueChanged<String?> onChanged,
      {bool isRequired = false}) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && value == null) return 'Selezionare un valore';
        return null;
      },
    );
  }

  Widget _buildDatePicker({bool isRequired = false}) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
          text: _selectedDate == null
              ? ''
              : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
      decoration: InputDecoration(
        labelText: 'Data di Validità',
        hintText: 'Seleziona una data',
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      validator: (value) {
        if (isRequired && _selectedDate == null) {
          return 'Selezionare una data';
        }
        return null;
      },
    );
  }

  Widget _buildAmountRange({bool isRequired = false}) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _minAmountController,
            decoration: const InputDecoration(
                labelText: 'Importo Min', prefixText: '€ '),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty))
                return 'Obbligatorio';
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) return 'Numero non valido';
              // UX: Aggiungere validazione logica
              if (_maxAmountController.text.isNotEmpty &&
                  int.tryParse(value ?? '') != null &&
                  int.parse(value!) > int.parse(_maxAmountController.text)) {
                return 'Min > Max';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _maxAmountController,
            decoration: const InputDecoration(
                labelText: 'Importo Max', prefixText: '€ '),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty))
                return 'Obbligatorio';
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) return 'Numero non valido';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

