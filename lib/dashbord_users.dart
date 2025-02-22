import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'partenerpage.dart';

class ClientDashboardPage extends StatefulWidget {
  @override
  _ClientDashboardPageState createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  User? user;
  String userEmail = "";
  String userName = "Nom non défini";
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  String searchQuery = ""; // Variable pour la recherche

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTransactions();
  }

  Future<void> fetchUserData() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userEmail = user!.email ?? "Utilisateur non connecté";
      setState(() {
        userName = user!.displayName ?? "Nom non défini";
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['full_name'] ?? userName;
          });
        }
      } catch (e) {
        print("Erreur lors de la récupération des données utilisateur : $e");
      }
    } else {
      setState(() {
        userEmail = "Utilisateur non connecté";
      });
    }
  }

  Future<void> fetchTransactions() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('emailclient', isEqualTo: userEmail)
          .get();

      setState(() {
        transactions = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        filteredTransactions =
            List.from(transactions); // Initialiser avec toutes les transactions
      });
    } catch (e) {
      print("Erreur lors de la récupération des transactions : $e");
    }
  }

  // Méthode de filtrage
  void filterTransactions() {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        return transaction['transaction_id']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            transaction['nom_magasin']
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  void showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Détails de la transaction"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Référence transaction : ${transaction['transaction_id']}"),
                Text("Nom magasin : ${transaction['nom_magasin']}"),
                Text(
                    "Montant payé (avec réduction) : ${transaction['montantclient']} FCFA"),
                Text(
                    "Montant initial : ${transaction['montant_initial']} FCFA"),
                Text(
                    "Gain accordé : ${transaction['montant_initial'] - transaction['montantclient']} FCFA"),
                Text("Localisation : ${transaction['localisation']}"),
                Text("Numéro partenaire : ${transaction['telephonemagasin']}"),
                Text("Date : ${transaction['date_transaction'].toDate()}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tableau de Bord Client"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount:
            filteredTransactions.isEmpty ? 3 : 3 + filteredTransactions.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Carte d'accueil utilisateur
            return Container(
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.only(bottom: 16.0), // Espace après le tableau
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_circle, size: 50, color: Colors.blue),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bienvenue, $userName",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (index == 1) {
            // Bouton "Liste des partenaires"
            return Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 16.0), // Espace après le bouton
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartnerListPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.list_alt, color: Colors.white),
                  label: Text(
                    "Liste des partenaires",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            );
          } else if (index == 2) {
            // Barre de recherche
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher par référence ou nom de magasin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                    filterTransactions();
                  },
                ),
                SizedBox(height: 16.0), // Espace après la barre de recherche
              ],
            );
          } else {
            // Transactions
            final transaction = filteredTransactions[index - 3];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  "Magasin : ${transaction['nom_magasin']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Montant facture: ${transaction['montant_initial']} FCFA"),
                    Text(
                        "Montant payé(8% réduction) : ${transaction['montantclient']} FCFA"),
                    Text(
                        "Gain accordé : ${transaction['montant_initial'] - transaction['montantclient']} FCFA"),
                  ],
                ),
                onTap: () => showTransactionDetails(transaction),
              ),
            );
          }
        },
      ),
    );
  }
}
