import 'package:flutter/material.dart';

class UserListScreen extends StatelessWidget {
  final List<String> userList;

  UserListScreen({required this.userList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios conectados'),
      ),
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(userList[index]),
            // Puedes agregar lógica para iniciar un chat privado con el usuario al hacer clic
            onTap: () {
              // Agrega aquí la lógica para iniciar un chat privado con el usuario seleccionado
            },
          );
        },
      ),
    );
  }
}
