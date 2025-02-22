import 'package:cartdor/dashbord_abonne.dart';
import 'package:cartdor/partenerpage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transactionpage.dart';
import 'dart:math';

class ScanQRCodePage_partener extends StatefulWidget {
  // Identifiant de l'utilisateur connecté
  final String userEmail;

  ScanQRCodePage_partener({required this.userEmail});

  @override
  _ScanQRCodePageState createState() => _ScanQRCodePageState();
}

class _ScanQRCodePageState extends State<ScanQRCodePage_partener> {
  bool isScannerActive = true;
  String codeVendeur = ''; // Initialiser la variable avant son utilisation
  String usercode = '';
  String userEmail = '';
  late String storeName;
  late String storeLocation;
  late String storePhone;

  late String userName;
  late String userPhone;

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
                isScannerActive = true;
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
                      isScannerActive = false;
                    });
                    _getStoreDetails(code); // Passer le code scanné directement
                  } else {
                    print('Code QR vide ou invalide.');
                  }
                }
              },
            )
          : Center(
              child: Text(
                'lancement du scan...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }

  Future<void> _getStoreDetails(String codeVendeur) async {
    try {
      final storeQuerySnapshot = await FirebaseFirestore.instance
          .collection('partenaires')
          .where('code_vendeur', isEqualTo: codeVendeur)
          .get();

      if (storeQuerySnapshot.docs.isNotEmpty) {
        final storeDoc = storeQuerySnapshot.docs.first;
        final storeData = storeDoc.data();

        // Initialisation correcte de la variable `codeVendeur`
        this.codeVendeur = storeData['code_vendeur'] ?? 'Non renseigné';
        storeName = storeData['nom_magasin'] ?? 'Non renseigné';
        storeLocation = storeData['localisation'] ?? 'Non renseignée';
        storePhone = storeData['telephone'] ?? 'Non renseigné';

        _getUserDetails(); // Récupérer les détails de l'utilisateur connecté
      } else {
        _showErrorDialog("Partenaire non trouvé.");
      }
    } catch (e) {
      _showErrorDialog(
          "Erreur lors de la récupération des données du partenaire : $e");
    }
  }

  Future<void> _getUserDetails() async {
    try {
      final userQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        final userDoc = userQuerySnapshot.docs.first;
        final userData = userDoc.data();

        setState(() {
          userName = userData['full_name'] ?? 'Utilisateur inconnu';
          userEmail = userData['email'] ?? 'Non renseigné';
          userPhone = userData['phone'] ?? 'Non renseigné';
        });
        _redirectToTransactionPage(); // Redirection directe ici
      } else {
        _showErrorDialog("Utilisateur non trouvé.");
      }
    } catch (e) {
      _showErrorDialog(
          "Erreur lors de la récupération des données utilisateur : $e");
    }
  }

  void _showPartnerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du Partenaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom du magasin: $storeName', style: TextStyle(fontSize: 18)),
            Text('Localisation: $storeLocation',
                style: TextStyle(fontSize: 18)),
            Text('Téléphone: $storePhone', style: TextStyle(fontSize: 18)),
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
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _redirectToTransactionPage();
            },
            child: Text('Continuer'),
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
          codeVendeur: codeVendeur,
          userName: userName,
          userEmail: userEmail,
          userPhone: userPhone,
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

class TransactionPage extends StatefulWidget {
  final String
      codeVendeur; // Remove 'late' and make it non-nullable// Déclarer codeVendeur ici
  final String userName;
  final String userEmail;
  final String userPhone;

  final String storeName;
  final String storeLocation;
  final String storePhone;

  TransactionPage({
    required this.codeVendeur, // Assurez-vous qu'il est inclus ici
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
  });

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  TextEditingController amountController = TextEditingController();
  double discountAmount = 0.0;
  double finalAmount = 0.0;
  String transactionCode = '';

  // Fonction pour générer un code de transaction alphanumérique
  String generateTransactionCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  void initState() {
    super.initState();
    transactionCode =
        generateTransactionCode(); // Générez le code de transaction au début
  }

  void calculateDiscount() {
    double initialAmount = double.tryParse(amountController.text) ?? 0.0;
    if (initialAmount > 0) {
      setState(() {
        discountAmount = initialAmount * 0.05;
        finalAmount = initialAmount - discountAmount;
      });
    }
  }

  void validateTransaction() async {
    double initialAmount = double.tryParse(amountController.text) ?? 0.0;

    if (initialAmount > 0) {
      try {
        await FirebaseFirestore.instance.collection('transactions').add({
          'amount': finalAmount,
          'codeVendeur':
              widget.codeVendeur, // Peut être remplacé par un code spécifique
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'email': widget.userEmail,
          'initialAmount': initialAmount,
          'name': widget.userName,
          'phone': widget.userPhone,
          'storeLocation': widget.storeLocation,
          'storeName': widget.storeName,
          'storePhone': widget.storePhone,
          'transactionCode': transactionCode,
        });

        // Affichage d'une boîte de dialogue avec les informations de la transaction
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Transaction réussie'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Montant de la transaction: ${finalAmount.toStringAsFixed(2)} '),
                  Text('Nom du partenaire: ${widget.storeName}'),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Ferme la boîte de dialogue

                      // Naviguer vers la page de la liste des partenaires
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DashboardUserPage()), // Remplacez ListePartenairesPage() par la page appropriée
                      );
                    },
                    child: Text('OK')),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Erreur lors de l\'enregistrement de la transaction: $e'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veuillez entrer un montant valide.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction'),
        backgroundColor: Colors.blue, // Fond bleu pour le titre
      ),
      body: SingleChildScrollView(
        // Permet à la page de défiler si nécessaire
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations du partenaire',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Nom du magasin: ${widget.storeName}',
                  style: TextStyle(fontSize: 16)),
              Text('Localisation: ${widget.storeLocation}',
                  style: TextStyle(fontSize: 16)),
              Text('Téléphone: ${widget.storePhone}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              // Champ pour entrer le montant
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant de la transaction',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  calculateDiscount();
                },
              ),
              SizedBox(height: 16),
              // Affichage du montant réduit de 5%
              Text(
                'Montant avec réduction de 5%: ${finalAmount.toStringAsFixed(2)} FCFA',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              SizedBox(height: 32), // Espace avant le bouton
              Center(
                child: ElevatedButton(
                  onPressed: validateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Fond bleu pour le bouton
                    minimumSize: Size(double.infinity, 50), // Largeur agrandie
                    textStyle: TextStyle(color: Colors.white), // Texte en blanc
                  ),
                  child: Text('Valider la transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
