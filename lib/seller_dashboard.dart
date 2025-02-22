import 'dart:math';
import 'package:cartdor/scanqr.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scanqr.dart';
import 'dashbord_sellers.dart';

class SellerLoginScreen extends StatefulWidget {
  @override
  _SellerLoginScreenState createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final TextEditingController _sellerCodeController = TextEditingController();
  bool _isLoading = false;

  void _validateSeller() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String sellerCode = _sellerCodeController.text.trim();

      // Rechercher le vendeur dans Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('partenaires') // Collection des vendeurs
          .where('code_vendeur', isEqualTo: sellerCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si le vendeur existe, récupérer ses données
        final sellerData = querySnapshot.docs.first.data();
        String storeName = sellerData['nom_magasin'] ?? 'Nom inconnu';
        String location = sellerData['localisation'] ?? 'Localisation inconnue';
        String phonemagasin = sellerData['telephone'] ?? 'telephone inconnue';

        // Naviguer vers le tableau de bord
        Navigator.push(
          context,
          // MaterialPageRoute(
          //   builder: (context) => SellerDashboard(
          //    storeName: storeName,
          //    location: location,
          //    sellerCode: sellerCode,
          MaterialPageRoute(
              builder: (context) => DashboardPage(
                  codeVendeur: sellerCode,
                  storeName: storeName,
                  storeLocation: location,
                  storePhone: phonemagasin)),
        );
      } else {
        // Afficher un message d'erreur si le code est incorrect
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code vendeur invalide')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Couleur de fond
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 10,
                offset: Offset(0, 3), // décalage horizontal et vertical
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connexion ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _sellerCodeController,
                decoration: InputDecoration(
                  labelText: 'Code partenaire',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _validateSeller,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Couleur du fond
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text(
                          'Valider',
                          style: TextStyle(
                            color: Colors.white, // Couleur du texte
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerDashboard extends StatefulWidget {
  final String storeName;
  final String location;
  final String sellerCode;

  SellerDashboard({
    required this.storeName,
    required this.location,
    required this.sellerCode,
  });

  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tableau de Bord vendeur"),
        backgroundColor: Colors.blue[50],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Ajout d'un espacement entre l'AppBar et le contenu
            SizedBox(height: 20),
            // Conteneur principal avec ListView pour éviter les débordements
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Message de bienvenue
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue, ${widget.storeName} !',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Localisation : ${widget.location}',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
                        hintText: 'Rechercher par nom ou référence...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Liste des transactions
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('code_vendeur', isEqualTo: widget.sellerCode)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Erreur : ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('Aucune transaction trouvée.'));
                      }

                      final transactions = snapshot.data!.docs.where((doc) {
                        final transaction =
                            doc.data() as Map<String, dynamic>; // Conversion
                        final clientName =
                            transaction['nomclient'].toString().toLowerCase();
                        final reference = transaction['transaction_id']
                            .toString()
                            .toLowerCase();
                        return clientName.contains(searchQuery) ||
                            reference.contains(searchQuery);
                      }).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index].data()
                              as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nom client : ${transaction['nomclient']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                      'Date : ${transaction['date_transaction'].toDate()}'),
                                  Text(
                                      'Référence : ${transaction['transaction_id']}'),
                                  Text(
                                      'Téléphone Client : ${transaction['telephoneclient']}'),
                                  Text(
                                      'Montant facture : ${transaction['montant_initial']} FCFA'),
                                  Text(
                                      'Montant payé (8% réduction) : ${transaction['montantclient']} FCFA'),
                                  Text(
                                    'Commission Cardor (2%) : ${double.parse(transaction['commissionapp'].toString()).toStringAsFixed(2)} FCFA',
                                  ),
                                  Text(
                                      'Montant reçu : ${transaction['selleramount']} FCFA'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
