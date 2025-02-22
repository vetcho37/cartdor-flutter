import 'package:cartdor/index.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final String subscriberName;
  final String subscriberPhone;
  final String subscriberProfession;
  final DateTime subscriberCreationDate;
  final DateTime subscriberExpirationDate;
  final String subscriberStatus;
  final String storeName;
  final String storePhone;
  final String storeLocation;

  const TransactionPage({
    required this.subscriberName,
    required this.subscriberPhone,
    required this.subscriberProfession,
    required this.subscriberCreationDate,
    required this.subscriberExpirationDate,
    required this.subscriberStatus,
    required this.storeName,
    required this.storePhone,
    required this.storeLocation,
  });

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  // Fonction pour créer une nouvelle transaction
  Future<void> _createTransaction() async {
    if (_amountController.text.isEmpty) {
      _showErrorDialog("Veuillez entrer le montant.");
      return;
    }

    try {
      // Récupérer le montant de la transaction
      double amount = double.parse(_amountController.text);

      // Vérifier si le montant est valide
      if (amount <= 0) {
        _showErrorDialog("Le montant doit être supérieur à zéro.");
        return;
      }

      // Calculer la réduction pour l'abonné
      double discount = 0.10; // 10% de réduction
      double discountedAmount = amount - (amount * discount);

      // Créer une nouvelle transaction dans Firestore
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('transactions').add({
        'subscriberName': widget.subscriberName,
        'subscriberPhone': widget.subscriberPhone,
        'subscriberProfession': widget.subscriberProfession,
        'subscriberCreationDate': widget.subscriberCreationDate,
        'subscriberExpirationDate': widget.subscriberExpirationDate,
        'subscriberStatus': widget.subscriberStatus,
        'storeName': widget.storeName,
        'storePhone': widget.storePhone,
        'storeLocation': widget.storeLocation,
        'amount': amount,
        'discount': discount,
        'discountedAmount': discountedAmount,
        'transactionDate': Timestamp.now(),
      });

      // Réinitialiser les champs
      _amountController.clear();
      setState(() {
        _isLoading = false;
      });

      // Afficher un message de succès
      _showSuccessDialog("Transaction effectuée avec succès !");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Erreur lors de la transaction: $e");
    }
  }

  // Afficher un message d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Afficher un message de succès
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(
                  context); // Retourner à l'écran précédent après succès
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page de Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de l'abonné
            Text('Nom Abonné: ${widget.subscriberName}'),
            Text('Téléphone Abonné: ${widget.subscriberPhone}'),
            Text('Profession Abonné: ${widget.subscriberProfession}'),
            Text(
                'Créé le: ${DateFormat('dd/MM/yyyy').format(widget.subscriberCreationDate)}'),
            Text(
                'Expire le: ${DateFormat('dd/MM/yyyy').format(widget.subscriberExpirationDate)}'),
            Text('Statut: ${widget.subscriberStatus}',
                style: TextStyle(
                  color: widget.subscriberStatus == 'Actif'
                      ? Colors.green
                      : Colors.red,
                )),
            SizedBox(height: 20),

            // Informations du vendeur
            Text('Nom du Magasin: ${widget.storeName}'),
            Text('Téléphone Magasin: ${widget.storePhone}'),
            Text('Localisation Magasin: ${widget.storeLocation}'),
            SizedBox(height: 20),

            // Montant de la transaction
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant de la transaction',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Bouton de transaction
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createTransaction,
                    child: Text('Effectuer la Transaction'),
                  ),
          ],
        ),
      ),
    );
  }
}
