import 'dart:math';
import 'package:cartdor/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers pour chaque champ de texte
  TextEditingController fullNameController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController professionController = TextEditingController();

  String gender = 'M';
  bool isLoading = false;

  // Form key pour valider le formulaire
  final _formKey = GlobalKey<FormState>();

  // Fonction pour générer un code utilisateur alphanumérique de 8 caractères
  String generateUserCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Validation générique pour s'assurer qu'un champ ne contient que des lettres,
  /// espaces et lettres accentuées.
  String? validateLettersOnly(String value, String fieldName) {
    // Expression régulière autorisant les lettres (majuscules/minuscules), espaces et lettres accentuées.
    final RegExp lettersRegExp = RegExp(r"^[a-zA-ZÀ-ÿ\s]+$");
    if (value.isEmpty) {
      return "Veuillez entrer votre $fieldName";
    } else if (!lettersRegExp.hasMatch(value)) {
      return "Entrez des donnees correctes svp";
    }
    return null;
  }

  // Validation de l'email
  String? validateEmail(String email) {
    if (EmailValidator.validate(email)) {
      return null;
    } else {
      return "Veuillez entrer un email valide";
    }
  }

  // Validation du téléphone
  String? validatePhone(String phone) {
    String phonePattern = r'^\+?[1-9]\d{1,14}$'; // Format international
    RegExp regExp = RegExp(phonePattern);
    if (regExp.hasMatch(phone)) {
      return null;
    } else {
      return "Veuillez entrer un numéro de téléphone valide";
    }
  }

  // Validation du mot de passe
  String? validatePassword(String password) {
    if (password.length < 6) {
      return "Le mot de passe doit comporter au moins 6 caractères";
    }
    return null;
  }

  // Validation du mot de passe confirmé
  String? validateConfirmPassword(String confirmPassword) {
    if (confirmPassword != passwordController.text) {
      return "Les mots de passe ne correspondent pas";
    }
    return null;
  }

  // Fonction d'inscription
  Future<void> signUp() async {
    setState(() {
      isLoading = true;
    });

    String userEmail = emailController.text;
    String userPassword = passwordController.text;

    try {
      // Créer l'utilisateur dans Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: userEmail, password: userPassword);

      // Mise à jour du displayName dans Firebase Authentication
      await userCredential.user?.updateDisplayName(fullNameController.text);

      // Recharger l'utilisateur pour actualiser les données
      await userCredential.user!.reload();

      // Générer un code utilisateur unique
      String userCode = generateUserCode();

      // Ajouter les données supplémentaires à Firestore
      await FirebaseFirestore.instance.collection('users').add({
        'user_code': userCode,
        'full_name': fullNameController.text,
        'city': cityController.text,
        'phone': phoneController.text,
        'email': userEmail,
        'gender': gender,
        'profession': professionController.text,
        'created_at': Timestamp.now(),
      });

      // Afficher la boîte de dialogue de succès
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Inscription réussie"),
            content: Text("Votre inscription a été effectuée avec succès."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer la boîte de dialogue
                  // Rediriger vers la page de connexion en utilisant MaterialPageRoute
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Afficher un message d'erreur personnalisé
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adresse email existante, désolé")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Couleur de fond
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Largeur fixée à 400px
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Fond du formulaire
              borderRadius: BorderRadius.circular(8), // Coins arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // Ombre sous le formulaire
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Titre centré
                  const Text(
                    "INSCRIPTION",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  // Nom complet avec validation pour lettres uniquement
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(labelText: "Nom complet"),
                  ),

                  // Ville
                  TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(labelText: "Ville"),
                    validator: (value) =>
                        validateLettersOnly(value ?? '', "ville"),
                  ),
                  // Téléphone
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Téléphone",
                      hintText: "+XX XXXXXXXXX",
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => validatePhone(value ?? ''),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Indiquez le code pays suivi du numéro",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => validateEmail(value ?? ''),
                  ),
                  // Sexe
                  Row(
                    children: [
                      Text("Sexe:"),
                      Radio(
                        value: 'M',
                        groupValue: gender,
                        onChanged: (String? value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                      ),
                      Text("Masculin"),
                      Radio(
                        value: 'F',
                        groupValue: gender,
                        onChanged: (String? value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                      ),
                      Text("Féminin"),
                    ],
                  ),
                  // Profession
                  TextFormField(
                    controller: professionController,
                    decoration: InputDecoration(labelText: "Profession"),
                    validator: (value) =>
                        validateLettersOnly(value ?? '', "profession"),
                  ),
                  // Mot de passe
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Mot de passe"),
                    validator: (value) => validatePassword(value ?? ''),
                  ),
                  // Confirmer le mot de passe
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: "Confirmer le mot de passe"),
                    validator: (value) => validateConfirmPassword(value ?? ''),
                  ),
                  SizedBox(height: 16.0),
                  // Bouton d'inscription
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Fond bleu
                            foregroundColor: Colors.white, // Texte en blanc
                            minimumSize:
                                Size(double.infinity, 50), // Largeur étendue
                            textStyle: TextStyle(
                              fontSize: 16, // Taille du texte
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              signUp(); // Appelle la méthode d'inscription
                            }
                          },
                          child: Text("S'inscrire"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
