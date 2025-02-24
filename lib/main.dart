import 'package:cartdor/dashbord_abonne.dart';
import 'package:cartdor/dashbord_users.dart';
import 'package:cartdor/menu_accueil.dart';
import 'package:cartdor/menu_demarage.dart';
import 'package:cartdor/register.dart';
import 'package:cartdor/subscription_cinetpay.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'form_recuperation.dart';
import 'homepage.dart';
import 'index.dart';
import 'partenerpage.dart';
import 'seller_dashboard.dart';
import 'subscriptionpage.dart';
import 'scanqr.dart';
import 'parteners_register.dart';
import 'scan_parteners.dart';
import 'menu_demarage.dart';
import 'menu_accueil.dart';
import 'admin_page.dart';
import 'nbre_abonne_mois.dart';
import 'dart:io'; // Pour accéder à Platform.environment
import 'package:flutter/widgets.dart';

void main() async {
  // Initialisation du framework Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase pour Flutter Web
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA3_V4ufspLegKjXWaIWkZU8DFhXsnfGIk",
      authDomain: "myflutter-cb967.firebaseapp.com",
      projectId: "myflutter-cb967",
      storageBucket: "myflutter-cb967.firebasestorage.app",
      messagingSenderId: "609178679652",
      appId: "1:609178679652:web:692a9ee2201002b37de271",
    ),
  );

  // Lancement de l'application Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CARTD'OR",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Supprime le bandeau de débogage
      home:
          StartMenu(), // Page d'accueil ou toute autre page que tu veux utiliser comme page principale
    );
  }
}
