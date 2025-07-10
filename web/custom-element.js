// custom-element.js

const FLUTTER_BASE_URL = 'https://pagopa.github.io/pagopa-payment-methods-manager';

const loadFlutterScript = new Promise((resolve, reject) => {
  console.log("JS: Inizio caricamento script Flutter.");
  if (window._flutter) {
    console.log("JS: _flutter già presente.");
    resolve(window._flutter);
    return;
  }
  const script = document.createElement('script');
  script.src = `${FLUTTER_BASE_URL}/flutter.js`;
  script.defer = true;
  script.onload = () => {
    console.log("JS: flutter.js caricato. Carico entrypoint...");
    window._flutter.loader.loadEntrypoint({
      entrypointUrl: `${FLUTTER_BASE_URL}/main.dart.js`,
      onEntrypointLoaded: (engineInitializer) => {
        console.log("JS: Entrypoint caricato. Risolvo la Promise.");
        resolve(engineInitializer);
      }
    }).catch(reject);
  };
  script.onerror = (err) => {
    console.error("JS: Errore caricamento flutter.js", err);
    reject(err);
  };
  document.head.appendChild(script);
});

class MyFlutterWidget extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.hostElement = document.createElement('div');
    this.hostElement.style.width = '100%';
    this.hostElement.style.height = '100%';
    this.shadowRoot.appendChild(this.hostElement);
    this._app = null;
  }

  async connectedCallback() {
    console.log("JS: Elemento connesso al DOM. Inizio processo di avvio.");
    try {
      const engineInitializer = await loadFlutterScript;
      console.log("JS: engineInitializer ottenuto. Inizializzo l'engine...");

      this._app = await engineInitializer.initializeEngine({
        hostElement: this.hostElement,
        assetBase: FLUTTER_BASE_URL + '/'
      });

      console.log("JS: Engine inizializzato. Chiamo runApp()...");

      // === IL PASSAGGIO CHIAVE ===
      // Avviamo esplicitamente l'app Flutter.
      // Questa chiamata eseguirà la funzione main() in Dart.
      this._app.runApp();

      console.log("JS: runApp() chiamato. L'app Flutter dovrebbe essere partita.");

      // Ora che l'app è in esecuzione, possiamo passare i dati.
        if (this.hasAttribute('jwt') && this.hasAttribute('host')) {
        this.updateFlutterMessage(this.getAttribute('jwt'), this.getAttribute('host'));
      }
    } catch (e) {
      console.error('JS: ERRORE CRITICO durante l\'avvio di Flutter:', e);
    }
  }

  static get observedAttributes() {
    return ['jwt'];
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (name === 'jwt' && oldValue !== newValue && this._app) {
      this.updateFlutterMessage(newValue);
    }
  }

  updateFlutterMessage(jwt, host) {
    // La strategia di polling è ancora la più sicura
    const checkAndUpdate = () => {
      if (window.updateConfig) {
        console.log(`JS: ✅ Trovato window.updateJwt. Invio jwt`);
        window.updateConfig(jwt, host);
      } else {
        console.warn("JS: ⏳ window.updateJwt non ancora pronto, riprovo tra 50ms...");
        setTimeout(checkAndUpdate, 50);
      }
    };
    checkAndUpdate();
  }

  disconnectedCallback() {
    console.log('MyFlutterWidget rimosso dal DOM.');
  }
}

customElements.define('payment-methods-manager', MyFlutterWidget);