import 'package:flutter/material.dart';
import 'admin_page.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _codeController = TextEditingController();
  final String _adminCode = 'cisco1991@Ud'; // Code administrateur

  // Méthode pour vérifier le code d'administrateur
  void _verifyAdminCode() {
    if (_codeController.text == _adminCode) {
      // Si le code est correct, redirige vers la page Admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else {
      // Si le code est incorrect, afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code incorrect. Veuillez réessayer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion '),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code personnel',
                border: OutlineInputBorder(),
                hintText: 'Entrez le code',
              ),
              obscureText: true, // Masque le texte saisi
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyAdminCode,
              child: Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
