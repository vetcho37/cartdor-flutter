import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashbord_users.dart';

// Page de transaction pour un partenaire
class PartnerTransactionPage extends StatefulWidget {
  final String partnerCode; // Code unique du partenaire
  final Map<String, dynamic> partnerInfo; // Infos sur le partenaire

  PartnerTransactionPage(
      {required this.partnerCode, required this.partnerInfo});

  @override
  _PartnerTransactionPageState createState() => _PartnerTransactionPageState();
}

class _PartnerTransactionPageState extends State<PartnerTransactionPage> {
  TextEditingController amountController = TextEditingController();
  double reducedAmount = 0.0;
  double initialAmount = 0.0;

  // Récupérer l'email de l'utilisateur connecté
  String getUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.email ?? '';
  }

  // Récupérer les informations du partenaire depuis Firestore
  Future<Map<String, dynamic>> getPartnerInfo(String partnerCode) async {
    DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
        .collection('partenaires')
        .doc(partnerCode)
        .get();

    if (partnerDoc.exists) {
      return partnerDoc.data() as Map<String, dynamic>;
    } else {
      throw Exception('Partenaire non trouvé');
    }
  }

  // Récupérer les informations du client à partir de son email
  Future<Map<String, dynamic>> getClientInfo(String email) async {
    QuerySnapshot clientQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (clientQuery.docs.isNotEmpty) {
      return clientQuery.docs.first.data() as Map<String, dynamic>;
    } else {
      throw Exception('Client non trouvé');
    }
  }

  // Générer un ID de transaction unique
  String generateTransactionId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Enregistrer la transaction dans Firestore
  Future<void> saveTransaction(String partnerCode, double clientAmount,
      double appCommission, double sellerAmount) async {
    String userEmail =
        getUserEmail(); // Récupérer l'email de l'utilisateur connecté
    Map<String, dynamic> partnerInfo =
        await getPartnerInfo(partnerCode); // Infos du partenaire
    Map<String, dynamic> clientInfo =
        await getClientInfo(userEmail); // Infos du client

    // Données de la transaction
    String transactionId =
        generateTransactionId(); // ID unique de la transaction
    String partnerName = partnerInfo['nom_magasin'];
    String partnerLocation = partnerInfo['localisation'];
    String partnerPhone = partnerInfo['telephone'];
    String sellerCode = partnerInfo['code_vendeur'];
    DateTime transactionDate = DateTime.now();

    // Infos client
    String clientName = clientInfo['full_name'] ?? 'Inconnu';
    String clientPhone = clientInfo['phone'] ?? 'Inconnu';

    // Stocker la transaction dans Firestore
    await FirebaseFirestore.instance.collection('transactions').add({
      'transaction_id': transactionId,
      'code_vendeur': sellerCode,
      'nom_magasin': partnerName,
      'localisation': partnerLocation,
      'telephonemagasin': partnerPhone,
      'emailclient': userEmail,
      'nomclient': clientName, // Nom du client
      'telephoneclient': clientPhone, // Téléphone du client
      'montant_initial': initialAmount,
      'montantclient': clientAmount,
      'commissionapp': appCommission,
      'selleramount': sellerAmount,
      'date_transaction': transactionDate,
    });
  }

  // Calculer le montant réduit avec 8 % de réduction
  void calculateReducedAmount(String amountText) {
    if (amountText.isEmpty) {
      setState(() {
        reducedAmount = 0.0;
        initialAmount = 0.0;
      });
      return;
    }

    try {
      double amount = double.parse(amountText);
      setState(() {
        initialAmount = amount;
        reducedAmount = amount * 0.92; // Réduction de 8 %
      });
    } catch (e) {
      setState(() {
        reducedAmount = 0.0;
        initialAmount = 0.0;
      });
    }
  }

  // Confirmer le paiement
  void confirmPayment() {
    if (reducedAmount > 0) {
      // Calcul des montants
      double clientAmount = reducedAmount;
      double appCommission = clientAmount * 0.02; // Commission (2%)
      double sellerAmount = clientAmount - appCommission;

      // Enregistrer la transaction
      saveTransaction(
          widget.partnerCode, clientAmount, appCommission, sellerAmount);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Paiement confirmé"),
            content: Text(
                "Le paiement de ${clientAmount.toStringAsFixed(2)} FCFA pour le partenaire ${widget.partnerInfo['nom_magasin']} a été effectué avec succès."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer la boîte de dialogue
                  // Rediriger vers la page de connexion en utilisant MaterialPageRoute
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ClientDashboardPage()), // Remplacer la page actuelle par LoginScreen
                  );
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez entrer un montant valide.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paiement - ${widget.partnerInfo['nom_magasin']}"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations sur le partenaire
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partnerInfo['nom_magasin'],
                      style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    SizedBox(height: 8),
                    Text("Localisation: ${widget.partnerInfo['localisation']}"),
                    Text("Téléphone: ${widget.partnerInfo['telephone']}"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            // Champ de saisie pour le montant
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Entrez le montant de la transaction",
                border: OutlineInputBorder(),
              ),
              onChanged: calculateReducedAmount,
            ),
            SizedBox(height: 16.0),
            // Montant après réduction
            Text(
              "Montant après réduction (8 %) : ${reducedAmount.toStringAsFixed(2)} FCFA",
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            // Bouton pour confirmer le paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: confirmPayment,
                child: Text("Confirmer le paiement"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
