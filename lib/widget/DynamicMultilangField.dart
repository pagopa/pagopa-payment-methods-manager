// --- NUOVO WIDGET DINAMICO PER CAMPI MULTILINGUA ---
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
const Map<String, String> _availableLanguages = {
  'EN': 'Inglese',
  'DE': 'Tedesco',
  'FR': 'Francese',
  'ES': 'Spagnolo',
};

class DynamicMultilangField extends StatefulWidget {
  final String label;
  final Map<String, String> initialData;
  final Function(Map<String, String>) onChanged;
  final bool isRequired;
  final bool isMultiline;

  const DynamicMultilangField({
    required this.label,
    required this.initialData,
    required this.onChanged,
    this.isRequired = false,
    this.isMultiline = false,
  });

  @override
  __DynamicMultilangFieldState createState() => __DynamicMultilangFieldState();
}

class __DynamicMultilangFieldState extends State<DynamicMultilangField> {
  late Map<String, String> _data;
  final _itController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clona la mappa per non modificare direttamente lo stato del genitore
    _data = Map<String, String>.from(widget.initialData);
    _itController.text = _data['IT'] ?? '';

    // Ascolta le modifiche del controller per l'italiano
    _itController.addListener(() {
      _updateData('IT', _itController.text);
    });
  }

  @override
  void dispose() {
    _itController.dispose();
    super.dispose();
  }

  void _updateData(String langCode, String value) {
    setState(() {
      _data[langCode] = value;
    });
    widget.onChanged(_data);
  }

  void _addLanguage(String langCode) {
    setState(() {
      _data[langCode] = '';
    });
    widget.onChanged(_data);
  }

  void _removeLanguage(String langCode) {
    setState(() {
      _data.remove(langCode);
    });
    widget.onChanged(_data);
  }

  Future<void> _showAddLanguageDialog() async {
    // Filtra le lingue già in uso
    final selectableLanguages = _availableLanguages.entries
        .where((entry) => !_data.containsKey(entry.key))
        .toList();

    if (selectableLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Tutte le lingue disponibili sono già state aggiunte.')),
      );
      return;
    }

    String? selectedLangCode = selectableLanguages.first.key;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Lingua'),
          content: DropdownButtonFormField<String>(
            value: selectedLangCode,
            items: selectableLanguages.map((entry) {
              return DropdownMenuItem(
                  value: entry.key, child: Text(entry.value));
            }).toList(),
            onChanged: (value) => selectedLangCode = value,
            decoration: const InputDecoration(labelText: 'Lingua'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedLangCode),
              child: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _addLanguage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Genera la lista dei campi per le lingue diverse dall'italiano
    final otherLanguageFields =
    _data.entries.where((entry) => entry.key != 'IT').map((entry) {
      final langName = _availableLanguages[entry.key] ?? entry.key;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextFormField(
          initialValue: entry.value,
          maxLines: widget.isMultiline ? 3 : 1,
          decoration: InputDecoration(
            labelText: langName,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              onPressed: () => _removeLanguage(entry.key),
            ),
          ),
          onChanged: (value) => _updateData(entry.key, value),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // Campo fisso per l'italiano
        TextFormField(
          controller: _itController,
          maxLines: widget.isMultiline ? 3 : 1,
          decoration: const InputDecoration(
            labelText: 'Italiano (obbligatorio)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (widget.isRequired && (value == null || value.isEmpty)) {
              return 'Il campo in italiano è obbligatorio';
            }
            return null;
          },
        ),
        // Lista dei campi per le altre lingue
        ...otherLanguageFields,
        const SizedBox(height: 8),
        // Bottone per aggiungere nuove lingue
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi lingua'),
            onPressed: _showAddLanguageDialog,
          ),
        ),
      ],
    );
  }
}
