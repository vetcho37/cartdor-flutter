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

          SizedBox(height: 20),

          // Texte accrocheur principal
          Text(
            "-10% SUR TOUS VOS ACHATS!",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Raleway',
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: 10),

// Texte indiquant la réduction de 10%
          SizedBox(height: 40),

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
