import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  void _connectToServer() {
    String ipAddress = _ipController.text.trim();
    String userName = _nameController.text.trim();

    if (ipAddress.isNotEmpty && userName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatGUI(ipAddress: ipAddress, userName: userName),
        ),
      );
    } else {
      // Mostrar un mensaje de error si la dirección IP o el nombre de usuario están vacíos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('La dirección IP y el nombre de usuario son obligatorios.'),
            actions: [
              TextButton(
                onPressed: () {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(labelText: 'Ingrese la IP del servidor'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Ingrese su nombre'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connectToServer,
              child: Text('Conectar al servidor'),
            ),
          ],
        ),
      ),
    );
  }
}

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
      // Muestra un mensaje de error
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
                  Navigator.of(context).pop(); // Cierra la pantalla actual
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

  // Agrega el mensaje a la lista y actualiza la interfaz de usuario
  void _addMessage(String message) {
    setState(() {
      _chatMessages.add(message);
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Envía el mensaje al servidor
      _socket.writeln(message);
      // Agrega el mensaje a la lista localmente
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
          title: Text('Chat Room'),
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
                    onPressed: _sendMessage,
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
