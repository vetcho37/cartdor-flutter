import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'index.dart';
import 'subscription_cinetpay.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'renew_abonnement.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import du package pour générer le QR code

class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionStatusScreenState createState() =>
      _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  String? email;
  String? subscriptionStatus;
  DateTime? expirationDate;
  String? name;
  String? phone;
  String? emailclit;
  DateTime? subscriptionDate;
  String? codeunique;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
  }

  Future<String?> getCurrentUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  Future<DocumentSnapshot?> getSubscriptionStatus(String email) async {
    var result = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('emailclit', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      return result.docs[0];
    }
    return null;
  }

  Future<void> _loadUserSubscription() async {
    try {
      email = await getCurrentUserEmail();
      if (email == null) {
        _redirectToSubscriptionPage();
        return;
      }

      DocumentSnapshot? subscriptionDoc = await getSubscriptionStatus(email!);
      if (subscriptionDoc == null) {
        _redirectToSubscriptionPage();
        return;
      }

      setState(() {
        subscriptionStatus = subscriptionDoc['status'];
        expirationDate =
            (subscriptionDoc['expirationDate'] as Timestamp).toDate();
        subscriptionDate =
            (subscriptionDoc['creationDate'] as Timestamp).toDate();
        name = subscriptionDoc['name'];
        codeunique = subscriptionDoc['uniqueCode'];
        phone = subscriptionDoc['phone'];
        emailclit = subscriptionDoc['emailclit'];
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération du statut d'abonnement : $e");
      _redirectToSubscriptionPage();
    }
  }

  void _redirectToSubscriptionPage() {
    setState(() => isLoading = true);
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionPage()),
      );
    });
  }

  // Méthode pour générer et afficher le QR code à partir du code unique
  Widget _buildQrCode() {
    if (codeunique == null || codeunique!.isEmpty) {
      return Text("Aucun code unique disponible",
          style: TextStyle(fontSize: 16, color: Colors.red));
    }
    return Column(
      children: [
        SizedBox(height: 10),
        QrImageView(
          data: codeunique!,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Détails de l'Abonnement", style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: _buildSubscriptionDetails(),
              ),
            ),
    );
  }

  Widget _buildSubscriptionDetails() {
    if (subscriptionStatus == 'Actif') {
      return _buildSubscriptionContainer(
        "",
        Colors.green,
        details: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du QR code généré automatiquement
            _buildQrCode(),
            SizedBox(height: 10),
            Text(
              "Félicitations, votre abonnement est actif!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text.rich(
              TextSpan(
                text: "Code abonné: ",
                style: TextStyle(fontSize: 15, color: Colors.black),
                children: [
                  TextSpan(
                    text: codeunique,
                    style: TextStyle(fontSize: 15, color: Colors.red),
                  ),
                ],
              ),
            ),
            Text("Nom: $name", style: TextStyle(fontSize: 15)),
            Text("Téléphone: $phone", style: TextStyle(fontSize: 15)),
            Text("Email: $emailclit", style: TextStyle(fontSize: 15)),
            Text(
                "Date d'abonnement: ${subscriptionDate?.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 15)),
            Text(
                "Date d'expiration: ${expirationDate?.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    } else if (subscriptionStatus == 'Expiré') {
      return _buildSubscriptionContainer(
        "Désolé, votre abonnement a expiré.",
        Colors.red,
        details: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Date d'abonnement: ${subscriptionDate?.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 15)),
            Text(
                "Date d'expiration: ${expirationDate?.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 15)),
            Text("Code abonné: $codeunique", style: TextStyle(fontSize: 10)),
            Text("Nom: $name", style: TextStyle(fontSize: 15)),
            Text("Téléphone: $phone", style: TextStyle(fontSize: 15)),
            Text("Email: $emailclit", style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    } else {
      return _buildSubscriptionContainer(
        "Vous n'avez pas d'abonnement.",
        Colors.grey,
        details: Column(
          children: [
            Text("Aucun abonnement trouvé.", style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    }
  }

  Widget _buildSubscriptionContainer(String message, Color color,
      {required Widget details}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(message,
              style: TextStyle(
                  fontSize: 22, color: color, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          details,
          SizedBox(height: 20),
          if (subscriptionStatus == 'Expiré')
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp_renew()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Renouveler l'abonnement",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class SubscriptionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Page d'Abonnement", style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(
              "Abonnez-vous et bénéficiez de 10% de réduction\nchez nos partenaires !",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Column(
              children: [
                _buildAdvantageItem(
                    Icons.percent, "10% de réduction sur vos achats"),
                _buildAdvantageItem(Icons.card_giftcard, "Cadeaux exclusifs"),
                _buildAdvantageItem(
                    Icons.shopping_cart, "Offres spéciales partenaires"),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp_cinet()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("S'abonner maintenant",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
