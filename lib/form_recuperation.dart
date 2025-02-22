import 'dart:async'; // Pour Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? transactionId;
  String paymentStatus = "En attente...";
  Timer? _timer; // Timer pour la vérification automatique

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
    });

    transactionId =
        DateTime.now().millisecondsSinceEpoch.toString(); // ID unique

    final response = await http.post(
      Uri.parse("https://api-checkout.cinetpay.com/v2/payment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "apikey": "VOTRE_API_KEY",
        "site_id": "VOTRE_SITE_ID",
        "transaction_id": transactionId,
        "amount": 100, // Montant fixe
        "currency": "XOF",
        "description": "Paiement de 100 F CFA",
        "customer_name": _nameController.text,
        "customer_email": _emailController.text,
        "customer_phone_number": _phoneController.text
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData["code"] == "201") {
        String paymentUrl = responseData["data"]["payment_url"];
        if (await canLaunch(paymentUrl)) {
          await launch(paymentUrl);
          _startAutoCheck(); // 🔄 Lancer la vérification automatique
        }
      } else {
        _showError("Erreur: ${responseData["message"]}");
      }
    } else {
      _showError("Erreur de connexion au serveur");
    }
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (transactionId == null) return;

    final response = await http.post(
      Uri.parse("https://api-checkout.cinetpay.com/v2/payment/check"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "apikey": "VOTRE_API_KEY",
        "site_id": "VOTRE_SITE_ID",
        "transaction_id": transactionId
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final status = responseData["data"]["status"];

      setState(() {
        paymentStatus = status == "ACCEPTED"
            ? "✅ Paiement accepté !"
            : "❌ Paiement échoué.";
      });

      if (status == "ACCEPTED") {
        _savePaymentToFirebase();
        _timer?.cancel(); // 🔴 Arrêter la vérification automatique
      }
    }
  }

  Future<void> _savePaymentToFirebase() async {
    if (transactionId == null) return;

    await FirebaseFirestore.instance
        .collection("subscriptions")
        .doc(transactionId)
        .set({
      "transaction_id": transactionId,
      "amount": 100,
      "status": "success",
      "customer_name": _nameController.text,
      "customer_email": _emailController.text,
      "customer_phone_number": _phoneController.text,
      "date": DateTime.now()
    });

    _showSuccess();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrêter le timer quand l'écran est fermé
    super.dispose();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Paiement réussi !"),
        content: Text("Votre paiement a bien été enregistré."),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paiement CinetPay")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Entrez votre nom",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text("Email", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Entrez votre email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text("Téléphone", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Entrez votre numéro de téléphone",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _initiatePayment,
                    child: Text("Payer 100 F CFA"),
                  ),
            SizedBox(height: 20),
            Text("Statut du paiement : $paymentStatus",
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
