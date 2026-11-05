import 'package:flutter/material.dart';

import '../export/download_csv.dart';

/// Condivide stato di avanzamento ed errori tra i due export.
/// Il file viene scaricato solo dopo il completamento di tutte le richieste.
class CsvExportButton extends StatefulWidget {
  final String filename;
  final Future<String> Function() createCsv;
  final Future<void> Function(String, String) save;
  final bool enabled;

  const CsvExportButton({
    super.key,
    required this.filename,
    required this.createCsv,
    this.enabled = true,
    this.save = downloadCsv,
  });

  @override
  State<CsvExportButton> createState() => _CsvExportButtonState();
}

class _CsvExportButtonState extends State<CsvExportButton> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final content = await widget.createCsv();
      if (!mounted) return;
      await widget.save(widget.filename, content);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export non completato: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: widget.enabled && !_exporting ? _export : null,
        icon: _exporting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download),
        label: Text(_exporting ? 'Esportazione...' : 'Esporta CSV'),
      );
}
