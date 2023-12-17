import 'package:flutter/material.dart';
import 'chat_gui.dart';

class PantallaConexion extends StatelessWidget {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  void _connectToServer(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/home.png'), // Cambia 'assets/imagen_circulo.png' por la ruta de tu imagen
            ),
            SizedBox(height: 16),
            Text(
              '¡Bienvenido a Chat QUITO A!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
              onPressed: () => _connectToServer(context),
              child: Text('Conectar al servidor'),
            ),
          ],
        ),
      ),
    );
  }
}
