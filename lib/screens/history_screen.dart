import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'round_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _clearHistory(context, userId);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rounds').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No rounds found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String date = data['date'] ?? 'Unknown date';
              String formattedDate = _formatDateTime(date);
              double totalBets = data['totalBets']?.toDouble() ?? 0.0;

              // Calculate total score for the current user for this round
              double totalScore = 0.0;
              if (data['scores'] != null && data['scores'][userId] != null) {
                Map<String, dynamic> userScores = data['scores'][userId];
                userScores.values.forEach((score) {
                  totalScore += (score as num).toDouble();
                });
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text("Round on $formattedDate"),
                  subtitle: Text("Total Score: $totalScore - Total Bets: \$${totalBets.toStringAsFixed(2)}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoundDetailsScreen(roundId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context, String? userId) async {
    if (userId != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('rounds')
          .where('scores.$userId', isNotEqualTo: null)
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('History cleared')));
    }
  }

String _formatDateTime(String dateString) {
  DateTime dateTime = DateTime.parse(dateString);
  String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime); // Format date
  String formattedTime = DateFormat('hh:mm:ss a').format(dateTime); // Format time in 12-hour format
  return '$formattedDate - $formattedTime';
}
}
