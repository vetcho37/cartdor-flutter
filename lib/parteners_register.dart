import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR Code generator
import 'dart:io'; // File operations
import 'dart:math'; // Random code generation
import 'package:path_provider/path_provider.dart'; // Local storage
import 'dart:ui';

class PartnerRegistrationPage extends StatefulWidget {
  @override
  _PartnerRegistrationPageState createState() =>
      _PartnerRegistrationPageState();
}

class _PartnerRegistrationPageState extends State<PartnerRegistrationPage> {
  String? vendorCode; // Code unique du vendeur
  String? qrImagePath; // Chemin local du QR code
  bool isLoading = false; // Indicateur de chargement

  final _communeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _localisationController = TextEditingController();
  final _nomMagasinController = TextEditingController();
  final _telephoneController = TextEditingController();

  String? selectedCategory; // Variable pour stocker la catégorie sélectionnée
  List<String> categories = [
    'Alimentations et boissons',
    'Beaute et bien etre',
    'Mode et accessoires',
    'Électroménager et high-tech',
    'services',
    'Spas et salons de beauté premium',
    'Supermarchés et epiceries',
    'autres',
  ]; // Liste des catégories

  // Générer un code unique pour le vendeur
  String _generateVendorCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Générer un QR code et sauvegarder en local
  Future<void> _generateQrCode(String code) async {
    final directory = await getApplicationDocumentsDirectory();
    final qrFile = File('${directory.path}/vendor_qr_code.png');
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

  // Sauvegarder le QR code dans la galerie
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

  // Enregistrer un nouveau partenaire
  Future<void> _registerNewPartner() async {
    setState(() {
      isLoading = true;
    });

    try {
      final code = _generateVendorCode(); // Générer le code vendeur
      await FirebaseFirestore.instance.collection('partenaires').add({
        'code_vendeur': code,
        'commune': _communeController.text,
        'createdAt': DateTime.now(),
        'description': _descriptionController.text,
        'email': _emailController.text,
        'localisation': _localisationController.text,
        'nom_magasin': _nomMagasinController.text,
        'telephone': _telephoneController.text,
        'categories': selectedCategory, // Enregistrer la catégorie sélectionnée
      });

      await _generateQrCode(code); // Générer le QR code localement

      setState(() {
        vendorCode = code;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Partenaire enregistré avec succès !")),
      );
    } catch (e) {
      print("Erreur lors de l'enregistrement du partenaire : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur : Impossible d'enregistrer le partenaire.")),
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
        title: Text('Ajouter un Partenaire'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nomMagasinController,
                    decoration: InputDecoration(labelText: 'Nom du magasin'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _localisationController,
                    decoration: InputDecoration(labelText: 'Localisation'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _communeController,
                    decoration: InputDecoration(labelText: 'Commune'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _telephoneController,
                    decoration: InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 10),
                  // Dropdown ajusté
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: 'Catégorie'),
                    isExpanded: true, // Utilisation de isExpanded
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerNewPartner,
                    child: Text('Ajouter Partenaire'),
                  ),
                  // Affichage du code vendeur et du QR code après l'enregistrement
                  if (vendorCode != null && qrImagePath != null) ...[
                    SizedBox(height: 20),
                    Text(
                      "Code Vendeur : $vendorCode",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Image.file(
                      File(qrImagePath!),
                      height: 150,
                      width: 150,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _saveQrCodeToGallery,
                      child: Text('Télécharger le QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
