import 'package:flutter/material.dart';
import 'dart:io';

class PrivateChatGUI extends StatefulWidget {
  final String ipAddress;
  final String userName;
  final String recipient;

  PrivateChatGUI({required this.ipAddress, required this.userName, required this.recipient});

  @override
  _PrivateChatGUIState createState() => _PrivateChatGUIState();
}
class _PrivateChatGUIState extends State<PrivateChatGUI> {
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
      _socket.listen((data) {
        String message = String.fromCharCodes(data).trim();
        // Solo añade el mensaje a la lista si es un mensaje privado para este usuario
        if (message.startsWith('@${widget.userName}')) {
          setState(() {
            _chatMessages.add(message);
          });
        }
      });
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la conexión
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      // Añade el nombre del destinatario al principio del mensaje
      _socket.writeln('@${widget.recipient} ${_messageController.text}');
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat privado con ${widget.recipient}'),
      ),
      body: Column(
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
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Escribe un mensaje',
              suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}