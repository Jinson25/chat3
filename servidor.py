import socket
import threading

def handle_client(client_socket, client_address):
    try:
        nombre = client_socket.recv(1024).decode('utf-8')
        print(f"Conexión establecida desde {client_address}. Nombre: {nombre}")

        if nombre != "#lista_clientes":
            clients.append((nombre, client_socket))

        while True:
            mensaje = client_socket.recv(1024).decode('utf-8')
            if not mensaje:
                print(f"{nombre} se ha desconectado.")
                break

            print(f"{nombre} dice: {mensaje}")

            # Verificar si el mensaje es un comando especial
            if mensaje == "#lista_clientes":
                lista_clientes = [client[0] for client in clients]
                client_socket.send("LISTA_CONECTADOS:".encode() + ','.join(lista_clientes).encode())
            elif mensaje.startswith("@"):
                # Procesar mensaje privado
                partes = mensaje.split(" ", 1)
                destinatario = partes[0][1:]
                mensaje_contenido = partes[1] if len(partes) > 1 else ""
                enviar_mensaje_privado(destinatario, mensaje_contenido, nombre)
            else:
                # Mensaje general
                send_to_all(f"{nombre}: {mensaje}", client_socket)

    except socket.error as e:
        print(f"Error de conexión con {nombre}: {e}")
    finally:
        for client in clients:
            if client[1] == client_socket:
                clients.remove(client)
                break
        client_socket.close()

def enviar_mensaje_privado(destinatario, mensaje, remitente):
    destinatario_encontrado = False
    for client in clients:
        if client[0] == destinatario:
            try:
                client[1].send(f"@{remitente} (privado): {mensaje}".encode('utf-8'))
                destinatario_encontrado = True
            except socket.error as e:
                print(f"Error al enviar mensaje privado a {destinatario}: {e}")
                clients.remove(client)
                break

    if not destinatario_encontrado:
        print(f"El destinatario '{destinatario}' no se encuentra en la lista de clientes.")

def send_to_all(message, sender_socket):
    if message.startswith("@"):  # Si es un mensaje privado
        parts = message.split(" ", 1)
        destinatario = parts[0][1:]
        mensaje = parts[1] if len(parts) > 1 else ""
        for client in clients.copy():
            if client[0] == destinatario:
                try:
                    client[1].send(f"@{destinatario}: {mensaje}".encode('utf-8'))
                except socket.error as e:
                    print(f"Error al enviar mensaje privado a {destinatario}: {e}")
                    clients.remove(client)
                    break
    else:  # Mensaje general
        for client in clients.copy():
            try:
                if client[1] != sender_socket:
                    client[1].send(message.encode('utf-8'))
            except socket.error as e:
                print(f"Error al enviar mensaje a un cliente: {e}")
                clients.remove(client)

# En el bloque principal, inicializa la lista de clientes
clients = []

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
local_ip = socket.gethostbyname(socket.gethostname())
port = 5555
server.bind((local_ip, port))
server.listen(5)

print(f"Servidor iniciado en {local_ip}:{port}. Esperando conexiones...")

while True:
    client_socket, addr = server.accept()
    print(f"Conexión establecida desde {addr}")

    client_handler = threading.Thread(target=handle_client, args=(client_socket, addr))
    client_handler.start()
