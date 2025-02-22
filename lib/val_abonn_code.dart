import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transactionpage.dart';

class ValidateSubscriptionPage extends StatefulWidget {
  final String codeVendeur;

  ValidateSubscriptionPage({required this.codeVendeur});

  @override
  _ValidateSubscriptionPageState createState() =>
      _ValidateSubscriptionPageState();
}

class _ValidateSubscriptionPageState extends State<ValidateSubscriptionPage> {
  final TextEditingController _codeController = TextEditingController();
  bool isValidating = false;
  late String name;
  late String phone;
  late String email;
  late DateTime creationDate;
  late DateTime expirationDate;
  late String status;
  double discountRate = 0.10;
  late String storeName;
  late String storeLocation;
  late String storePhone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Valider Abonnement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrez le code d\'abonnement:',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Code d\'abonnement',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _validateSubscription,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isValidating) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Future<void> _validateSubscription() async {
    String uniqueCode = _codeController.text.trim();

    if (uniqueCode.isEmpty) {
      _showErrorDialog("Veuillez entrer un code d'abonnement.");
      return;
    }

    setState(() {
      isValidating = true;
    });

    try {
      final subscriptionQuerySnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('uniqueCode', isEqualTo: uniqueCode)
          .get();

      if (subscriptionQuerySnapshot.docs.isNotEmpty) {
        final doc = subscriptionQuerySnapshot.docs.first;
        final data = doc.data();
        name = data['name'] ?? 'Inconnu';
        phone = data['phone'] ?? 'Non renseigné';
        email = data['emailclit'] ?? 'Non renseignée';
        creationDate = (data['creationDate'] as Timestamp).toDate();
        expirationDate = (data['expirationDate'] as Timestamp).toDate();
        status = data['status'] ?? 'Non renseigné';

        _getStoreDetails(widget.codeVendeur);
        _showSubscriberDialog();
      } else {
        _showErrorDialog("Abonnement non trouvé.");
      }
    } catch (e) {
      _showErrorDialog("Erreur: $e");
    } finally {
      setState(() {
        isValidating = false;
      });
    }
  }

  Future<void> _getStoreDetails(String codeVendeur) async {
    try {
      final storeQuerySnapshot = await FirebaseFirestore.instance
          .collection('partenaires')
          .where('code_vendeur', isEqualTo: widget.codeVendeur)
          .get();

      if (storeQuerySnapshot.docs.isNotEmpty) {
        final storeDoc = storeQuerySnapshot.docs.first;
        final storeData = storeDoc.data();
        storeName = storeData['nom_magasin'] ?? 'Non renseigné';
        storeLocation = storeData['localisation'] ?? 'Non renseignée';
        storePhone = storeData['telephone'] ?? 'Non renseigné';
      } else {
        storeName = 'Inconnu';
        storeLocation = 'Non renseignée';
        storePhone = 'Non renseigné';
      }
    } catch (e) {
      print('Erreur lors de la récupération des informations du magasin: $e');
    }
  }

  void _showSubscriberDialog() {
    bool isActive = status == "Actif";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'abonné'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: $name', style: TextStyle(fontSize: 18)),
            Text('Téléphone: $phone', style: TextStyle(fontSize: 18)),
            Text('Email: $email', style: TextStyle(fontSize: 18)),
            Text('Créé le: ${DateFormat('dd/MM/yyyy').format(creationDate)}',
                style: TextStyle(fontSize: 18)),
            Text(
                'Expire le: ${DateFormat('dd/MM/yyyy').format(expirationDate)}',
                style: TextStyle(fontSize: 18)),
            Text(
              isActive ? 'Statut: Actif' : 'Statut: Non Actif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fermer'),
          ),
          if (isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToTransactionPage();
              },
              child: Text('Continuer vers Transaction'),
            ),
        ],
      ),
    );
  }

  void _redirectToTransactionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionPage(
          name: name,
          phone: phone,
          email: email,
          creationDate: creationDate,
          expirationDate: expirationDate,
          status: status,
          discountRate: discountRate,
          codeVendeur: widget.codeVendeur,
          storeName: storeName,
          storeLocation: storeLocation,
          storePhone: storePhone,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
