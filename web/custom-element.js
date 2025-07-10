// custom-element.js

const FLUTTER_BASE_URL = 'https://pagopa.github.io/pagopa-payment-methods-manager';

const loadFlutterScript = new Promise((resolve, reject) => {
  if (window._flutter) {
    resolve(window._flutter);
    return;
  }
  const script = document.createElement('script');
  script.src = `${FLUTTER_BASE_URL}/flutter.js`;
  script.defer = true;
  script.onload = () => {
    window._flutter.loader.loadEntrypoint({
      entrypointUrl: `${FLUTTER_BASE_URL}/main.dart.js`,
      onEntrypointLoaded: (engineInitializer) => {
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
    try {
      const engineInitializer = await loadFlutterScript;

      this._app = await engineInitializer.initializeEngine({
        hostElement: this.hostElement,
        assetBase: FLUTTER_BASE_URL + '/'
      });

      this._app.runApp();

      if (this.hasAttribute('jwt') && this.hasAttribute('host')) {
        this.updateFlutterMessage(this.getAttribute('jwt'), this.getAttribute('host'));
      }
    } catch (e) {
      console.error('JS: ERRORE CRITICO durante l\'avvio di Flutter:', e);
    }
  }

  static get observedAttributes() {
    return ['jwt', 'host'];
  }

  attributeChangedCallback(name, oldValue, newValue) {
      if ((name === 'jwt' || name === 'host') && oldValue !== newValue && this._app) {
        const currentJwt = this.getAttribute('jwt');
        const currentHost = this.getAttribute('host');

        if (currentJwt && currentHost) {
          this.updateFlutterMessage(currentJwt, currentHost);
        }
      }
    }

  updateFlutterMessage(jwt, host) {
    // La strategia di polling è ancora la più sicura
    const checkAndUpdate = () => {
      if (window.updateConfig) {
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