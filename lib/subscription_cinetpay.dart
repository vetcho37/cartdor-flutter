import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'statutabonement.dart';

String generateUniqueCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(8, (index) => chars[random.nextInt(chars.length)])
      .join();
}

class MyApp_cinet extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<MyApp_cinet> {
  final _formKey = GlobalKey<FormState>();

  // User information variables
  String userName = "";
  String userPhone = "";
  String userEmail = "";
  bool isUserInfoLoaded = false;
  bool isLoadingUserInfo = false;

  String? currentTransactionId;
  bool isProcessing = false;
  List<String> logMessages = [];

  // Pour la vérification périodique
  Timer? statusCheckTimer;
  Timer? subscriptionCheckTimer;

  @override
  void dispose() {
    statusCheckTimer?.cancel();
    subscriptionCheckTimer?.cancel();
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

  // Nouvelle méthode pour récupérer les informations de l'utilisateur connecté
  Future<void> fetchCurrentUserInfo() async {
    setState(() {
      isLoadingUserInfo = true;
    });

    try {
      // Récupérer l'utilisateur actuel
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.email != null) {
        // Enregistrer l'email de l'utilisateur connecté
        userEmail = currentUser.email!;
        addLog("Utilisateur connecté avec l'email: $userEmail");

        // Récupérer les autres informations depuis Firestore
        final usersCollection = FirebaseFirestore.instance.collection('users');
        final querySnapshot = await usersCollection
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();

          setState(() {
            // Récupérer le nom et le téléphone
            userName = userData['full_name'] ?? userData['displayName'] ?? "";
            userPhone = userData['phone'] ?? userData['phoneNumber'] ?? "";

            isUserInfoLoaded = true;
            addLog(
                "Informations utilisateur récupérées: $userName, $userPhone");
          });
        } else {
          addLog("Aucune information utilisateur trouvée dans Firestore");
        }
      } else {
        addLog("Aucun utilisateur connecté ou email non disponible");
      }
    } catch (e) {
      addLog("Erreur lors de la récupération des informations utilisateur: $e");
    } finally {
      setState(() {
        isLoadingUserInfo = false;
      });
    }
  }

  Future<void> initiateCinetPayPayment() async {
    // Vérifier si les informations utilisateur sont disponibles
    if (!isUserInfoLoaded) {
      addLog(
          "Informations utilisateur non disponibles. Impossible de procéder au paiement.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Veuillez vous connecter pour effectuer un paiement.")),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Génération d'un ID de transaction unique
      final transactionId = Random().nextInt(10000000).toString();
      currentTransactionId = transactionId;

      final amount = 2000;

      addLog("Initialisation du paiement pour la transaction: $transactionId");

      // Construction du corps de la requête
      final Map<String, dynamic> requestBody = {
        "apikey": "1536910383678539018fd155.59185723",
        "site_id": "105885554",
        "transaction_id": transactionId,
        "amount": amount,
        "currency": "XOF",
        "description": "Paiement abonnement depuis Flutter Web",
        "customer_name": userName,
        "customer_email": userEmail,
        "customer_phone_number": userPhone,
        "channels": "ALL",
        "lang": "fr"
      };

      addLog("Envoi de la requête à CinetPay...");

      // Enregistrement des données dans localStorage pour les récupérer plus tard
      final userData = {
        'name': userName,
        'email': userEmail,
        'phone': userPhone,
        'amount': amount,
        'transactionId': transactionId
      };

      html.window.localStorage['cinetpay_transaction'] = json.encode(userData);

      // Appel API pour initialiser le paiement
      final response = await http.post(
        Uri.parse('https://api-checkout.cinetpay.com/v2/payment'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      addLog("Réponse reçue (statut: ${response.statusCode})");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        addLog(
            "Paiement initialisé avec succès. Code: ${responseData['code']}");

        if (responseData['code'] == '201') {
          final paymentUrl = responseData['data']['payment_url'];
          addLog("URL de paiement: $paymentUrl");

          // Lancer la vérification périodique avant la redirection
          startPeriodicStatusCheck(transactionId);

          // Redirection vers la page de paiement
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
        addLog("Données complètes: ${json.encode(responseData['data'])}");

        if (status == "ACCEPTED") {
          addLog("PAIEMENT ACCEPTÉ! Transaction complétée avec succès");

          // Récupération des infos stockées dans localStorage
          final storedTransaction =
              html.window.localStorage['cinetpay_transaction'];

          if (storedTransaction != null) {
            final transactionData = json.decode(storedTransaction);

            // Génération automatique des valeurs
            final DateTime creationDate = DateTime.now();
            final DateTime expirationDate =
                creationDate.add(Duration(days: 30));
            final String uniqueCode = generateUniqueCode();

            // Enregistrement dans Firestore (collection: subscriptions)
            await FirebaseFirestore.instance
                .collection('subscriptions')
                .doc(transactionId)
                .set({
              "transaction_id": transactionId,
              "amount": transactionData['amount'],
              "creationDate": Timestamp.fromDate(creationDate),
              "expirationDate": Timestamp.fromDate(expirationDate),
              "emailclit": transactionData['email'],
              "name": transactionData['name'],
              "phone": transactionData['phone'],
              "status": "Actif",
              "uniqueCode": uniqueCode,
            });

            addLog("🔥 Abonnement enregistré dans Firestore !");
          } else {
            addLog("⚠️ Aucune transaction trouvée dans localStorage.");
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
      } else {
        addLog(
            "Erreur de vérification: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      addLog("Exception lors de la vérification: $e");
    }
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

  @override
  void initState() {
    super.initState();

    // Récupérer les informations de l'utilisateur connecté
    fetchCurrentUserInfo();

    // Démarrer la vérification des abonnements expirés
    startSubscriptionCheck();

    // Vérifier si une transaction est en cours depuis le localStorage
    try {
      final storedTransaction =
          html.window.localStorage['cinetpay_transaction'];
      if (storedTransaction != null) {
        final transactionData = json.decode(storedTransaction);
        currentTransactionId = transactionData['transactionId'];

        if (currentTransactionId != null) {
          addLog("Transaction en cours détectée: $currentTransactionId");

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
                child: Container(
                  width: 400,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isLoadingUserInfo
                          ? Center(child: CircularProgressIndicator())
                          : Form(
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

                                  // Affichage des informations utilisateur
                                  if (isUserInfoLoaded) ...[
                                    ListTile(
                                      title: Text("Nom"),
                                      subtitle: Text(userName),
                                      leading: Icon(Icons.person),
                                      dense: true,
                                    ),
                                    Divider(),
                                    ListTile(
                                      title: Text("Email"),
                                      subtitle: Text(userEmail),
                                      leading: Icon(Icons.email),
                                      dense: true,
                                    ),
                                    Divider(),
                                    ListTile(
                                      title: Text("Téléphone"),
                                      subtitle: Text(userPhone),
                                      leading: Icon(Icons.phone),
                                      dense: true,
                                    ),
                                  ] else ...[
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Veuillez vous connecter pour procéder au paiement",
                                        style: TextStyle(color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: 12),

                                  // Affichage du montant
                                  Card(
                                    color: Colors.blue.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            "Montant à payer",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "2000 XOF",
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 20),

                                  // Bouton de paiement
                                  ElevatedButton.icon(
                                    onPressed:
                                        (isProcessing || !isUserInfoLoaded)
                                            ? null
                                            : initiateCinetPayPayment,
                                    icon: Icon(Icons.payment),
                                    label: Text(isProcessing
                                        ? "Traitement en cours..."
                                        : "Procéder au paiement"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (currentTransactionId != null)
                Center(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),
            ],
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
              icon: Icons.subscriptions,
              title: 'verifiez votre abonnement',
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
