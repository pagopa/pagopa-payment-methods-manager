// Widget per gestire una lista di stringhe (es. Target)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DynamicStringListFields extends StatefulWidget {
  final String title;
  final List<String> listData;
  final Function(List<String>) onChanged;
  final FormFieldValidator<List<String>>? validator;

  const DynamicStringListFields({
    required this.title,
    required this.listData,
    required this.onChanged,
    this.validator,
  });

  @override
  _DynamicStringListFieldsState createState() =>
      _DynamicStringListFieldsState();
}

class _DynamicStringListFieldsState extends State<DynamicStringListFields> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.listData
        .map((item) => TextEditingController(text: item))
        .toList();
  }

  @override
  void didUpdateWidget(covariant DynamicStringListFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listData.length != _controllers.length) {
      _controllers = widget.listData
          .map((item) => TextEditingController(text: item))
          .toList();
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
                    Expanded(
                        child: TextFormField(
                            controller: _controllers[index],
                            onChanged: (_) => _updateParent())),
                    IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _controllers.removeAt(index).dispose();
                            _updateParent();
                          });
                        }),
                  ],
                );
              }),
              if (state.hasError)
                Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(state.errorText!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12))),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                  onPressed: () {
                    setState(() => _controllers.add(TextEditingController()));
                    _updateParent();
                  }),
            ],
          );
        });
  }
}

