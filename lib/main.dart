// lib/main.dart
import 'package:flutter/foundation.dart'; // Importa kIsWeb
import 'package:flutter/material.dart';
import 'package:payment_methods_manager/screens/auth_wrapper.dart';
import 'package:payment_methods_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'providers/payment_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa MultiProvider per fornire tutti i servizi/provider necessari
    return MultiProvider(
      providers: [
        // Fornisce il servizio di autenticazione all'intera app
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Il tuo provider esistente
        ChangeNotifierProvider(create: (_) => PaymentProvider()),

        // Potresti anche fare in modo che PaymentProvider dipenda da AuthService
        // per passare i token di accesso alle API, usando ChangeNotifierProxyProvider
      ],
      child: MaterialApp(
        title: 'PagoPA Payment Methods',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        // La nostra home ora è l'AuthWrapper, che deciderà cosa mostrare
        home: const AuthWrapper(),
      ),
    );
  }
}