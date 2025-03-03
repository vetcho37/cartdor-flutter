import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transactionpage.dart';

class ScanQRCodePage extends StatefulWidget {
  final String codeVendeur;

  ScanQRCodePage({required this.codeVendeur});

  @override
  _ScanQRCodePageState createState() => _ScanQRCodePageState();
}

class _ScanQRCodePageState extends State<ScanQRCodePage> {
  bool isScannerActive = true;
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
        title: Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isScannerActive = true; // Réactiver le scanner
              });
            },
          ),
        ],
      ),
      body: isScannerActive
          ? MobileScanner(
              onDetect: (barcodeCapture) {
                if (barcodeCapture.barcodes.isNotEmpty) {
                  final barcode = barcodeCapture.barcodes.first;
                  if (barcode.rawValue != null) {
                    String code = barcode.rawValue!;
                    print('QR Code scanné : $code');
                    setState(() {
                      isScannerActive =
                          false; // Désactiver le scanner après détection
                    });
                    _getSubscriptionDetails(code);
                  } else {
                    print('Code QR vide ou invalide.');
                  }
                }
              },
            )
          : Center(
              child: Text(
                'Rafraichissement............',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }

  Future<void> _getSubscriptionDetails(String uniqueCode) async {
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
            Text(
                'Date dabonnement: ${DateFormat('dd/MM/yyyy').format(creationDate)}',
                style: TextStyle(fontSize: 18)),
            Text(
                'Fin dabonnement: ${DateFormat('dd/MM/yyyy').format(expirationDate)}',
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
              setState(() {
                isScannerActive = true; // Réactiver le scanner après fermeture
              });
            },
            child: Text('Fermer'),
          ),
          if (isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToTransactionPage();
              },
              child: Text('Continuer la  Transaction'),
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
              setState(() {
                isScannerActive = true; // Réactiver le scanner après fermeture
              });
            },
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
