import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

String generateUniqueCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(8, (index) => chars[random.nextInt(chars.length)])
      .join();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp_renew());
}

class MyApp_renew extends StatefulWidget {
  const MyApp_renew({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp_renew> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final amountController = TextEditingController(text: "100");

  String? currentTransactionId;
  bool isProcessing = false;
  List<String> logMessages = [];

  // Pour la vérification périodique
  Timer? statusCheckTimer;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    amountController.dispose();
    statusCheckTimer?.cancel();
    super.dispose();
  }

  void addLog(String message) {
    print(message); // Affiche dans la console du navigateur
    setState(() {
      logMessages
          .add("[${DateTime.now().toString().split('.').first}] $message");
      // Limite le nombre de messages affichés
      if (logMessages.length > 50) {
        logMessages.removeAt(0);
      }
    });
  }

  Future<void> initiateCinetPayPayment() async {
    if (!_formKey.currentState!.validate()) {
      addLog("Formulaire invalide. Vérifiez les champs.");
      return;
    }

    // Récupérer l'email de l'utilisateur
    String email = emailController.text.trim();
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final subscriptionsCollection =
        FirebaseFirestore.instance.collection('subscriptions');

    try {
      // Vérifier si l'utilisateur existe
      final userQuery =
          await usersCollection.where('email', isEqualTo: email).get();

      if (userQuery.docs.isEmpty) {
        addLog("L'email n'existe pas dans notre base de données.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Utilisez votre email de l'inscription.")),
        );
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final DateTime now = DateTime.now();

      // Vérifier l'existence d'un abonnement
      final subscriptionQuery = await subscriptionsCollection
          .where('emailclit', isEqualTo: email)
          .orderBy('expirationDate', descending: true)
          .limit(1)
          .get();

      // Vérifier si l'abonnement est actif
      if (subscriptionQuery.docs.isNotEmpty) {
        final currentSubscription = subscriptionQuery.docs.first.data();
        final DateTime expirationDate =
            (currentSubscription['expirationDate'] as Timestamp).toDate();

        if (expirationDate.isAfter(now)) {
          // Abonnement encore actif
          addLog(
              "Vous avez déjà un abonnement actif jusqu'au ${expirationDate.toString()}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Vous avez déjà un abonnement actif. Réessayez après son expiration.")),
          );
          return;
        }
      }

      setState(() {
        isProcessing = true;
      });

      // Initialisation du paiement
      final transactionId = Random().nextInt(10000000).toString();
      currentTransactionId = transactionId;
      final amount = 100;
      final bool isResubscription = subscriptionQuery.docs.isNotEmpty;

      addLog(isResubscription
          ? "Initialisation du réabonnement"
          : "Initialisation du nouvel abonnement");

      final Map<String, dynamic> requestBody = {
        "apikey": "1536910383678539018fd155.59185723",
        "site_id": "105885554",
        "transaction_id": transactionId,
        "amount": amount,
        "currency": "XOF",
        "description": isResubscription
            ? "Réabonnement depuis Flutter Web"
            : "Nouvel abonnement depuis Flutter Web",
        "customer_name": nameController.text,
        "customer_email": emailController.text,
        "customer_phone_number": phoneController.text,
        "channels": "ALL",
        "lang": "fr"
      };

      final newExpirationDate = now.add(Duration(days: 30));

      // Stocker les informations de transaction
      html.window.localStorage['cinetpay_transaction'] = json.encode({
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'amount': amount,
        'transactionId': transactionId,
        'isResubscription': isResubscription,
        'newExpirationDate': newExpirationDate.toIso8601String(),
      });

      final response = await http.post(
        Uri.parse('https://api-checkout.cinetpay.com/v2/payment'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == '201') {
          final paymentUrl = responseData['data']['payment_url'];
          addLog("URL de paiement: $paymentUrl");

          startPeriodicStatusCheck(transactionId);
          html.window.open(paymentUrl, "_blank");
          addLog("Page de paiement ouverte dans un nouvel onglet");
        } else {
          addLog("Erreur: ${responseData['message']}");
          setState(() {
            isProcessing = false;
          });
        }
      } else {
        addLog("Erreur: ${response.statusCode} - ${response.body}");
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      addLog("Exception: $e");
      setState(() {
        isProcessing = false;
      });
    }
  }

  void startPeriodicStatusCheck(String transactionId) {
    // Annuler tout timer existant
    statusCheckTimer?.cancel();

    // Premier check immédiat
    checkPaymentStatus(transactionId);

    // Puis checks périodiques toutes les 5 secondes
    statusCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkPaymentStatus(transactionId);

      // Arrêter après 5 minutes (60 checks)
      if (timer.tick >= 60) {
        addLog("Vérification automatique arrêtée après 5 minutes");
        timer.cancel();
      }
    });

    addLog("Vérification périodique du statut démarrée");
  }

  Future<void> checkPaymentStatus(String transactionId) async {
    try {
      addLog("Vérification du statut pour transaction: $transactionId");

      final requestBody = {
        "apikey": "1536910383678539018fd155.59185723",
        "site_id": "105885554",
        "transaction_id": transactionId
      };

      final response = await http.post(
        Uri.parse('https://api-checkout.cinetpay.com/v2/payment/check'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final status = responseData['data']['status'];

        addLog("Statut de paiement: $status");

        if (status == "ACCEPTED") {
          addLog("PAIEMENT ACCEPTÉ! Transaction complétée avec succès");

          final storedTransaction =
              html.window.localStorage['cinetpay_transaction'];
          if (storedTransaction != null) {
            final transactionData = json.decode(storedTransaction);
            final DateTime creationDate = DateTime.now();
            final DateTime expirationDate =
                DateTime.parse(transactionData['newExpirationDate']);
            final String uniqueCode = generateUniqueCode();
            final bool isResubscription =
                transactionData['isResubscription'] ?? false;
            final String email = transactionData['email']; // Récupérer l'email

            // 🔍 Vérifier si un abonnement existe déjà avec cet email
            final QuerySnapshot existingSubscription = await FirebaseFirestore
                .instance
                .collection('subscriptions')
                .where('emailclit', isEqualTo: email)
                .limit(1)
                .get();

            if (existingSubscription.docs.isNotEmpty && isResubscription) {
              // 🛠 Mettre à jour l'abonnement existant
              final String docId = existingSubscription.docs.first.id;

              await FirebaseFirestore.instance
                  .collection('subscriptions')
                  .doc(docId)
                  .update({
                "creationDate": Timestamp.fromDate(creationDate),
                "expirationDate": Timestamp.fromDate(expirationDate),
                "status": "Actif",
              });

              addLog("🔄 Réabonnement mis à jour avec succès !");
            } else {
              // 🆕 Créer un nouvel abonnement si aucun n'existe ou si ce n'est pas un réabonnement
              await FirebaseFirestore.instance.collection('subscriptions').add({
                "transaction_id": transactionId,
                "amount": transactionData['amount'],
                "creationDate": Timestamp.fromDate(creationDate),
                "expirationDate": Timestamp.fromDate(expirationDate),
                "emailclit": email,
                "name": transactionData['name'],
                "phone": transactionData['phone'],
                "status": "Actif",
                "uniqueCode": uniqueCode,
                "isResubscription": isResubscription,
              });

              addLog("🆕 Nouvel abonnement créé avec succès !");
            }
          }

          statusCheckTimer?.cancel();
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        } else if (status == "REFUSED" || status == "CANCELED") {
          addLog("Paiement échoué: $status");
          statusCheckTimer?.cancel();
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        }
      }
    } catch (e) {
      addLog("Exception lors de la vérification: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    // Vérifier si une transaction est en cours depuis le localStorage
    try {
      final storedTransaction =
          html.window.localStorage['cinetpay_transaction'];
      if (storedTransaction != null) {
        final transactionData = json.decode(storedTransaction);
        currentTransactionId = transactionData['transactionId'];

        if (currentTransactionId != null) {
          addLog("Transaction en cours détectée: $currentTransactionId");

          // Restaurer les données du formulaire
          nameController.text = transactionData['name'] ?? '';
          emailController.text = transactionData['email'] ?? '';
          phoneController.text = transactionData['phone'] ?? '';

          // Démarrer la vérification
          Future.delayed(Duration(seconds: 1), () {
            startPeriodicStatusCheck(currentTransactionId!);
          });
        }
      }
    } catch (e) {
      addLog("Erreur lors de la récupération des données stockées: $e");
    }
  }

  Future<void> updateExpiredSubscriptions() async {
    try {
      // Récupérer la collection d'abonnements
      final subscriptionsCollection =
          FirebaseFirestore.instance.collection('subscriptions');

      // Récupérer la date actuelle
      final now = DateTime.now();

      // Récupérer tous les abonnements dont la date d'expiration est avant aujourd'hui
      final expiredSubscriptionsQuery = await subscriptionsCollection
          .where('expirationDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('status',
              isEqualTo:
                  'Actif') // On vérifie que l'abonnement est encore actif
          .get();

      if (expiredSubscriptionsQuery.docs.isEmpty) {
        print('Aucun abonnement expiré trouvé.');
        return;
      }

      // Pour chaque abonnement expiré, on met à jour le statut
      for (var doc in expiredSubscriptionsQuery.docs) {
        final subscriptionId = doc.id;
        final subscriptionData = doc.data();
        final expirationDate =
            (subscriptionData['expirationDate'] as Timestamp).toDate();

        // Vérification si la date d'expiration est bien antérieure à la date actuelle
        if (expirationDate.isBefore(now)) {
          // Mettre à jour le statut de l'abonnement à "Expiré"
          await subscriptionsCollection.doc(subscriptionId).update({
            'status': 'Expiré',
            'expirationDate': Timestamp.fromDate(
                now), // Mettre à jour la date d'expiration si nécessaire
          });

          // print('Abonnement ${subscriptionId} mis à jour à Expiré.');
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des abonnements expirés: $e');
    }
  }

  void startSubscriptionCheck() {
    Timer.periodic(Duration(hours: 24), (Timer t) {
      updateExpiredSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  // Centrer le formulaire horizontalement
                  child: Container(
                width: 400, // Définir la largeur du formulaire à 400px
                // Formulaire de paiement
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Abonnement CARTD'OR",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Nom complet",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Veuillez entrer votre nom";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: "Téléphone",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 8) {
                                return "Veuillez entrer un numéro de téléphone valide";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return "Veuillez entrer un email valide";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "100 XOF", // Affiche la valeur du montant
                            style: TextStyle(
                              color: Colors.blue, // Met la valeur en rouge
                              fontWeight:
                                  FontWeight.bold, // Optionnel : mettre en gras
                              fontSize:
                                  16, // Optionnel : ajuster la taille du texte
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                isProcessing ? null : initiateCinetPayPayment,
                            icon: Icon(Icons.payment),
                            label: Text(isProcessing
                                ? "Traitement en cours..."
                                : "Procéder au paiement"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blue, // Définir l'arrière-plan bleu
                              foregroundColor: Colors.white, // Texte en blanc
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),

              // Section de vérification manuelle
              if (currentTransactionId != null)
                Center(
                  // Centrer la Card
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Transaction en cours",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("ID: $currentTransactionId"),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Centrer les boutons
                            children: [
                              // Bouton Vérifier maintenant avec largeur réduite

                              SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
