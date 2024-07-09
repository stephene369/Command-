import http.server
import socketserver
import os
import socket
import ssl
import logging
from pathlib import Path
from qfluentwidgets import HyperlinkButton

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

def create_media_folder():
    home_dir = Path.home()
    downloads_dir = home_dir / "Downloads"
    media_dir = downloads_dir / "media"
    
    if not media_dir.exists():
        media_dir.mkdir(parents=True)

    return media_dir

class CustomHandler(http.server.SimpleHTTPRequestHandler):

    def do_GET(self):
        self.directory_to_serve = create_media_folder()


        style = """ 
*{
    border: 0;
    padding: 0;
    font-family: 'Courier New', Courier, monospace;
    box-sizing: border-box;
}
body{
    width: 100%;
    min-height: 100vh;
    background: linear-gradient(180deg , #ffffff , #bfbeff);
    position: relative;

}
h1{
    color: blue;
}

h4{
    font-size: 15px;
}
.file{
    padding-top: 10px;
    padding-right: 20px;
    display: flex;
    align-items: center;
}
.file span{
    font-size: 20px;
}
.file button{
    font-family: 30px;
    padding-left: 10px;
    padding-right: 10px;
    color: rgb(0, 17, 255);
    background: transparent;
    border: solid 1px rgba(245, 245, 245, 0.397);
    border-radius: 3px;
}
span{
    font-size: 20px;
}
button{
    font-size: 22px;
    font-weight: 0px;
    cursor: pointer;
}
"""


        logging.debug(f"Requête reçue pour {self.path}")
        if self.path == '/':

            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(f"""
                <html>
                <head><title>Serveur</title></head>
                <body>

                    <style>
                        {style}
                    </style>
                                                
                <h1>Available Files</h1>
                <div class="container">
            """.encode())

            for file_name in sorted(os.listdir(self.directory_to_serve)):
                if os.path.isfile(os.path.join(self.directory_to_serve, file_name)):
                    self.wfile.write(f'''
                                
<div class="file">

    <span> - {file_name} </span>
    <a href="/{file_name}"> 
        <button>
                Download 
        </button>
    </a>
    <h4>
    ({os.path.getsize( os.path.join(self.directory_to_serve, file_name) )/1000 } Mo)
    </h4>
</div>              
'''.encode())
                    
            self.wfile.write(b"""
                    </div>
                </body>
                </html>
            """)
            logging.debug("Liste des fichiers envoyée.")
        else:
            try:
                self.send_response(200)
                self.send_header('Content-type', 'application/octet-stream')
                self.send_header('Content-Disposition', f'attachment; filename="{os.path.basename(self.path)}"')
                self.end_headers()
                with open(self.path[1:], 'rb') as file:
                    self.wfile.write(file.read())
                logging.debug(f"Fichier {self.path[1:]} téléchargé.")
            except FileNotFoundError:
                self.send_error(404, f'Fichier non trouvé: {self.path}')
                logging.error(f"Fichier non trouvé: {self.path}")




class FileServer :
    def __init__(self) -> None:
        pass 

    def get_local_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80)) 
            local_ip_address = s.getsockname()[0]
            s.close()
            return local_ip_address
        except socket.error:
            return '127.1.1.1'



    def find_available_port(self, start_port):
        port = start_port
        while True:
            try:
                with socketserver.TCPServer(("", port), CustomHandler) as httpd:
                    return port, httpd
            except OSError as e:
                if e.errno == 98:
                    port += 1
                else:
                    raise

    def launchServer(self , hyperlink:HyperlinkButton=None) :
        self.local_ip = self.get_local_ip()
        port, httpd = self.find_available_port(2020)
        self.port = port

        with socketserver.TCPServer(("", port), CustomHandler) as httpd:
            # Créer un contexte SSL
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)


            # Envelopper le socket du serveur avec SSL
            #httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

            logging.info(f"Serveur démarré sur le port {port}")
            logging.info(f"Répertoire servi : {os.getcwd()}")
            logging.info(f"Pour accéder au serveur, ouvrez un navigateur web et allez à l'adresse :")
            if hyperlink : 
                hyperlink.setUrl(f"http://{self.local_ip}:{self.port}/")
                hyperlink.setText(f"http://{self.local_ip}:{self.port}/")

            logging.info(f"http://{self.local_ip}:{port}/")

            httpd.serve_forever()

server = FileServer()
server.launchServer()

