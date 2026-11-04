# payment_methods_manager

Payment Methods Manager

## Consultazione e filtri

Le schermate **Metodi di pagamento** e **Pacchetti commissionali** mantengono le
funzioni gestionali esistenti e aggiungono filtri combinabili, applicati con
**Applica** e rimossi con **Resetta**. I filtri restano impostati passando tra tab.

- Metodi: nome/ID, touchpoint, gestione (in particolare `REDIRECT`), stato, gruppo,
  categoria e device. IO, CHECKOUT e CHECKOUT_CART rimangono distinti.
- Pacchetti: nome, tipo GLOBAL/PUBLIC/PRIVATE, stato, touchpoint, tipo pagamento,
  PSP per ID o nome, importo del pagamento, commissione, tassonomia, ente,
  canale/broker e flag tecnici.

Il catalogo descrive la **configurazione**, non garantisce la disponibilita' di un
metodo o l'applicabilita' di una commissione per un pagamento. Importi e fee sono
visualizzati in euro e trasmessi come centesimi interi. Il filtro importo dei
pacchetti usa l'intervallo **(minimo, massimo]**, coerente con la query calculator:
minimo escluso, massimo incluso. La tassonomia in lista filtra il valore
configurato esatto, non interpreta le regole specifiche dell'ente.

La ricerca pacchetti percorre tutte le pagine necessarie ai filtri locali, con
richieste sequenziali e possibilita' di interruzione. Avanzamento e risultati
parziali sono espliciti; un errore non viene presentato come un elenco completo
vuoto. "Tutti" richiede esplicitamente tutti e tre i tipi, evitando il default
GLOBAL del backend. Con un ente specificato vengono mostrati i pacchetti associati
e i GLOBAL: questo non sostituisce la selezione del calculator. Il dettaglio
mostra gli attributi ente disponibili, comprese le relazioni EQUAL/NOT_EQUAL.

Le funzionalita' di consultazione utilizzano esclusivamente le API marketplace.
Non sono presenti simulazioni o confronti delle commissioni tramite calculator.
La configurazione di accesso marketplace per lo sviluppo locale resta invariata.

### Sviluppo

```sh
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter build web
```

Le suite in `test/` usano risposte HTTP simulate e non contattano ambienti pagoPA.
Le specifiche di riferimento sono
[marketplace](https://raw.githubusercontent.com/pagopa/pagopa-afm-marketplace-be/refs/heads/main/openapi/openapi.json)
e [calculator internal](https://raw.githubusercontent.com/pagopa/pagopa-afm-calculator/refs/heads/main/openapi/openapi-internal.json).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
