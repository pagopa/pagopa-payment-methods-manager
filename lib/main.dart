// lib/main.dart

import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
// 1. Importa i pacchetti di interoperabilità JS
import 'dart:js_interop';
import 'package:web/web.dart' as web;




String token = '';

String setToken(String message) {
  print('Received message: $message');
  token = message;
  return message;
}

// Punto di ingresso dell'applicazione.
void main() {

  web.window.setProperty('setToken'.toJS, setToken.toJS);


  // Avvia l'app Flutter
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // L'app ora accetta il controller per passarlo al widget figlio.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Component',
      debugShowCheckedModeBanner: false,
      home: MessageDisplayWidget(),
    );
  }
}

class MessageDisplayWidget extends StatefulWidget {
  // Il widget riceve il controller per collegare la sua UI.
  const MessageDisplayWidget({super.key});

  @override
  State<MessageDisplayWidget> createState() => _MessageDisplayWidgetState();
}

class _MessageDisplayWidgetState extends State<MessageDisplayWidget> {
  String _message = "In attesa di un messaggio da React...";

  @override
  void initState() {
    super.initState();

    setState(() {
      _message = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    // La UI rimane identica
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$token",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}