import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR Code generator
import 'package:intl/intl.dart'; // Date formatting
import 'dart:io'; // File operations
import 'dart:math'; // Random code generation
import 'package:path_provider/path_provider.dart'; // Local storage
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? uniqueCode;
  String? qrImagePath;
  DateTime? creationDate;
  DateTime? expirationDate;
  String? status;
  String? name;
  String? phone;
  String? profession;

  bool isLoading = false; // Pour afficher un indicateur de chargement
  bool hasSubscription = false; // Indique si une souscription existe
  bool isSubscriptionExpired = false; // Indique si l'abonnement est expiré

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingSubscription();
  }

  // Vérifier si l'utilisateur a déjà un abonnement
  Future<void> _checkExistingSubscription() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final subscriptionDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (subscriptionDoc.exists) {
        final data = subscriptionDoc.data();
        final existingExpirationDate =
            (data?['expirationDate'] as Timestamp).toDate();

        // Vérifier si l'abonnement est expiré
        final isExpired = existingExpirationDate.isBefore(DateTime.now());

        if (isExpired) {
          // Mettre à jour le statut dans Firestore
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .doc(userId)
              .update({
            'status': 'Expiré',
          });
        }

        setState(() {
          hasSubscription = true;
          uniqueCode = data?['uniqueCode'];
          creationDate = (data?['creationDate'] as Timestamp).toDate();
          expirationDate = existingExpirationDate;
          status = isExpired ? 'Expiré' : 'Actif';
          isSubscriptionExpired = isExpired;
        });
      } else {
        setState(() {
          hasSubscription = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification de l'abonnement existant : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur : Impossible de vérifier l'abonnement.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Renouveler l'abonnement
  Future<void> _renewSubscription() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final code = _generateUniqueCode();
      final creation = DateTime.now();
      final expiration =
          creation.add(Duration(days: 30)); // Expiration dans 1 jour

      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .update({
        'uniqueCode': code,
        'creationDate': creation,
        'expirationDate': expiration,
        'status': 'Actif',
      });

      await _generateQrCode(code);

      setState(() {
        uniqueCode = code;
        creationDate = creation;
        expirationDate = expiration;
        status = 'Actif';
        isSubscriptionExpired = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Abonnement renouvelé avec succès !")),
      );
    } catch (e) {
      print("Erreur lors du renouvellement de l'abonnement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur : Impossible de renouveler l'abonnement.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _generateQrCode(String code) async {
    final directory = await getApplicationDocumentsDirectory();
    final qrFile = File('${directory.path}/qr_code.png');
    final qrImage = await QrPainter(
      data: code,
      version: QrVersions.auto,
      gapless: false,
    ).toImage(200);
    final byteData = await qrImage.toByteData(format: ImageByteFormat.png);
    await qrFile.writeAsBytes(byteData!.buffer.asUint8List());
    setState(() {
      qrImagePath = qrFile.path;
    });
  }

  Future<void> _saveQrCodeToGallery() async {
    if (qrImagePath != null) {
      try {
        final success = await GallerySaver.saveImage(qrImagePath!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success != null && success
                  ? "QR Code enregistré dans la galerie !"
                  : "Erreur lors de l'enregistrement.",
            ),
          ),
        );
      } catch (e) {
        print("Erreur lors de l'enregistrement : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de l'enregistrement du QR Code.")),
        );
      }
    }
  }

  Future<void> _createNewSubscription() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final code = _generateUniqueCode();
      final creation = DateTime.now();
      final expiration = creation.add(Duration(days: 30));

      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .set({
        'uniqueCode': code,
        'creationDate': creation,
        'expirationDate': expiration,
        'status': 'Actif',
        'name': _nameController.text,
        'phone': _phoneController.text,
        'emailclit': _emailController.text,
      });

      await _generateQrCode(code);

      setState(() {
        uniqueCode = code;
        creationDate = creation;
        expirationDate = expiration;
        status = 'Actif';
        hasSubscription = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Abonnement créé avec succès !")),
      );
    } catch (e) {
      print("Erreur lors de la création de l'abonnement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : Impossible de créer l'abonnement.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Abonnement'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasSubscription
              ? _buildSubscriptionDetails()
              : _buildSubscriptionForm(),
    );
  }

  Widget _buildSubscriptionForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Entrez vos informations',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nom complet'),
          ),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Numéro de téléphone'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'email'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createNewSubscription,
            child: Text('Paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: Size(200, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Votre abonnement',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          if (uniqueCode != null)
            Text(
              'Code unique : $uniqueCode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          if (creationDate != null)
            Text(
              'Date de création : ${DateFormat('dd/MM/yyyy').format(creationDate!)}',
              style: TextStyle(fontSize: 16),
            ),
          if (expirationDate != null)
            Text(
              'Date d\'expiration : ${DateFormat('dd/MM/yyyy').format(expirationDate!)}',
              style: TextStyle(fontSize: 16),
            ),
          if (status != null)
            Text(
              'Statut : $status',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: status == 'Actif' ? Colors.green : Colors.red),
            ),
          SizedBox(height: 20),
          if (qrImagePath != null)
            Image.file(
              File(qrImagePath!),
              height: 150,
              width: 150,
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveQrCodeToGallery,
            child: Text('Sauvegarder le QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(200, 50),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isSubscriptionExpired ? _renewSubscription : null,
            child: Text('Renouveler'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSubscriptionExpired ? Colors.blue : Colors.grey,
              minimumSize: Size(200, 50),
            ),
          ),
        ],
      ),
    );
  }
}
