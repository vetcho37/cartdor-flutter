import 'package:flutter/material.dart';
import 'package:cartdor/admin_loginpage.dart';
import 'package:cartdor/index.dart';
import 'package:cartdor/partenerpage.dart';
import 'dashbord_abonne.dart';

void main() {
  runApp(MyApp_Start());
}

class MyApp_Start extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartMenu(),
    );
  }
}

class StartMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/cartdorall.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),

          // Texte "SCAN et PROFITES"
          Text(
            "ABONNES TOI ET PROFITES!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          // QR Code avec 10% réduction
          Image.asset(
            'assets/images/scanme.png',
            width: 120,
            height: 120,
          ),
          Text(
            "10% Réduction",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 30),

          // Bouton "Se connecter"
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Se connecter",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
