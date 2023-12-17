import 'package:flutter/material.dart';
import 'dart:io';
import 'UserListScreen.dart'; // Asegúrate de importar la pantalla de la lista de usuarios

class ChatGUI extends StatefulWidget {
  final String ipAddress;
  final String userName;

  ChatGUI({required this.ipAddress, required this.userName});

  @override
  _ChatGUIState createState() => _ChatGUIState();
}

class _ChatGUIState extends State<ChatGUI> {
  late Socket _socket;
  final TextEditingController _messageController = TextEditingController();
  final List<String> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    try {
      _socket = await Socket.connect(widget.ipAddress, 5555);

      // Envía el nombre al servidor
      _socket.writeln(widget.userName);

      // Escucha mensajes del servidor
      await for (List<int> data in _socket) {
        final message = String.fromCharCodes(data);

        // Ignora mensajes en blanco
        if (message.trim().isEmpty) {
          continue;
        }

        // Agrega el mensaje a la lista
        _addMessage(message);
      }
    } catch (e) {
      print('Error al conectar al servidor: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Error al conectar al servidor. Asegúrate de que la dirección IP y el puerto son correctos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showUserListScreen(List<String> userList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(userList: userList),
      ),
    );
  }

  @override
  void dispose() {
    _socket.destroy();
    super.dispose();
  }

  void _addMessage(String message) {
    setState(() {
      _chatMessages.add(message);
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _socket.writeln(message);
      _addMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _socket.destroy();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('QUINTO A'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.people),
              onPressed: () async {
                // Envía el mensaje #lista_clientes para obtener la lista de usuarios
                _socket.writeln("#lista_clientes");

                // Lista temporal para almacenar usuarios
                List<String> userList = [];

                // Escucha mensajes del servidor
                await for (List<int> data in _socket) {
                  final message = String.fromCharCodes(data);

                  // Ignora mensajes en blanco
                  if (message.trim().isEmpty) {
                    continue;
                  }

                  // Verifica si la respuesta comienza con "#lista_clientes"
                  if (message.startsWith("#lista_clientes")) {
                    // Extrae la lista de usuarios
                    userList = message.split(":")[1].trim().split(", ");

                    // Actualiza la lista de usuarios y navega a la nueva pantalla
                    setState(() {
                      _showUserListScreen(userList);
                    });

                    // Sal del bucle para dejar de escuchar
                    break;
                  }
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_chatMessages[index]),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:
                          InputDecoration(labelText: 'Escribe un mensaje'),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _sendMessage(),
                    child: Text('Enviar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
