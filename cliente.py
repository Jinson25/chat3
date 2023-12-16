import socket
import threading
import tkinter as tk
from tkinter import scrolledtext, simpledialog, messagebox

class ChatGUI:
    def __init__(self, master):
        self.master = master
        self.master.title("Chat Cliente")
        self.private_chat_windows = {}
        self.chat_general = scrolledtext.ScrolledText(self.master, wrap=tk.WORD, width=40, height=15)
        self.chat_general.pack(padx=10, pady=10, side=tk.LEFT)

        self.users_listbox = tk.Listbox(self.master, width=20)
        self.users_listbox.pack(padx=10, pady=10, side=tk.RIGHT)
        self.users_listbox.bind("<<ListboxSelect>>", self.seleccionar_usuario)

        self.refresh_button = tk.Button(self.master, text="Refrescar", command=self.actualizar_usuarios)
        self.refresh_button.pack()

        self.input_entry = tk.Entry(self.master, width=30)
        self.input_entry.pack(pady=10)
        self.input_entry.bind("<Return>", lambda event: self.enviar_mensaje())

        self.send_button = tk.Button(self.master, text="Enviar", command=self.enviar_mensaje)
        self.send_button.pack()

        self.ip_servidor = simpledialog.askstring("IP del Servidor", "Ingresa la IP del servidor:")
        self.puerto_servidor = 5555

        self.socket_cliente = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket_cliente.connect((self.ip_servidor, self.puerto_servidor))

        self.nombre = simpledialog.askstring("Nombre", "Ingresa tu nombre:")
        self.socket_cliente.send(self.nombre.encode())

        self.hilo_envio = threading.Thread(target=self.recibir_mensajes)
        self.hilo_envio.start()

    def enviar_mensaje(self):
        mensaje = self.input_entry.get()
        destinatario = self.users_listbox.get(tk.ACTIVE)
        if destinatario:
            if destinatario.startswith("@"):
                self.enviar_mensaje_seleccionado(destinatario[1:], mensaje)
            else:
                self.chat_general.insert(tk.END, f"[Mensaje general]: {mensaje}\n")
                try:
                    self.socket_cliente.send(mensaje.encode())
                except socket.error:
                    self.chat_general.insert(tk.END, "El servidor se ha cerrado o hay un problema de conexión.\n")
        else:
            self.chat_general.insert(tk.END, "Selecciona un destinatario para enviar un mensaje privado.\n")
        self.input_entry.delete(0, tk.END)

    def recibir_mensajes(self):
        while True:
            try:
                data = self.socket_cliente.recv(1024)
                if not data:
                    break
                mensaje_recibido = data.decode()
                if mensaje_recibido.startswith("LISTA_CONECTADOS:"):
                    self.actualizar_lista_usuarios(mensaje_recibido)
                elif mensaje_recibido.startswith("@"):
                    self.procesar_mensaje_privado(mensaje_recibido)
                else:
                    self.chat_general.insert(tk.END, f"[Mensaje general]: {mensaje_recibido}\n")
                    self.chat_general.see(tk.END)
            except ConnectionResetError:
                self.chat_general.insert(tk.END, "El servidor se ha cerrado o hay un problema de conexión.\n")
                break

    def procesar_mensaje_privado(self, mensaje):
        partes = mensaje.split(" ", 2)
        destinatario = partes[0][1:]
        mensaje_contenido = partes[2]

        if destinatario == self.nombre:
            nombre_emisor = partes[0][1:]
            if nombre_emisor in self.private_chat_windows:
                chat_area = self.private_chat_windows[nombre_emisor]['chat_area']
                chat_area.insert(tk.END, f"[{nombre_emisor} (privado)]: {mensaje_contenido}\n")
            else:
                self.abrir_ventana_privada(nombre_emisor)
                chat_area = self.private_chat_windows[nombre_emisor]['chat_area']
                chat_area.insert(tk.END, f"[{nombre_emisor} (privado)]: {mensaje_contenido}\n")
        else:
            nombre_emisor = partes[0][1:]
            if destinatario in self.private_chat_windows:
                chat_area = self.private_chat_windows[destinatario]['chat_area']
                chat_area.insert(tk.END, f"[{nombre_emisor} (privado)]: {mensaje_contenido}\n")
            else:
                self.abrir_ventana_privada(destinatario)
                chat_area = self.private_chat_windows[destinatario]['chat_area']
                chat_area.insert(tk.END, f"[{nombre_emisor} (privado)]: {mensaje_contenido}\n")


    def abrir_ventana_privada(self, destinatario):
        if destinatario not in self.private_chat_windows:
            top = tk.Toplevel(self.master)
            top.title(f"Chat privado con {destinatario}")

            chat_area = scrolledtext.ScrolledText(top, wrap=tk.WORD, width=40, height=15)
            chat_area.pack(padx=10, pady=10)

            mensaje_entry = tk.Entry(top, width=30)
            mensaje_entry.pack(pady=10)
            mensaje_entry.bind("<Return>", lambda event, dest=destinatario: self.enviar_mensaje_seleccionado(dest, mensaje_entry))

            enviar_button = tk.Button(top, text="Enviar", command=lambda dest=destinatario, entry=mensaje_entry: self.enviar_mensaje_seleccionado(dest, entry))
            enviar_button.pack()

            self.private_chat_windows[destinatario] = {'window': top, 'chat_area': chat_area, 'entry': mensaje_entry}

    def enviar_mensaje_seleccionado(self, destinatario, mensaje_entry):
        mensaje = mensaje_entry.get()
        if mensaje:
            chat_window = self.private_chat_windows.get(destinatario)
            if chat_window:
                chat_area = chat_window['chat_area']
                chat_area.insert(tk.END, f"[Yo (privado)]: {mensaje}\n")
                try:
                    self.socket_cliente.send(f"@{destinatario} {mensaje}\n".encode())  # Agregar '\n' al final del mensaje
                except socket.error:
                    chat_area.insert(tk.END, "El servidor se ha cerrado o hay un problema de conexión.\n")
                mensaje_entry.delete(0, tk.END)
        else:
            messagebox.showwarning("Mensaje vacio", "No se puede enviar un mensaje vacío.")


    def actualizar_lista_usuarios(self, mensaje):
        lista_usuarios = mensaje.split(":")[1].split(",")
        self.users_listbox.delete(0, tk.END)
        for usuario in lista_usuarios:
            self.users_listbox.insert(tk.END, usuario)

    def actualizar_usuarios(self):
        try:
            self.socket_cliente.send("#lista_clientes".encode())
        except socket.error:
            self.chat_general.insert(tk.END, "El servidor se ha cerrado o hay un problema de conexión.\n")

    def seleccionar_usuario(self, event):
        seleccionado = self.users_listbox.get(tk.ACTIVE)
        if seleccionado:
            respuesta = messagebox.askyesno("Enviar mensaje privado", f"¿Enviar mensaje privado a {seleccionado}?")
            if respuesta:
                self.abrir_ventana_privada(seleccionado)

def main():
    root = tk.Tk()
    app = ChatGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()