import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Usa un URL temporaneo: i dati non sono inviati a servizi esterni o salvati
/// nello storage del browser. Il ritardo lascia partire il download prima del cleanup.
Future<void> downloadCsv(String filename, String content) async {
  final blob = web.Blob(
      [content.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  try {
    final body = web.document.body;
    if (body == null) throw StateError('Documento non pronto per il download.');
    body.appendChild(anchor);
    anchor.click();
    await Future<void>.delayed(const Duration(seconds: 1));
  } finally {
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
