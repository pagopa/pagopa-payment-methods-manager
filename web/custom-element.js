// custom-element.js

// L'URL base dove risiede la nostra app Flutter
const FLUTTER_BASE_URL = 'http://localhost:8000'; // <-- MODIFICA QUI

const loadFlutterScript = new Promise((resolve, reject) => {
  if (window._flutter) {
    resolve(window._flutter);
    return;
  }
  const script = document.createElement('script');
  // Usa l'URL assoluto
  script.src = `${FLUTTER_BASE_URL}/flutter.js`;
  script.defer = true;
  script.onload = () => {
    _flutter.loader.loadEntrypoint({
      // Specifica l'URL base anche qui per le risorse (es. canvaskit, assets)
      entrypointUrl: `${FLUTTER_BASE_URL}/main.dart.js`,
      onEntrypointLoaded: (engineInitializer) => {
        resolve(engineInitializer);
      }
    });
  };
  script.onerror = reject;
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

  // Chiamato quando l'elemento viene aggiunto al DOM
  async connectedCallback() {
    const engineInitializer = await loadFlutterScript;

    // Inizializza l'app Flutter dentro il nostro 'div'
    this._app = await engineInitializer.initializeEngine({
      hostElement: this.hostElement,
      assetBase: `${FLUTTER_BASE_URL}/`

    });

    // Avvia l'app Flutter
    this._app.runApp();

    // Passa il valore iniziale dell'attributo 'message'
    if (this.hasAttribute('message')) {
      this.updateFlutterMessage(this.getAttribute('message'));
    }
  }

  // Definisce quali attributi osservare per i cambiamenti
  static get observedAttributes() {
    return ['message'];
  }

  // Chiamato quando un attributo osservato cambia
  attributeChangedCallback(name, oldValue, newValue) {
    if (name === 'message' && oldValue !== newValue) {
      this.updateFlutterMessage(newValue);
    }
  }

  // Funzione helper per chiamare la nostra funzione Dart esportata
  updateFlutterMessage(message) {
      // Aspettiamo che la funzione `updateJwt` sia disponibile su `window`
      // (potrebbe non esserlo immediatamente al caricamento)
      const checkAndUpdate = () => {
        if (window.updateJwt) {
            window.updateJwt(message);
        } else {
            setTimeout(checkAndUpdate, 50); // Riprova tra 50ms
        }
      }
      checkAndUpdate();
  }

  // Chiamato quando l'elemento viene rimosso dal DOM
  disconnectedCallback() {
    // Qui potresti aggiungere logica di pulizia se necessario
    console.log('MyFlutterWidget rimosso dal DOM.');
  }
}

// Definisce il nuovo tag HTML
customElements.define('my-flutter-widget', MyFlutterWidget);