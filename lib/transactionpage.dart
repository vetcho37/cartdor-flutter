import 'package:cartdor/index.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Import pour générer un identifiant unique
import 'dashbord_sellers.dart';
import 'scanqr.dart';

class TransactionPage extends StatefulWidget {
  final String name;
  final String phone;
  final String email;
  final DateTime creationDate;
  final DateTime expirationDate;
  final String status;
  final double discountRate;
  final String codeVendeur;
  final String storeName;
  final String storeLocation;
  final String storePhone;
  //final String offre;

  TransactionPage({
    required this.name,
    required this.phone,
    required this.email,
    required this.creationDate,
    required this.expirationDate,
    required this.status,
    required this.discountRate,
    required this.codeVendeur,
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
    // required this.offre,
  });

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController _amountController = TextEditingController();
  double finalAmount = 0.0;
  String transactionCode = '';
  double initialAmount = 0.0; // Montant initial avant réduction

  @override
  void initState() {
    super.initState();
    transactionCode = _generateTransactionCode();
  }

  String _generateTransactionCode() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TXN-${timestamp}-${random.nextInt(1000)}';
  }

  void _calculateDiscount() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      initialAmount = amount; // Le montant initial
      finalAmount =
          amount - (amount * widget.discountRate); // Montant après réduction
    });
  }

  void _saveTransaction() async {
    try {
      // Enregistrer la transaction
      await FirebaseFirestore.instance.collection('transactions').add({
        'transactionCode': transactionCode,
        'name': widget.name,
        'phone': widget.phone,
        'email': widget.email,
        'codeVendeur': widget.codeVendeur,
        'storeName': widget.storeName,
        'storeLocation': widget.storeLocation,
        'storePhone': widget.storePhone,
        'initialAmount': initialAmount,
        'amount': finalAmount,
        'date': DateTime.now(),
        //'offre': widget.offre,
      });

      // Affichage de la boîte de dialogue de confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transaction enregistrée'),
          content: Text(
              'Transaction enregistrée pour ${widget.name}, montant: $finalAmount FCFA'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                // Redirection vers le tableau de bord
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(
                      storeName: widget.storeName,
                      storeLocation: widget.storeLocation,
                      storePhone: widget.storePhone,
                      codeVendeur: widget.codeVendeur,
                    ),
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.status == "Actif";

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction - ${widget.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${widget.name}', style: TextStyle(fontSize: 18)),
            Text('Téléphone: ${widget.phone}', style: TextStyle(fontSize: 18)),
            Text('Email: ${widget.email}', style: TextStyle(fontSize: 18)),
            Text('Magasin: ${widget.storeName}',
                style: TextStyle(fontSize: 18)),
            Text('Localisation: ${widget.storeLocation}',
                style: TextStyle(fontSize: 18)),
            Text('Téléphone du magasin: ${widget.storePhone}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Entrez le montant'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateDiscount(),
            ),
            SizedBox(height: 10),
            Text(
              'Montant après réduction: ${finalAmount.toStringAsFixed(2)} FCFA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
