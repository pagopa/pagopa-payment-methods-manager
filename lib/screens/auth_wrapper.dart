// lib/screens/auth_wrapper.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:payment_methods_manager/screens/login_screen.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Stato per gestire il caricamento iniziale
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Inizializza l'autenticazione solo se siamo su piattaforma Web
    if (kIsWeb) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
    }
    // Una volta finito, ferma il caricamento
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se stiamo ancora inizializzando, mostra una schermata di caricamento
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Ascolta i cambiamenti nel servizio di autenticazione
    final authService = context.watch<AuthService>();

    // Se l'utente è autenticato, mostra la schermata principale,
    // altrimenti mostra la schermata di login.
    if (authService.isAuthenticated) {
      return FutureBuilder<String>(future: authService.getAccessToken(), builder: (context, AsyncSnapshot<String> snapshot) {
        return PaymentListScreen(token: snapshot.data ?? '-');

      });
    } else {
      return PaymentListScreen(token: '',);
    }
  }
}