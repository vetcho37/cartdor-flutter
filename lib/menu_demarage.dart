import 'package:flutter/material.dart';
import 'package:cartdor/admin_loginpage.dart';
import 'package:cartdor/index.dart';
import 'package:cartdor/partenerpage.dart';

void main() {
  runApp(MyApp_Start());
}

class MyApp_Start extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartMenu(),
    );
  }
}

class StartMenu extends StatefulWidget {
  @override
  _StartMenuState createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  int _selectedIndex = 0;

  // Liste des pages associées aux icônes du menu
  final List<Widget> _pages = [
    StartMenuContent(),
    PartnerListPage(),
    CartDorPage(),
    AdminLoginPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Fond bleu
      body: _pages[_selectedIndex], // Affiche la page sélectionnée
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, -3))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.blue,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.play_arrow), label: "Accueil"),
            BottomNavigationBarItem(
                icon: Icon(Icons.people), label: "Partenaires"),
            BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard), label: "À propos"),
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: "Personnels"),
          ],
        ),
      ),
    );
  }
}

// Contenu principal de la page d'accueil
class StartMenuContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 10),

        // Affichage du logo au lieu du texte
        Center(
          child: Image.asset(
            'assets/imags/cartdorall.png', // Chemin vers l'image
            width: 300, // Largeur de l'image (ajuste selon la taille souhaitée)
            height:
                300, // Hauteur de l'image (ajuste selon la taille souhaitée)
            fit: BoxFit.contain, // Ajuste l'image sans la déformer
          ),
        ),

        SizedBox(height: 20),
        SizedBox(height: 30),

        // Bouton "Se connecter"
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            "Se connecter",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

// Page À propos
class CartDorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("À propos de Cartd'or"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildSection(
              "Qui sommes-nous ?",
              "Cartd'or est une plateforme numérique qui permet à ses utilisateurs de bénéficier de réductions exclusives chez nos partenaires. "
                  "Nous facilitons l'accès à des offres spéciales dans divers établissements comme les restaurants, bars, supermarchés et bien plus encore. "
                  "Grâce à notre application, vous pouvez économiser sur vos achats tout en découvrant de nouveaux endroits.",
            ),
            _buildSection(
              "Notre mission",
              "Notre mission est de révolutionner l'expérience d'achat en créant un réseau dynamique entre les consommateurs et les commerçants partenaires. "
                  "Nous souhaitons rendre le pouvoir d'achat plus accessible à tous, tout en offrant aux commerçants une meilleure visibilité et plus de clients fidèles.",
            ),
            _buildSection(
              "L'abonnement Cartd'or - 1000 FCFA/mois",
              "Avec seulement 1000 FCFA/mois, bénéficiez de réductions exclusives dans tous nos établissements partenaires. "
                  "Vous aurez droit à une remise de 10% sur tous vos achats à partir de 2 000 FCFA chez nos partenaires. "
                  "De plus, profitez d'offres spéciales, de cadeaux surprises et d'avantages réservés à nos abonnés.",
            ),
            _buildSection(
              "Nos valeurs",
              "🔹 Accessibilité: Offrir des réductions accessibles à tous pour améliorer le pouvoir d'achat. \n\n"
                  "🔹 Partenariat gagnant-gagnant: Soutenir les commerçants en leur apportant plus de clients et de visibilité. \n\n"
                  "🔹 Satisfaction client: Garantir une expérience fluide et avantageuse pour chaque utilisateur.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
