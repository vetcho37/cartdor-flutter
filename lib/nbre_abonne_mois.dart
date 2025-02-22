import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
