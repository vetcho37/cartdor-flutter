import 'package:cartdor/index.dart';
import 'package:cartdor/scanqr.dart';
import 'package:cartdor/val_abonn_code.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Import pour générer un identifiant unique
import 'seller_dashboard.dart';
import 'scanqr.dart';

class DashboardPage extends StatefulWidget {
  final String storeName;
  final String storeLocation;
  final String storePhone;
  final String codeVendeur;

  DashboardPage({
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
    required this.codeVendeur,
  });

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  late Stream<QuerySnapshot> transactionsStream;
  bool showSearchBar = false;
  String searchQuery = ''; // Stocke la requête de recherche
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    // Initialisation de la recherche
    searchController = TextEditingController();
    // Récupérer les transactions liées à ce vendeur
    transactionsStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('codeVendeur', isEqualTo: widget.codeVendeur)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    // Libérer le contrôleur de texte lorsque la page est supprimée
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Tableau de bord - ${widget.storeName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue),
            onPressed: () {
              // Redirection vers la page de connexion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        // Centre tout le contenu
        child: SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur le magasin
                Card(
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
                            Icon(Icons.store, size: 30, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              widget.storeName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 20, color: Colors.red),
                            SizedBox(width: 5),
                            Text(widget.storeLocation),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.green),
                            SizedBox(width: 5),
                            Text(widget.storePhone),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Affichage conditionnel de la barre de recherche en haut
                if (showSearchBar)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un abonné...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                SizedBox(height: 20),

                // Section des transactions
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: transactionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text(
                          'Aucune transaction disponible.',
                          style: TextStyle(fontSize: 16),
                        ));
                      }

                      // Filtrage des transactions en fonction de la recherche
                      final transactions =
                          snapshot.data!.docs.where((transaction) {
                        final data = transaction.data() as Map<String, dynamic>;
                        final name =
                            data['name']?.toString().toLowerCase() ?? '';
                        return name.contains(searchQuery); // Filtrage par nom
                      }).toList();

                      if (transactions.isEmpty) {
                        return Center(
                            child: Text(
                          'Aucune transaction correspondant à votre recherche.',
                          style: TextStyle(fontSize: 16),
                        ));
                      }

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final transactionData =
                              transaction.data() as Map<String, dynamic>;

                          final date = transactionData['date'];
                          DateTime transactionDate =
                              DateTime.now(); // Valeur par défaut
                          if (date is Timestamp) {
                            transactionDate = date
                                .toDate(); // Convertir Timestamp en DateTime
                          } else if (date is DateTime) {
                            transactionDate =
                                date; // Utiliser DateTime si déjà au bon format
                          }

                          final transactionCode =
                              transactionData['transactionCode'] ?? '';
                          final name = transactionData['name'] ?? 'Inconnu';
                          final phone =
                              transactionData['phone'] ?? 'Non renseigné';
                          final initialAmount =
                              transactionData['initialAmount'] ?? 0.0;
                          final amountAfterDiscount =
                              transactionData['amount'] ?? 0.0;

                          final reduction = initialAmount * 0.10;
                          final finalAmount = initialAmount - reduction;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Divider(
                                      thickness: 1, color: Colors.grey[300]),
                                  Row(
                                    children: [
                                      Icon(Icons.receipt,
                                          size: 18, color: Colors.teal),
                                      SizedBox(width: 5),
                                      Text('Référence: $transactionCode'),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 18, color: Colors.orange),
                                      SizedBox(width: 5),
                                      Text(
                                          'Date: ${DateFormat('dd/MM/yyyy').format(transactionDate)}'),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 18, color: Colors.green),
                                      SizedBox(width: 5),
                                      Text('Téléphone: $phone'),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.money,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 5),
                                      Text(
                                          'Montant facture: ${initialAmount.toStringAsFixed(2)} FCFA'),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  // Row(
                                  //   children: [
                                  //     Icon(Icons.discount,
                                  //         size: 18, color: Colors.purple),
                                  //     SizedBox(width: 5),
                                  //     Text(
                                  //       'réduction (10%): ${reduction.toStringAsFixed(2)} FCFA',
                                  //       style: TextStyle(
                                  //           fontWeight: FontWeight.bold),
                                  //     ),
                                  //   ],
                                  // ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.payment,
                                          size: 18, color: Colors.green),
                                      SizedBox(width: 5),
                                      Text(
                                        'Montant Reçu: ${amountAfterDiscount.toStringAsFixed(2)} FCFA',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
              title: 'Statistiques',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatisticsPage(
                        storeName: widget.storeName,
                        storeLocation: widget.storeLocation,
                        storePhone: widget.storePhone,
                        codeVendeur: widget.codeVendeur),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.dashboard, // Icône d'accueil
              title: 'historiques',
              onTap: () {
                // Réinitialiser la page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(
                        storeName: widget.storeName,
                        storeLocation: widget.storeLocation,
                        storePhone: widget.storePhone,
                        codeVendeur: widget.codeVendeur),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.scanner,
              title: 'Scanner',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanQRCodePage(
                      codeVendeur: widget.codeVendeur,
                    ),
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

class StatisticsPage extends StatefulWidget {
  final String storeName;
  final String storeLocation;
  final String storePhone;
  final String codeVendeur;

  StatisticsPage({
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
    required this.codeVendeur,
  });

  @override
  StatisticsPageState createState() => StatisticsPageState();
}

class StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    // Référence aux variables du widget à l'intérieur de la méthode build
    String codeVendeur = widget.codeVendeur;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord'),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlobalStatistics(codeVendeur),
                SizedBox(height: 20),
                _buildSubscribersTable(codeVendeur),
                SizedBox(height: 20),
                _buildDailyRevenueTable(codeVendeur),
              ],
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
              title: 'Statistiques',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatisticsPage(
                        storeName: widget.storeName,
                        storeLocation: widget.storeLocation,
                        storePhone: widget.storePhone,
                        codeVendeur: widget.codeVendeur),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.dashboard,
              title: 'Historiques',
              onTap: () {
                // Rafraîchissement de la page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(
                        storeName: widget.storeName,
                        storeLocation: widget.storeLocation,
                        storePhone: widget.storePhone,
                        codeVendeur: widget.codeVendeur),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.scanner,
              title: 'Scanner',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanQRCodePage(
                      codeVendeur: widget.codeVendeur,
                    ),
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

  // Widget pour afficher les statistiques globales
  Widget _buildGlobalStatistics(String codeVendeur) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 8,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiques Globales',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('codeVendeur',
                      isEqualTo: codeVendeur) // Utilisation de codeVendeur ici
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucune donnée disponible.'));
                }

                final transactions = snapshot.data!.docs;
                int totalTransactions = transactions.length;
                double totalCA = 0.0;
                double totalReduction = 0.0;
                double totalNetCA = 0.0;

                transactions.forEach((transaction) {
                  final data = transaction.data() as Map<String, dynamic>;
                  final initialAmount = data['initialAmount'] ?? 0.0;
                  final reduction = initialAmount * 0.10;
                  final netCA = initialAmount - reduction;

                  totalCA += initialAmount;
                  totalReduction += reduction;
                  totalNetCA += netCA;
                });

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(
                          label: Text('',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Chiffre',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('Nombre de Transactions')),
                        DataCell(Text(totalTransactions.toString()))
                      ]),
                      DataRow(cells: [
                        DataCell(Text('CA')),
                        DataCell(
                          Text(
                            totalCA.toStringAsFixed(2) + ' FCFA',
                            style: TextStyle(color: Colors.orange),
                          ),
                        )
                      ]),
                      DataRow(cells: [
                        DataCell(Text('Réduction (10%)')),
                        DataCell(
                          Text(
                            totalReduction.toStringAsFixed(2) + ' FCFA',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      ]),
                      DataRow(cells: [
                        DataCell(Text('CA Net')),
                        DataCell(Text(
                          totalNetCA.toStringAsFixed(2) + ' FCFA',
                          style: TextStyle(color: Colors.green),
                        ))
                      ]),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribersTable(String codeVendeur) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 8,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abonnés',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('codeVendeur',
                      isEqualTo: codeVendeur) // Utilisation de codeVendeur ici
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucun abonné avec des achats.'));
                }

                Map<String, Map<String, dynamic>> subscribers = {};

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String subscriberName = data['name'] ?? 'Inconnu';
                  double initialAmount =
                      (data['initialAmount'] ?? 0.0).toDouble();
                  if (initialAmount <= 0) continue;

                  double netCA = initialAmount * 0.90;

                  if (subscribers.containsKey(subscriberName)) {
                    subscribers[subscriberName]!['transactions'] += 1;
                    subscribers[subscriberName]!['netCA'] += netCA;
                  } else {
                    subscribers[subscriberName] = {
                      'transactions': 1,
                      'netCA': netCA,
                    };
                  }
                }

                List<MapEntry<String, Map<String, dynamic>>> sortedSubscribers =
                    subscribers.entries.toList()
                      ..sort((a, b) =>
                          b.value['netCA'].compareTo(a.value['netCA']));

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(
                          label: Text('Nom',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Transactions',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('CA Net',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: sortedSubscribers.map((entry) {
                      return DataRow(cells: [
                        DataCell(Text(entry.key)),
                        DataCell(Text(entry.value['transactions'].toString())),
                        DataCell(Text(
                            '${entry.value['netCA'].toStringAsFixed(2)} FCFA')),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRevenueTable(String codeVendeur) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 8,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recettes Journalières',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('codeVendeur',
                      isEqualTo: codeVendeur) // Utilisation de codeVendeur ici
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Aucune donnée de recettes.'));
                }

                // Code pour afficher les recettes journalières
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(
                          label: Text('Date',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('CA',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('01/02/2025')),
                        DataCell(Text('1,200,000 FCFA')),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('02/02/2025')),
                        DataCell(Text('1,300,000 FCFA')),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
