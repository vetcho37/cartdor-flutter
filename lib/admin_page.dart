import 'package:cartdor/nbre_abonne_mois.dart';
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

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  // Contenus des différentes sections
  final List<Widget> _pages = [
    SubscriptionsPage(),
    PartnersPage(),
    TransactionsPage(),
    UsersPage(),
    AbonnesPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Administrateur'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu Administrateur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Abonnements'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Partenaires'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Transactions'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('utilisateurs'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('abonnes reguliers'),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Affichage de la page sélectionnée
    );
  }
}

class SubscriptionsPage extends StatefulWidget {
  @override
  _SubscriptionsPageState createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  TextEditingController _searchNameController = TextEditingController();
  TextEditingController _searchStatusController = TextEditingController();
  String _searchNameQuery = '';
  String _searchStatusQuery = '';

  // Méthode pour récupérer les abonnés avec un filtre spécifique (par statut)
  Future<int> _getSubscriberCountByStatus(String status) async {
    Query query = FirebaseFirestore.instance.collection('subscriptions');

    if (status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    return snapshot.size; // Renvoie le nombre d'abonnés correspondant au statut
  }

  // Méthode pour récupérer le nombre total d'abonnés
  Future<int> _getTotalSubscriberCount() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subscriptions').get();
    return snapshot.size; // Renvoie le nombre total d'abonnés
  }

  Stream<QuerySnapshot> _getSubscribers() {
    // Initialisation de la requête de base
    Query query = FirebaseFirestore.instance.collection('subscriptions');

    // Filtrage par nom si la recherche par nom n'est pas vide
    if (_searchNameQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchNameQuery)
          .where('name', isLessThanOrEqualTo: _searchNameQuery + '\uf8ff');
    }

    // Filtrage par statut si un statut est spécifié
    if (_searchStatusQuery.isNotEmpty) {
      query = query.where('status', isEqualTo: _searchStatusQuery);
    }

    return query.snapshots();
  }

  void _showSubscriberDetails(DocumentSnapshot subscriber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de l\'Abonné'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom: ${subscriber['name'] ?? 'Non défini'}'),
                Text('Email: ${subscriber['emailclit'] ?? 'Non défini'}'),
                Text('Téléphone: ${subscriber['phone'] ?? 'Non défini'}'),
                Text(
                    'Date de création: ${subscriber['creationDate']?.toDate().toString() ?? 'Non définie'}'),
                Text(
                    'Date d\'expiration: ${subscriber['expirationDate']?.toDate().toString() ?? 'Non définie'}'),
                Text('Statut: ${subscriber['status'] ?? 'Non défini'}'),
                Text(
                    'Code unique: ${subscriber['uniqueCode'] ?? 'Non défini'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Affichage du nombre total d'abonnés, Actifs et Expirés
          FutureBuilder<int>(
            future: _getTotalSubscriberCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text("Erreur de récupération du nombre d'abonnés"),
                );
              } else if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'Nombre total d\'abonnés : ${snapshot.data}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<int>(
                        future: _getSubscriberCountByStatus('Actif'),
                        builder: (context, activeSnapshot) {
                          if (activeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (activeSnapshot.hasError) {
                            return Text("Erreur");
                          } else if (activeSnapshot.hasData) {
                            return Text(
                              'Nombre d\'abonnés Actifs : ${activeSnapshot.data}',
                              style: TextStyle(fontSize: 16),
                            );
                          }
                          return Container();
                        },
                      ),
                      SizedBox(height: 10),
                      FutureBuilder<int>(
                        future: _getSubscriberCountByStatus('Expiré'),
                        builder: (context, expiredSnapshot) {
                          if (expiredSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (expiredSnapshot.hasError) {
                            return Text("Erreur");
                          } else if (expiredSnapshot.hasData) {
                            return Text(
                              'Nombre d\'abonnés Expirés : ${expiredSnapshot.data}',
                              style: TextStyle(fontSize: 16),
                            );
                          }
                          return Container();
                        },
                      ),
                    ],
                  ),
                );
              }
              return Container();
            },
          ),

          // Champ de recherche pour le nom
          TextField(
            controller: _searchNameController,
            onChanged: (value) {
              setState(() {
                _searchNameQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Rechercher par nom',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 10),

          // Champ de recherche pour le statut
          TextField(
            controller: _searchStatusController,
            onChanged: (value) {
              setState(() {
                _searchStatusQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Rechercher par statut',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 10),

          // Affichage des abonnés
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSubscribers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Erreur de récupération des données"));
                }

                final subscribers = snapshot.data!.docs;
                if (subscribers.isEmpty) {
                  return Center(child: Text("Aucun abonné trouvé"));
                }

                return ListView.builder(
                  itemCount: subscribers.length,
                  itemBuilder: (context, index) {
                    final subscriber = subscribers[index];
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(subscriber['name'] ?? 'Nom non défini'),
                        subtitle: Text(
                          'Statut: ${subscriber['status'] ?? 'Inconnu'}',
                        ),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          _showSubscriberDetails(subscriber);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PartnersPage extends StatefulWidget {
  @override
  _PartnersPageState createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Méthode pour récupérer les partenaires depuis Firestore
  Stream<QuerySnapshot> _getPartners() {
    Query query = FirebaseFirestore.instance.collection('partenaires');

    // Filtrage par nom si la recherche est effectuée
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('nom_magasin', isGreaterThanOrEqualTo: _searchQuery)
          .where('nom_magasin', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    return query.snapshots();
  }

  void _showPartnerDetails(DocumentSnapshot partner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails du Partenaire'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom: ${partner['nom_magasin'] ?? 'Non défini'}'),
                Text('Email: ${partner['email'] ?? 'Non défini'}'),
                Text('Téléphone: ${partner['telephone'] ?? 'Non défini'}'),
                Text('Adresse: ${partner['localisation'] ?? 'Non définie'}'),
                Text('Ville: ${partner['commune'] ?? 'Non définie'}'),
                Text('categories: ${partner['categories'] ?? 'Non définie'}'),
                Text('Matricule: ${partner['code_vendeur'] ?? 'Non définie'}'),
                Text('Description: ${partner['description'] ?? 'Non définie'}'),
                Text(
                    'Date d\'inscription: ${partner['createdAt']?.toDate().toString() ?? 'Non définie'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour créer un nouveau partenaire
  void _createNewPartner() {
    // Code pour rediriger vers la page de création d'un nouveau partenaire
    // Vous pouvez utiliser une autre page ou un formulaire pour cela
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PartnerRegistrationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Bouton pour créer un nouveau partenaire
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton(
              onPressed: _createNewPartner,
              child: Text('Créer un Nouveau Partenaire'),
            ),
          ),
          SizedBox(height: 10),

          // Champ de recherche pour le nom du partenaire
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Rechercher un partenaire par nom',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 10),

          // Affichage des partenaires
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPartners(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Erreur de récupération des données"));
                }

                final partners = snapshot.data!.docs;
                if (partners.isEmpty) {
                  return Center(child: Text("Aucun partenaire trouvé"));
                }

                return ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final partner = partners[index];
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(partner['nom_magasin'] ?? 'Nom non défini'),
                        subtitle: Text(
                          'Email: ${partner['email'] ?? 'Non défini'}',
                        ),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          _showPartnerDetails(partner);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

  // Fonction pour récupérer le nombre de partenaires
  Future<int> _getPartnerCount() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('partenaires').get();
    return snapshot
        .size; // Renvoie le nombre de documents dans la collection 'partenaires'
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
                  // Afficher le nombre de partenaires juste avant la barre de recherche
                  FutureBuilder<int>(
                    future: _getPartnerCount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Icon(Icons.error),
                        );
                      } else if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Nombre de partenaires : ${snapshot.data}',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }
                      return Container(); // Si pas de donnée
                    },
                  ),

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

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _subscriberSearchQuery = ''; // Recherche par nom d'abonné
  String _storeSearchQuery = ''; // Recherche par nom de propriétaire (store)

  TextEditingController _subscriberSearchController = TextEditingController();
  TextEditingController _storeSearchController = TextEditingController();

  // Méthode pour récupérer toutes les transactions
  Stream<QuerySnapshot> _getTransactions() {
    Query query = FirebaseFirestore.instance.collection('transactions');

    // Filtrage par nom d'abonné
    if (_subscriberSearchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _subscriberSearchQuery)
          .where('name',
              isLessThanOrEqualTo: _subscriberSearchQuery + '\uf8ff');
    }

    // Filtrage par nom de propriétaire (store)
    if (_storeSearchQuery.isNotEmpty) {
      query = query
          .where('storeName', isGreaterThanOrEqualTo: _storeSearchQuery)
          .where('storeName',
              isLessThanOrEqualTo: _storeSearchQuery + '\uf8ff');
    }

    return query.snapshots();
  }

  // Afficher les détails de la transaction
  void _showTransactionDetails(DocumentSnapshot transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de la Transaction'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'code tarnsaction: ${transaction['transactionCode'] ?? 'Non défini'}'),
                Text('Nom Abonné: ${transaction['name'] ?? 'Non défini'}'),
                Text('email client: ${transaction['email'] ?? 'Non défini'}'),
                Text(
                    'Nom Propriétaire: ${transaction['storeName'] ?? 'Non défini'}'),
                Text(
                    'Monatnt facture: ${transaction['initialAmount'] ?? 'Non défini'}'),
                Text('Montant final: ${transaction['amount'] ?? 'Non défini'}'),
                Text(
                    'Matricule vendeur: ${transaction['codeVendeur'] ?? 'Non défini'}'),
                Text(
                    'localisation: ${transaction['storeLocation'] ?? 'Non défini'}'),
                Text(
                    'phone vendeur: ${transaction['storePhone'] ?? 'Non défini'}'),
                Text(
                    'Date: ${transaction['date']?.toDate().toString() ?? 'Non définie'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: Text('Transactions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du nombre de transactions
            StreamBuilder<QuerySnapshot>(
              stream: _getTransactions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text("Chargement...");
                }

                final transactionCount = snapshot.data!.docs.length;

                return Text(
                  'Nombre total de transactions : $transactionCount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 10),

            // Barre de recherche pour le nom de l'abonné
            TextField(
              controller: _subscriberSearchController,
              onChanged: (value) {
                setState(() {
                  _subscriberSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Rechercher par nom d\'abonné',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 10),

            // Barre de recherche pour le nom du propriétaire (store)
            TextField(
              controller: _storeSearchController,
              onChanged: (value) {
                setState(() {
                  _storeSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Rechercher par nom de propriétaire',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 10),

            // Affichage des transactions
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTransactions(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Erreur de récupération des données"));
                  }

                  final transactions = snapshot.data!.docs;
                  if (transactions.isEmpty) {
                    return Center(child: Text("Aucune transaction trouvée"));
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(transaction['name'] ?? 'Nom non défini'),
                          subtitle: Text(
                            'Propriétaire: ${transaction['storeName'] ?? 'Inconnu'}',
                          ),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            _showTransactionDetails(transaction);
                          },
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
    );
  }
}

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Méthode pour récupérer les utilisateurs depuis Firestore
  Stream<QuerySnapshot> _getUsers() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('full_name', isGreaterThanOrEqualTo: _searchQuery)
          .where('full_name', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    return query.snapshots();
  }

  // Méthode pour récupérer le nombre total d'utilisateurs
  Future<int> _getTotalUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.length;
  }

  // Affichage des détails d'un utilisateur
  void _showUserDetails(DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de l\'utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom complet: ${user['full_name'] ?? 'Non défini'}'),
                Text('Email: ${user['email'] ?? 'Non défini'}'),
                Text('Téléphone: ${user['phone'] ?? 'Non défini'}'),
                Text('Ville: ${user['city'] ?? 'Non définie'}'),
                Text('Profession: ${user['profession'] ?? 'Non définie'}'),
                Text('Genre: ${user['gender'] ?? 'Non défini'}'),
                Text('Code utilisateur: ${user['user_code'] ?? 'Non défini'}'),
                Text(
                    'Date de création: ${user['created_at']?.toDate().toString() ?? 'Non définie'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: Text('Page Utilisateurs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Affichage du nombre total d'utilisateurs
            FutureBuilder<int>(
              future: _getTotalUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(
                      "Erreur lors du chargement du nombre d'utilisateurs");
                }

                return Text(
                  'Nombre total d\'utilisateurs: ${snapshot.data}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 10),

            // Champ de recherche pour le nom
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Rechercher par nom',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),

            // Affichage des utilisateurs
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUsers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Erreur de récupération des données"));
                  }

                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return Center(child: Text("Aucun utilisateur trouvé"));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(user['full_name'] ?? 'Nom non défini'),
                          subtitle:
                              Text('Email: ${user['email'] ?? 'Inconnu'}'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            _showUserDetails(user);
                          },
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
    );
  }
}

class AbonnesPage extends StatefulWidget {
  @override
  _AbonnesPageState createState() => _AbonnesPageState();
}

class _AbonnesPageState extends State<AbonnesPage> {
  Map<String, int> abonnementsParMois = {};

  @override
  void initState() {
    super.initState();
    getAbonnesParMois();
  }

  Future<void> getAbonnesParMois() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('subscriptions').get();

    print("📌 Nombre de documents Firestore : ${snapshot.docs.length}");

    Map<String, int> compteurs = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['creationDate']; // Vérifie si le champ existe

      if (timestamp != null) {
        DateTime date =
            timestamp.toDate(); // Convertir le timestamp Firestore en DateTime
        String mois =
            DateFormat('yyyy-MM').format(date); // Formater en "YYYY-MM"

        compteurs[mois] = (compteurs[mois] ?? 0) + 1;
        print("✅ Abonnement trouvé pour le mois : $mois");
      } else {
        print("❌ Le champ 'creationDate' est manquant !");
      }
    }

    setState(() {
      abonnementsParMois = compteurs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Abonnés par mois")),
      body: Column(
        children: [
          // Ajouter le bouton pour accéder aux abonnés réguliers
          ElevatedButton(
            onPressed: () {
              // Naviguer vers la page des abonnés réguliers
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AbonnesReguliersPage(), // Page des abonnés réguliers
                ),
              );
            },
            child: Text("Voir les abonnés réguliers"),
          ),
          // Affichage de la liste des abonnements par mois
          Expanded(
            child: ListView.builder(
              itemCount: abonnementsParMois.length,
              itemBuilder: (context, index) {
                String mois = abonnementsParMois.keys.elementAt(index);
                int count = abonnementsParMois[mois] ?? 0;

                return ListTile(
                  title: Text("📅 $mois"),
                  subtitle: Text("👥 $count abonnés"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListeAbonnesPage(mois: mois),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ListeAbonnesPage extends StatelessWidget {
  final String mois;

  ListeAbonnesPage({required this.mois});

  Future<List<Map<String, dynamic>>> getAbonnesDuMois() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('subscriptions').get();

    List<Map<String, dynamic>> abonnes = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['creationDate'];

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        String moisDoc = DateFormat('yyyy-MM').format(date);

        if (moisDoc == mois) {
          abonnes.add(data);
        }
      }
    }
    return abonnes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Abonnés de $mois")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getAbonnesDuMois(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          List<Map<String, dynamic>> abonnes = snapshot.data!;
          if (abonnes.isEmpty)
            return Center(child: Text("Aucun abonné trouvé pour $mois"));

          return ListView.builder(
            itemCount: abonnes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(abonnes[index]['name'] ?? 'Inconnu'),
                subtitle: Text(abonnes[index]['emailclit'] ?? 'Aucun email'),
                trailing: Text(abonnes[index]['phone'] ?? 'Aucun numéro'),
              );
            },
          );
        },
      ),
    );
  }
}

class AbonnesReguliersPage extends StatefulWidget {
  @override
  _AbonnesReguliersPageState createState() => _AbonnesReguliersPageState();
}

class _AbonnesReguliersPageState extends State<AbonnesReguliersPage> {
  Map<String, Map<String, dynamic>> abonnementsParUtilisateur = {};

  @override
  void initState() {
    super.initState();
    getAbonnesReguliers();
  }

  Future<void> getAbonnesReguliers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('subscriptions').get();

    print("📌 Nombre total d'abonnements trouvés : ${snapshot.docs.length}");

    Map<String, Map<String, dynamic>> compteurs = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String? email = data['emailclit'];
      String? phone = data['phone'];
      String? name = data['name'] ?? "Nom inconnu";

      String cleUtilisateur =
          email ?? phone ?? "Inconnu"; // Identifier chaque utilisateur

      if (cleUtilisateur != "Inconnu") {
        if (!compteurs.containsKey(cleUtilisateur)) {
          compteurs[cleUtilisateur] = {
            'name': name,
            'nombre_abonnements': 0,
          };
        }
        compteurs[cleUtilisateur]!['nombre_abonnements'] += 1;
      }
    }

    // Trier les abonnés du plus fidèle au moins fidèle
    List<MapEntry<String, Map<String, dynamic>>> sortedList = compteurs.entries
        .toList()
      ..sort((a, b) => b.value['nombre_abonnements']
          .compareTo(a.value['nombre_abonnements']));

    setState(() {
      abonnementsParUtilisateur = Map.fromEntries(sortedList);
    });

    print("✅ Liste des abonnés réguliers : $abonnementsParUtilisateur");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Abonnés les plus réguliers")),
      body: ListView.builder(
        itemCount: abonnementsParUtilisateur.length,
        itemBuilder: (context, index) {
          String utilisateur = abonnementsParUtilisateur.keys.elementAt(index);
          String nom = abonnementsParUtilisateur[utilisateur]!['name'];
          int nombreAbonnements =
              abonnementsParUtilisateur[utilisateur]!['nombre_abonnements'];

          return ListTile(
            title: Text(nom), // Affichage du nom de l'abonné
            subtitle: Text("$utilisateur - 🔄 $nombreAbonnements abonnements"),
          );
        },
      ),
    );
  }
}
