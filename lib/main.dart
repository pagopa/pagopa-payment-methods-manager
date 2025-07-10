import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:payment_methods_manager/providers/api_provider.dart';
import 'package:payment_methods_manager/screens/Structure.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';
import 'package:payment_methods_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

final ValueNotifier<AppConfig> configNotifier = ValueNotifier(AppConfig());

class AppConfig {
  final String jwt;
  final String host;

  AppConfig({this.jwt = '', this.host = ''});
}

@JS('updateConfig')
void updateConfig(String jwt, String host) {
  configNotifier.value = AppConfig(jwt: jwt, host: host);
}

void main() {
  web.window.setProperty('updateConfig'.toJS, updateConfig.toJS);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ValueListenableProvider<AppConfig>.value(value: configNotifier),
        ChangeNotifierProxyProvider<AppConfig, ApiProvider>(
          create: (_) => ApiProvider(),
          update: (context, config, previousProvider) {

            return previousProvider!
              ..updateConfig(jwt: config.jwt, host: config.host);
          },
        ),
      ],
      child: MaterialApp(
        title: 'PagoPA Payment Methods',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const Structure(),
      ),
    );
  }
}