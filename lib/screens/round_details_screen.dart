import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RoundDetailsScreen extends StatelessWidget {
  final String roundId;

  RoundDetailsScreen({required this.roundId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Round Details'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rounds').doc(roundId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Round not found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String dateString = data['date'];
          String formattedDateTime = _formatDateTime(dateString);
          Map<String, dynamic> scores = data['scores'] ?? {};
          double totalBets = data['totalBets']?.toDouble() ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Date: $formattedDateTime',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Total Bets: \$${totalBets.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Scores:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView(
                    children: scores.entries.map((entry) {
                      String playerId = entry.key;
                      Map<int, int> playerScores = entry.value.cast<int, int>();
                      return ListTile(
                        title: Text(_getPlayerName(playerId)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: playerScores.entries.map((scoreEntry) {
                            int hole = scoreEntry.key;
                            int score = scoreEntry.value;
                            return Text('Hole $hole: $score');
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime); // Format date
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime); // Format time in 12-hour format
    return '$formattedDate - $formattedTime';
  }

  String _getPlayerName(String playerId) {
    // You can implement a function to retrieve the user name from Firestore based on the player ID
    // For example, if you have a 'users' collection with user information
    // Here, we assume that the user name is directly stored in Firestore under the 'playerNames' collection
    return 'Player Name'; // Replace this with the actual implementation to get the player name
  }
}
