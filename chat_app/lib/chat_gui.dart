import 'package:flutter/material.dart';
import 'dart:io';

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

  void _initializeSocket() async {
    try {
      _socket = await Socket.connect(widget.ipAddress, 5555);

      // Envía el nombre al servidor
      _socket.writeln(widget.userName);

      // Escucha mensajes del servidor
      _socket.listen(
        (List<int> data) {
          final message = String.fromCharCodes(data);

          // Ignora mensajes en blanco
          if (message.trim().isEmpty) {
            return;
          }

          // Agrega el mensaje a la lista
          _addMessage(message);
        },
        onDone: () {
          print('Conexión cerrada por el servidor');
          _socket.destroy();
        },
        onError: (error) {
          print('Error de conexión: $error');
          _socket.destroy();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Error al conectar al servidor: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error al conectar al servidor. Asegúrate de que la dirección IP y el puerto son correctos.'),
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
                      decoration: InputDecoration(labelText: 'Escribe un mensaje'),
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
