# server_with_cors.py
import http.server
import socketserver

PORT = 8000 # La porta su cui vuoi servire i file di Flutter

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Aggiungi qui l'header CORS
        # Per lo sviluppo, puoi usare '*' ma è meglio specificare l'origine
        # della tua app React (es. 'http://localhost:3000')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
    print("Servendo file di Flutter su porta", PORT, "con CORS abilitato")
    httpd.serve_forever()