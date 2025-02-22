import 'package:cartdor/dashbord_abonne.dart';
import 'package:cartdor/info.dart';
import 'package:cartdor/partenerpage.dart';
import 'package:cartdor/scan_parteners.dart';
import 'package:cartdor/seller_dashboard.dart';
import 'package:flutter/material.dart';
import 'partenerpage.dart';
import 'dashbord_abonne.dart';
import 'scan_parteners.dart';
import 'nosservice.dart';
import 'info.dart';

class MenuAccueil extends StatelessWidget {
  final String userEmail;

  MenuAccueil({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Permet de défiler si le contenu dépasse
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Titre centré
            Text(
              "Bienvenue chez CARTD'OR!",
              style: const TextStyle(
                fontFamily: 'Poppins', // Appliquer la police Poppins
                fontSize: 35, // Taille du texte
                color: Colors.blue, // Couleur bleu élégant (Hexadécimal)
                fontWeight: FontWeight.bold, // Texte en gras pour plus d'impact
              ),
              textAlign: TextAlign.center, // Aligne le texte au centre
            ),

            SizedBox(height: 16), // Espacement entre le titre et la grille

            // Grille avec gestion d'espace flexible
            GridView.count(
              crossAxisCount: 2, // Deux colonnes
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap:
                  true, // Permet à la grille de prendre la taille nécessaire
              physics:
                  NeverScrollableScrollPhysics(), // Désactive le défilement de la grille
              children: [
                // Nouveau menu "Qui sommes-nous ?"
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Qui sommes-nous ?',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InfoPage(),
                      ),
                    );
                  },
                ),
                // Nouveau menu "Nos produits et services"
                _buildMenuItem(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Nos produits et services',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NosServicesPage(),
                      ),
                    );

                    // Action à définir pour "Nos produits et services"
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.payment,
                  title: 'Effectuez un Paiement',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScanQRCodePage_partener(userEmail: userEmail),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Tableau de Bord',
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
                  icon: Icons.store,
                  title: 'Espaces Partenaires',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerLoginScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.list,
                  title: 'Liste des Partenaires',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartnerListPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour un élément du menu
  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
