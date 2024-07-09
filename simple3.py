from http.server import SimpleHTTPRequestHandler, HTTPServer
from pathlib import Path
import socket
import json

def create_media_folder():
    home_dir = Path.home()
    downloads_dir = home_dir / "Downloads"
    media_dir = downloads_dir / "media"
    
    if not media_dir.exists():
        media_dir.mkdir(parents=True)

    return media_dir

# Créer le dossier media
media_dir = create_media_folder()

# Définir le chemin du fichier index.html
current_dir = Path(__file__).parent
index_file = current_dir / "index.html"

class CustomHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Définir le chemin racine pour servir les fichiers
        path = super().translate_path(path)
        relpath = Path(path).relative_to(Path.cwd())
        return str(media_dir / relpath)

    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
            self.serve_index()
        elif self.path == '/files':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            file_list = [
                {"name": f.name, "url": f"/{f.name}"}
                for f in media_dir.iterdir() if f.is_file()
            ]
            self.wfile.write(json.dumps({"files": file_list}).encode())
        else:
            return super().do_GET()

    def serve_index(self):
        try:
            with open(index_file, 'rb') as file:
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(file.read())
        except Exception as e:
            self.send_error(404, f"File not found: {self.path}")

    def end_headers(self):
        if not self.path.endswith('/index.html') and not self.path.endswith('/files'):
            self.send_header('Content-Disposition', 'attachment')
        super().end_headers()

# Configuration du serveur
server_address = ('', 8000)  # Écoute sur le port 8000
httpd = HTTPServer(server_address, CustomHandler)

# Obtenir l'adresse IP locale
hostname = socket.gethostname()
local_ip = socket.gethostbyname(hostname)

print(f"Serving HTTP on http://{local_ip}:8000 from {media_dir}...")

# Démarrer le serveur
httpd.serve_forever()
