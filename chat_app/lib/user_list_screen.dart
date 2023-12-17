import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class UserListScreen extends StatefulWidget {
  final String ipAddress;

  UserListScreen({required this.ipAddress});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    _updateUserList();
  }

  Future<void> _updateUserList() async {
    try {
      Socket socket = await Socket.connect(widget.ipAddress, 5555);
      socket.writeln("#lista_clientes");

      String response;
      do {
        response = await socket.transform(utf8.decoder.cast()).join();
      } while (!response.startsWith("#lista_clientes"));

      List<String> userList = response.split(":")[1].trim().split(", ");

      setState(() {
        users = userList;
      });

      socket.destroy();
    } catch (e) {
      print("Error al obtener la lista de usuarios: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios conectados'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index]),
            onTap: () {
              // Puedes agregar lógica para iniciar un chat privado con el usuario seleccionado
            },
          );
        },
      ),
    );
  }
}
