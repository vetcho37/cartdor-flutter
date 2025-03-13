import 'package:cartdor/index.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dashbord_sellers.dart';

class TransactionNoReducePage extends StatefulWidget {
  final String name;
  final String phone;
  final String email;
  final String codeVendeur;
  final String storeName;
  final String storeLocation;
  final String storePhone;

  TransactionNoReducePage({
    required this.name,
    required this.phone,
    required this.email,
    required this.codeVendeur,
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
  });

  @override
  _TransactionNoReducePageState createState() =>
      _TransactionNoReducePageState();
}

class _TransactionNoReducePageState extends State<TransactionNoReducePage> {
  final TextEditingController _amountController = TextEditingController();
  double initialAmount = 0.0;
  double finalAmount = 0.0;
  String transactionCode = '';

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

  void _updateAmount() {
    setState(() {
      initialAmount = double.tryParse(_amountController.text) ?? 0.0;
      finalAmount =
          initialAmount; // Pas de réduction, donc le montant reste le même
    });
  }

  void _saveTransaction() async {
    try {
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
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transaction enregistrée'),
          content: Text(
              'Transaction enregistrée pour ${widget.name}, montant: $finalAmount FCFA'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
              onChanged: (_) => _updateAmount(),
            ),
            SizedBox(height: 10),
            // Text(
            //   'Montant initial: ${initialAmount.toStringAsFixed(2)} FCFA',
            //   style: TextStyle(fontSize: 18),
            // ),
            Text(
              'Montant de la transaction: ${finalAmount.toStringAsFixed(2)} FCFA',
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
