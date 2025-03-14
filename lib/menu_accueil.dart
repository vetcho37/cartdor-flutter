import 'package:cartdor/subscriptionpage.dart';
import 'package:flutter/material.dart';
import 'package:cartdor/scan_parteners.dart';
import 'package:cartdor/seller_dashboard.dart';
import 'package:cartdor/dashbord_abonne.dart';
import 'package:cartdor/partenerpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Pour Timer
import 'statutabonement.dart';

class Menu_Accueil extends StatefulWidget {
  final String userEmail;

  Menu_Accueil({required this.userEmail});

  @override
  _Menu_AccueilState createState() => _Menu_AccueilState();
}

class _Menu_AccueilState extends State<Menu_Accueil> {
  bool showSearchBar = false;
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> transactionsFuture;
  Timer? subscriptionCheckTimer;
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    transactionsFuture = getTransactionsByEmail(widget.userEmail);

    // Démarrer la vérification des abonnements expirés
    startSubscriptionCheck();
  }

  @override
  void dispose() {
    // Annuler le timer lorsque la page est fermée
    subscriptionCheckTimer?.cancel();
    super.dispose();
  }

  void addLog(String message) {
    print(message); // Print to console
    setState(() {
      logs.add("${DateFormat('HH:mm:ss').format(DateTime.now())}: $message");
      // Keep only the latest 100 logs
      if (logs.length > 100) {
        logs.removeAt(0);
      }
    });
  }

  Future<void> updateExpiredSubscriptions() async {
    try {
      // Récupérer la collection des abonnements
      final subscriptionsCollection =
          FirebaseFirestore.instance.collection('subscriptions');

      // Récupérer la date actuelle
      final now = DateTime.now();

      addLog('Début de la vérification des abonnements expirés...');

      // Récupérer les abonnements actifs dont la date d'expiration est dépassée
      final expiredSubscriptionsQuery = await subscriptionsCollection
          .where('expirationDate', isLessThan: Timestamp.fromDate(now))
          .where('status', isEqualTo: 'Actif')
          .get();

      if (expiredSubscriptionsQuery.docs.isEmpty) {
        addLog('Aucun abonnement expiré trouvé.');
        return;
      }

      addLog(
          'Nombre d\'abonnements expirés trouvés: ${expiredSubscriptionsQuery.docs.length}');

      // Utilisation d'un batch pour optimiser les mises à jour Firestore
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in expiredSubscriptionsQuery.docs) {
        final subscriptionId = doc.id;
        final subscriptionData = doc.data();
        final expirationDate =
            (subscriptionData['expirationDate'] as Timestamp).toDate();

        addLog(
            'Traitement de l\'abonnement $subscriptionId - Expiration: $expirationDate');

        // Vérification finale avant mise à jour
        if (expirationDate.isBefore(now)) {
          batch.update(subscriptionsCollection.doc(subscriptionId), {
            'status': 'Expiré',
            'lastUpdated': Timestamp.fromDate(
                now), // Ajout d'un champ pour suivre les mises à jour
          });
          addLog('Abonnement $subscriptionId mis à jour à Expiré.');
        }
      }

      // Appliquer toutes les mises à jour en une seule opération
      await batch.commit();
      addLog('✅ Mise à jour des abonnements expirés terminée avec succès.');
    } catch (e) {
      addLog('❌ Erreur lors de la mise à jour des abonnements expirés : $e');
    }
  }

  // Fonction pour exécuter la vérification périodiquement
  void startSubscriptionCheck() {
    addLog('⏳ Démarrage du vérificateur d\'abonnements...');

    // Exécuter une première vérification immédiatement
    updateExpiredSubscriptions();

    // Puis configurer une vérification périodique
    // En production, utilisez un intervalle plus long comme 24 heures
    subscriptionCheckTimer = Timer.periodic(Duration(hours: 24), (Timer t) {
      addLog('🔄 Exécution de la mise à jour des abonnements expirés...');
      updateExpiredSubscriptions();
    });
  }

  // Fonction pour gérer la déconnexion
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Après déconnexion, rediriger vers la page de connexion
      // Remplacez 'LoginPage()' par le nom de votre page de connexion
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Couleur de fond

      // Ajout de l'AppBar avec le bouton de déconnexion
      appBar: AppBar(
        title: Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false, // Supprime la flèche de retour
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _showLogoutConfirmationDialog(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),

      body: Center(
          // Centrer le contenu
          child: SizedBox(
        width: 500, // Largeur fixée à 400 pixels
        child: FutureBuilder<List<Map<String, dynamic>>>(
          // Fetch transactions
          future: transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Erreur de récupération des transactions'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Aucune transaction pour linstant'));
            }

            final transactions = snapshot.data!
                .where((transaction) => transaction['store']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();

            // Calcul des économies réalisées
            double totalEconomies = 0.0;
            for (var transaction in transactions) {
              double amount = transaction['initialAmount'].toDouble();
              double montantPaye = transaction['amount'].toDouble();
              double economy = amount - montantPaye;
              // Exemple avec 5% de réduction
              totalEconomies += economy;
            }

            return Column(
              children: [
                SizedBox(height: 20),

                // Section des économies réalisées
                Center(
                  child: Container(
                    width: 500,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Économies réalisées',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${totalEconomies.toStringAsFixed(2)} FCFA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Barre de recherche
                if (showSearchBar)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un partenaire...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),

                // Liste des transactions
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: transactions.map((transaction) {
                              double initialAmount =
                                  transaction['initialAmount'].toDouble();
                              double amount = transaction['amount'].toDouble();
                              double economy =
                                  initialAmount - amount; // Exemple avec 5%

                              // Convertir la date de Timestamp à DateTime
                              Timestamp timestamp = transaction['date'];
                              DateTime transactionDate = timestamp.toDate();
                              String formattedDate = DateFormat('yyyy-MM-dd')
                                  .format(
                                      transactionDate); // Formatage de la date

                              return Card(
                                child: ListTile(
                                  title: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            transaction['store'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                          Spacer(),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${economy.toStringAsFixed(2)} FCFA',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Date: $formattedDate',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                        ],
                                      ),

                                      // Ajout de l'information "offre"
                                      SizedBox(
                                          height:
                                              4), // Espacement entre la date et l'offre
                                      Text(
                                        'Offre: ${transaction['offre'] ?? 'Non spécifié'}',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Naviguer vers la page des détails de la transaction
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionDetailPage(
                                                transaction: transaction),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      )),

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMenuItem(
              context,
              icon: Icons.search,
              title: 'recherche',
              onTap: () {
                setState(() {
                  showSearchBar = !showSearchBar;
                });
              },
            ),
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
                    builder: (context) =>
                        Menu_Accueil(userEmail: widget.userEmail),
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

  // Fonction pour afficher une boîte de dialogue de confirmation avant la déconnexion
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
              _signOut(context); // Déconnexion
            },
            child: Text('Déconnexion'),
          ),
        ],
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

  Future<List<Map<String, dynamic>>> getTransactionsByEmail(
      String email) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: email)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'store': doc['storeName'],
          'date': doc['date'], // Timestamp
          'amount': doc['amount'],
          'initialAmount': doc['initialAmount'],
          'offre': doc['offre'],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des transactions: $e');
      return [];
    }
  }
}

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  TransactionDetailPage({required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Convertir la date de Timestamp à DateTime
    DateTime transactionDate = (transaction['date'] as Timestamp).toDate();
    String formattedDate = DateFormat('yyyy-MM-dd').format(transactionDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la transaction',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partenaire: ${transaction['store']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Date: $formattedDate'),
            SizedBox(height: 8),
            Text('Montant facture: ${transaction['initialAmount']}'),
            SizedBox(height: 8),
            Text(
                'Montant paye: ${(transaction['amount']).toStringAsFixed(2)} FCFA'),
            SizedBox(height: 8),
            Text(
                'Economie: ${(transaction['initialAmount'] - (transaction['amount'])).toStringAsFixed(2)}'),
            SizedBox(height: 10),
            Text('offre: ${transaction['offre']}'),
          ],
        ),
      ),
    );
  }
}
