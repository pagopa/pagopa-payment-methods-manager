// lib/main.dart

// 1. Aggiungi questo import!
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:payment_methods_manager/providers/payment_provider.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';
import 'package:payment_methods_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

// Il tuo "ponte" da JS a Dart rimane identico
final ValueNotifier<AppConfig> configNotifier = ValueNotifier(AppConfig());

class AppConfig {
  final String jwt;
  final String host;

  AppConfig({this.jwt = '', this.host = ''});
}

@JS('updateConfig')
void updateConfig(String jwt, String host) {
  print('DART RICEVE: Nuovo config -> JWT: $jwt, Host: $host');

  // Aggiorna il nostro notifier con un nuovo oggetto AppConfig.
  configNotifier.value = AppConfig(jwt: jwt, host: host);
}

// 2. Modifica la funzione main in questo modo
void main() {
  // Questo è il nuovo entry point corretto per le app Flutter
  // che vengono integrate in un elemento specifico del DOM.
  // Si assicura che l'engine sia pronto e collegato a una vista
  // prima di eseguire runApp.
  print('MAIN');
  web.window.setProperty('updateConfig'.toJS, updateConfig.toJS);
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
        ValueListenableProvider<AppConfig>.value(value: configNotifier),
        ChangeNotifierProxyProvider<AppConfig, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (context, config, previousProvider) {
            // Quando la configurazione cambia, aggiorna il tuo provider
            // passando sia il jwt che l'host.
            return previousProvider!
              ..updateConfig(jwt: config.jwt, host: config.host);
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
