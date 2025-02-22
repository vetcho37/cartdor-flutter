import 'package:flutter/material.dart';

class NosServicesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nos produits et services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "CARTD'OR :",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Une Plateforme  permettant à ses utilisateurs de bénéficier d’une réduction fixe de 5 % sur tous les achats à partir de 5000fcfa auprès des partenaires (bars, restaurants, supermarchés, etc.).',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Avantages :',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Réduction de 5 %: Offerte à tous les utilisateurs. Inscription gratuite sans frais\n'
              '• Paiement simplifié : Via l\'application CartDor avec un paiement QR code.\n'
              '• Suivi des achats : Toutes les transactions sont enregistrées dans l\'application.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Services supplémentaires :',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Événements partenaires : Promotion et visibilité accrue pour les établissements partenaires.\n'
              "• Publicité et promotion : CARTD'OR aide les établissements à maximiser leur visibilité grâce à la base de données d’utilisateurs et à des campagnes ciblées.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
