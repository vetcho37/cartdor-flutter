import 'package:cartdor/partenerpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Assurez-vous que cette ligne est présente
import 'menu_accueil.dart';
import 'statutabonement.dart';

class DashboardUserPage extends StatefulWidget {
  @override
  DashboardUserPageState createState() => DashboardUserPageState();
}

class DashboardUserPageState extends State<DashboardUserPage> {
  late String userEmail;
  late String userName = "";
  late double totalMontantInitial = 0.0;
  late double totalMontantPaye = 0.0;
  late double totalEconomies = 0.0;
  late List<DocumentSnapshot> transactions = [];

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  // Récupérer l'email de l'utilisateur connecté
  Future<void> _getUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
      });
      _fetchUserDetails(userEmail);
      _fetchTransactions(userEmail);
    }
  }

  // Récupérer les détails de l'utilisateur (nom, email, etc.)
  void _fetchUserDetails(String email) async {
    try {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users') // Collection des utilisateurs
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          userName = userSnapshot.docs.first['full_name'];
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails de l\'utilisateur: $e');
    }
  }

  // Récupérer les transactions de l'utilisateur, triées par date décroissante
  void _fetchTransactions(String email) async {
    try {
      var transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .orderBy('date', descending: true) // Tri par date décroissante
          .get();

      setState(() {
        transactions = transactionsSnapshot.docs;
      });

      // Calculer les statistiques
      _calculateStatistics(transactions);
    } catch (e) {
      print('Erreur lors de la récupération des transactions: $e');
    }
  }

  // Calculer les statistiques (montant initial, montant payé, économies réalisées)
  void _calculateStatistics(List<DocumentSnapshot> transactions) {
    double montantInitialTotal = 0.0;
    double montantPayeTotal = 0.0;
    double economiesTotal = 0.0;

    for (var transaction in transactions) {
      double montantInitial = transaction['initialAmount'].toDouble();
      // double montantPaye =
      //     montantInitial * 0.9; // Montant payé après réduction de 10%
      double montantPaye = transaction['amount'].toDouble();
      double economie = montantInitial - montantPaye; // Économie réalisée

      montantInitialTotal += montantInitial;
      montantPayeTotal += montantPaye;
      economiesTotal += economie;
    }

    setState(() {
      totalMontantInitial = montantInitialTotal;
      totalMontantPaye = montantPayeTotal;
      totalEconomies = economiesTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Couleur de fond
      appBar: AppBar(
        title: Text('Tableau de bord Utilisateur'),
      ),
      body: Center(
        // Centre tout le contenu
        child: SizedBox(
          width: 500, // Fixe la largeur à 400 pixels
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Détails de l'abonné
                  Row(
                    children: [
                      Icon(Icons.account_circle, size: 40, color: Colors.blue),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(" "),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Tableau des statistiques
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Colonne Montant Initial
                              Expanded(
                                child: _buildStatColumn(
                                  Icons.monetization_on,
                                  'Factures',
                                  totalMontantInitial,
                                ),
                              ),
                              // Colonne Montant Payé
                              Expanded(
                                child: _buildStatColumn(
                                  Icons.arrow_downward,
                                  'Paiements',
                                  totalMontantPaye,
                                ),
                              ),
                              // Colonne Économies Réalisées avec couleur verte
                              Expanded(
                                child: _buildStatColumn(
                                  Icons.attach_money,
                                  'Économies',
                                  totalEconomies,
                                  isEconomy: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Liste des transactions
                  transactions.isNotEmpty
                      ? Column(
                          children: transactions.map((transaction) {
                            // double montantInitial =
                            // transaction['initialAmount'].toDouble();
                            // double montantPaye = montantInitial * 0.95;
                            // double economie = montantInitial - montantPaye;
                            double economie =
                                transaction['initialAmount'].toDouble() -
                                    transaction['amount'].toDouble();

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 6,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.store,
                                            size: 30, color: Colors.blue),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            transaction['storeName'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),
                                    // Date placée après storeName
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 20, color: Colors.orange),
                                        SizedBox(width: 5),
                                        // Format de la date
                                        Text(
                                          'Date: ${_formatDate(transaction['date'])}',
                                          style: TextStyle(fontSize: 16),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 20, color: Colors.green),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Localisation: ${transaction['storeLocation']}',
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.local_offer,
                                            size: 20,
                                            color: Colors.lightGreenAccent),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Offre: ${transaction['offre']}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.blue),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Téléphone: ${transaction['storePhone']}',
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.attach_money,
                                            size: 20, color: Colors.black),
                                        SizedBox(width: 5),
                                        Text(
                                          'Montant facture: ${transaction['initialAmount']}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.payment,
                                            size: 20, color: Colors.green),
                                        SizedBox(width: 5),
                                        Text(
                                          'Montant Payé:${transaction['amount']}',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.money_off,
                                            size: 20, color: Colors.purple),
                                        SizedBox(width: 5),
                                        Text(
                                          'Économies réalisées: ${economie}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Center(
                          child: Text(
                            'Aucune transaction disponible.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMenuItem(
              context,
              icon: Icons.dashboard,
              title: 'Historiques',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardUserPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.home, // Icône d'accueil
              title: 'Accueil',
              onTap: () {
                // Réinitialiser la page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Menu_Accueil(userEmail: userEmail),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.people,
              title: 'Partenaires',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartnerListPage(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.subscriptions,
              title: 'Abonnez vous',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionStatusScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Méthode pour afficher une colonne des statistiques
Widget _buildStatColumn(IconData icon, String label, double value,
    {bool isEconomy = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, size: 40, color: isEconomy ? Colors.green : Colors.blue),
      SizedBox(height: 10),
      Text(
        label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 5),
      Text(
        value.toStringAsFixed(0),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

// Fonction pour formater la date en fonction du type de données
String _formatDate(dynamic date) {
  if (date is Timestamp) {
    // Si la date est un Timestamp, convertissez-la en DateTime
    return DateFormat('dd/MM/yyyy').format(date.toDate());
  } else if (date is String) {
    // Si la date est une chaîne de caractères, tentez de la convertir en DateTime
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Date invalide';
    }
  } else {
    return 'Date invalide';
  }
}
