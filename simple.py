from http.server import SimpleHTTPRequestHandler, HTTPServer
from pathlib import Path
import socket

def create_media_folder():
    home_dir = Path.home()
    downloads_dir = home_dir / "Downloads"
    media_dir = downloads_dir / "media"
    
    if not media_dir.exists():
        media_dir.mkdir(parents=True)

    return media_dir

# Créer le dossier media
media_dir = create_media_folder()

# Définir le répertoire de base pour le serveur HTTP
class CustomHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Définir le chemin racine pour servir les fichiers
        path = super().translate_path(path)
        relpath = Path(path).relative_to(Path.cwd())
        return str(media_dir / relpath)

# Configuration du serveur
server_address = ('', 8000)  # Écoute sur le port 8000
httpd = HTTPServer(server_address, CustomHandler)

# Obtenir l'adresse IP locale
hostname = socket.gethostname()
local_ip = socket.gethostbyname(hostname)

print(f"Serving HTTP on http://{local_ip}:8000 from {media_dir}...")

# Démarrer le serveur
httpd.serve_forever()
