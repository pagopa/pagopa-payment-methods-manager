import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_methods_manager/widget/csv_export_button.dart';

void main() {
  testWidgets('button waits for all records and prevents duplicate downloads',
      (tester) async {
    final pending = Completer<String>();
    final downloads = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: CsvExportButton(
        filename: 'pacchetti.csv',
        createCsv: () => pending.future,
        save: (filename, content) async => downloads.add('$filename:$content'),
      ),
    )));
    await tester.tap(find.text('Esporta CSV'));
    await tester.pump();
    expect(find.text('Esportazione...'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull);
    expect(downloads, isEmpty);
    pending.complete('complete-csv');
    await tester.pumpAndSettle();
    expect(downloads, ['pacchetti.csv:complete-csv']);
    expect(find.text('Esporta CSV'), findsOneWidget);
  });

  testWidgets(
      'a failed export shows an error without downloading a partial file',
      (tester) async {
    var downloaded = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: CsvExportButton(
        filename: 'pacchetti.csv',
        createCsv: () async => throw StateError('page failed'),
        save: (_, __) async {
          downloaded = true;
        },
      ),
    )));
    await tester.tap(find.text('Esporta CSV'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Export non completato'), findsOneWidget);
    expect(downloaded, false);
  });
}
