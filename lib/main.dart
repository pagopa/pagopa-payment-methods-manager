// lib/main.dart

import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:provider/provider.dart';

// 1. Aggiungi questo import!
import 'dart:ui_web' as ui_web;

import 'package:payment_methods_manager/providers/payment_provider.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';
import 'package:payment_methods_manager/theme/app_theme.dart';

// Il tuo "ponte" da JS a Dart rimane identico
final ValueNotifier<String> jwtNotifier = ValueNotifier('');

@JS('updateJwt')
void updateJwt(String jwt) {
  jwtNotifier.value = jwt;
}

// 2. Modifica la funzione main in questo modo
void main() {
  // Questo è il nuovo entry point corretto per le app Flutter
  // che vengono integrate in un elemento specifico del DOM.
  // Si assicura che l'engine sia pronto e collegato a una vista
  // prima di eseguire runApp.
    print('MAIN');
  // ui_web.bootstrapEngine(runApp: () {
    print('RUN APP');
    runApp(const MyApp());
  // });
}

// La tua classe MyApp e tutto il resto del codice rimangono invariati
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ValueListenableProvider<String>.value(value: jwtNotifier),
        ChangeNotifierProxyProvider<String, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (context, jwt, previousProvider) {
            return previousProvider!
              ..updateJwt(jwt);
          },
        ),
      ],
      child: MaterialApp(
        title: 'PagoPA Payment Methods',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const PaymentListScreen(),
      ),
    );
  }
}