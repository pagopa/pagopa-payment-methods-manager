// lib/main.dart
import 'package:flutter/material.dart';
import 'package:payment_methods_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/payment_provider.dart';
import 'screens/payment_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaymentProvider(),
      child: MaterialApp(
        title: 'PagoPA Payment Methods',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme, // <-- APPLICA IL TEMA
        home: const PaymentListScreen(),
      ),
    );
  }
}