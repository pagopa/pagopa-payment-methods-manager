import 'package:flutter/foundation.dart';
import 'package:msal_js/msal_js.dart';

class AuthService extends ChangeNotifier {
  static const String _clientId = 'IL_TUO_CLIENT_ID_AZURE'; // <-- INSERISCI QUI
  static const String _authority = 'https://login.microsoftonline.com/IL_TUO_TENANT_ID'; // <-- INSERISCI QUI

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