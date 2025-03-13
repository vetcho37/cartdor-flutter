import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleDashboardPage extends StatelessWidget {
  final String storeName;
  final String storeLocation;
  final String storePhone;
  final String codeVendeur;

  SimpleDashboardPage({
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
    required this.codeVendeur,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('codeVendeur', isEqualTo: codeVendeur)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              var transaction = transactions[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(transaction['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Téléphone: ${transaction['phone']}'),
                      Text('Email: ${transaction['email']}'),
                      Text('Magasin: ${transaction['storeName']}'),
                      Text('Localisation: ${transaction['storeLocation']}'),
                      Text('Téléphone du magasin: ${transaction['storePhone']}'),
                      SizedBox(height: 5),
                      Text('Montant: ${transaction['initialAmount'].toStringAsFixed(2)} FCFA', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
