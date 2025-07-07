import 'package:flutter/foundation.dart';
import 'package:msal_js/msal_js.dart';

class AuthService extends ChangeNotifier {
  static const String _clientId = '156820bb-8193-4cc8-86a8-b710fb6b6756'; // <-- INSERISCI QUI
  static const String _authority = 'https://login.microsoftonline.com/7788edaf-0346-4068-9d79-c868aed15b3d'; // <-- INSERISCI QUI

  PublicClientApplication? _msal;
  AccountInfo? _account;

  AccountInfo? get account => _account;
  bool get isAuthenticated => _account != null;

  Future<void> initialize() async {
    // Evita la doppia inizializzazione
    if (_msal != null) return;

    final config = Configuration()
      ..auth = (BrowserAuthOptions()..clientId = _clientId ..authority = _authority ..redirectUri = Uri.base.toString())
      ..cache = (CacheOptions()..cacheLocation = BrowserCacheLocation.localStorage);

    _msal = PublicClientApplication(config);
    await _msal!.handleRedirectFuture();

    final accounts = _msal!.getAllAccounts();
    if (accounts.isNotEmpty) {
      _account = accounts.first;
      notifyListeners();
    }
  }

  Future<void> login() async {
    try {
      await _msal!.loginRedirect(RedirectRequest()..scopes = ['user.read']);
    } catch (e) {
      debugPrint('Errore di login: $e');
    }
  }

  Future<void> logout() async {
    await _msal?.logoutRedirect();
    _account = null;
    notifyListeners();
  }

  Future<String> getAccessToken() async {
    if (_account == null) return '-';
    try {
      final response = await _msal!.acquireTokenSilent(SilentRequest()..account = _account! ..scopes = ['user.read']);
      return response.accessToken;
    } catch (e) {
      // Se il token silente fallisce, prova con un redirect
      debugPrint('Acquisizione token silente fallita: $e');
      try {
        await _msal!.acquireTokenRedirect(RedirectRequest()..scopes = ['user.read']);
      } catch (redirectError) {
        debugPrint('Acquisizione token con redirect fallita: $redirectError');
      }
      return '-';
    }
  }
}