# payment_methods_manager

Payment Methods Manager

## Consultazione e filtri

Le schermate **Metodi di pagamento** e **Pacchetti commissionali** mantengono le
funzioni gestionali esistenti e aggiungono filtri combinabili, applicati con
**Applica** e rimossi con **Resetta**. I filtri restano impostati passando tra tab.

- Metodi: nome/ID, touchpoint, gestione (in particolare `REDIRECT`), stato, gruppo,
  categoria e device. IO, CHECKOUT e CHECKOUT_CART rimangono distinti.
- Pacchetti: nome, ID esatto, tipo GLOBAL/PUBLIC/PRIVATE, stato, touchpoint, tipo pagamento,
  PSP per ID o nome, importo del pagamento, commissione, tassonomia, ente,
  canale/broker e flag tecnici.

Il catalogo descrive la **configurazione**, non garantisce la disponibilita' di un
metodo o l'applicabilita' di una commissione per un pagamento. Importi e fee sono
visualizzati in euro e trasmessi come centesimi interi. Il filtro importo dei
pacchetti usa l'intervallo **(minimo, massimo]**, coerente con la query calculator:
minimo escluso, massimo incluso. La tassonomia in lista filtra il valore
configurato esatto, non interpreta le regole specifiche dell'ente.

La lista pacchetti carica progressivamente i risultati con infinite scroll,
senza mostrare numeri di pagina o riepiloghi dei filtri applicati. Se i filtri
locali escludono un'intera pagina, la ricerca prosegue fino al prossimo risultato
o alla fine dei dati. Un errore mantiene i risultati caricati e permette di
riprovare. "Tutti" richiede esplicitamente tutti e tre i tipi, evitando il default
GLOBAL del backend. Con un ente specificato vengono mostrati i pacchetti associati
e i GLOBAL: questo non sostituisce la selezione del calculator. Il dettaglio
mostra gli attributi ente disponibili, comprese le relazioni EQUAL/NOT_EQUAL.

Le funzionalita' di consultazione utilizzano esclusivamente le API marketplace.
Non sono presenti simulazioni o confronti delle commissioni tramite calculator.
La configurazione di accesso marketplace per lo sviluppo locale resta invariata.

### Export dei risultati filtrati

Il pulsante **Esporta CSV** in ciascuna schermata scarica solo i record che
rispettano i filtri applicati con **Applica**. Le modifiche ai campi non ancora
applicate non influenzano il file. Senza filtri vengono esportati tutti i record.

Per i pacchetti l'export legge tutte le pagine, comprese quelle non ancora caricate
con l'infinite scroll, usando una fotografia dei filtri al click. Questa lettura
non modifica la lista o la posizione dello scroll. Se cambia l'ambiente o una
richiesta fallisce, l'export segnala l'errore e non scarica un file parziale.

Il CSV usa BOM UTF-8, separatore `;` e terminatori CRLF per Excel. Le intestazioni
corrispondono ai campi API; gli importi sono **centesimi interi**, le date sono nel
formato API e liste/mappe sono serializzate come JSON nella cella, mantenendo
touchpoint e traduzioni. I valori null sono vuoti, distinti da zero e false.
Le celle potenzialmente interpretabili come formule vengono prefissate con un
apostrofo. Il download avviene nel browser, senza servizi esterni o storage locale.

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
