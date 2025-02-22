import 'package:cartdor/scan_parteners.dart';
import 'package:cartdor/subscriptionpage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerListPage extends StatefulWidget {
  @override
  _PartnerListPageState createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedCategory =
      ''; // Variable pour stocker la catégorie sélectionnée

  final List<String> categories = [
    'Alimentations et boissons',
    'Beaute et bien etre',
    'Mode et accessoires',
    'Électroménager et high-tech',
    'services',
    'Spas et salons de beauté premium',
    'Supermarchés et epiceries',
    'autres',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Partenaires",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Retour à la page précédente
            },
          ),
        ),
        body: Center(
            // Centre tout le contenu
            child: SizedBox(
          width: 500, // Fi
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'partenaire, ville',
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
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
              // Sélection des catégories avec une flèche pour revenir
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          selectedCategory =
                              ''; // Réinitialiser la catégorie sélectionnée
                        });
                      },
                    ),
                    // Utilisation de Flexible ou Expanded pour éviter le débordement
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0), // Un peu de marge
                        child: DropdownButton<String>(
                          hint: Text('Sélectionnez une catégorie'),
                          value: selectedCategory.isEmpty
                              ? null
                              : selectedCategory,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                          isExpanded:
                              true, // Cette option rend le dropdown plus fluide
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Liste des partenaires avec design amélioré
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('partenaires')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Erreur de chargement des données'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('Aucun partenaire trouvé'));
                    }

                    // Filtrer les partenaires
                    var allPartners = snapshot.data!.docs;
                    var filteredPartners = allPartners.where((doc) {
                      String nomMagasin =
                          doc['nom_magasin']?.toString().toLowerCase() ?? '';
                      String commune =
                          doc['commune']?.toString().toLowerCase() ?? '';
                      String ville =
                          doc['localisation']?.toString().toLowerCase() ?? '';

                      // Caster doc.data() en Map<String, dynamic>
                      var data = doc.data() as Map<String, dynamic>?;

                      String category = '';
                      if (data != null && data.containsKey('categories')) {
                        category =
                            data['categories']?.toString().toLowerCase() ?? '';
                      }

                      bool matchesCategory = selectedCategory.isEmpty ||
                          category.contains(selectedCategory.toLowerCase());

                      return (searchQuery.isEmpty ||
                              nomMagasin.contains(searchQuery) ||
                              commune.contains(searchQuery) ||
                              ville.contains(searchQuery)) &&
                          matchesCategory;
                    }).toList();

                    if (filteredPartners.isEmpty) {
                      return Center(child: Text('Aucun partenaire trouvé'));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(8.0),
                      itemCount: filteredPartners.length,
                      itemBuilder: (context, index) {
                        var partner = filteredPartners[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 30,
                                child: Icon(
                                  Icons.storefront,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                              title: Text(
                                partner['nom_magasin'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.white70, size: 18),
                                      SizedBox(width: 5),
                                      Text(
                                        partner['commune'],
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartnerDetailsPage(
                                      partnerInfo: partner.data()
                                          as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                              },
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
        )));
  }
}

class PartnerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> partnerInfo;

  PartnerDetailsPage({required this.partnerInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          partnerInfo['nom_magasin'] ?? 'Détails du Partenaire',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerInfo['nom_magasin'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      partnerInfo['commune'] ?? 'Non spécifié',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _launchPhoneCall(partnerInfo['telephone']),
                      child: Text(
                        partnerInfo['telephone'] ?? 'Non spécifié',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline, // Effet de lien
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      partnerInfo['email'] ?? 'Non spécifié',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partnerInfo['description'] ?? 'Aucune description',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.place, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partnerInfo['localisation'] ?? 'Non spécifiée',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _launchPhoneCall(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri phoneUri = Uri.parse("tel:$phoneNumber");
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        print("Impossible de passer l'appel");
      }
    }
  }
}
