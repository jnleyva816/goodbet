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
          double totalBets = data['totalBets']?.toDouble() ?? 0.0;
          Map<String, dynamic> scores = data['scores'] ?? {};

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
                    children: scores.entries.map<Widget>((entry) {
                      String userId = entry.key;
                      Map<int, int> playerScores = entry.value.cast<int, int>();
                      int totalScore = _calculateTotalScore(playerScores);
                      return FutureBuilder(
                        future: _getPlayerName(userId),
                        builder: (context, AsyncSnapshot<String> playerNameSnapshot) {
                          if (playerNameSnapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (playerNameSnapshot.hasError) {
                            return Text("Error retrieving player name");
                          }
                          if (!playerNameSnapshot.hasData) {
                            return Text("Player name not found");
                          }
                          String playerName = playerNameSnapshot.data!;
                          return ListTile(
                            title: Text(playerName),
                            subtitle: Text('Total Score: $totalScore'),
                          );
                        },
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

  Future<String> _getPlayerName(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot.exists ? userSnapshot['name'] : 'Unknown'; // Replace 'name' with the field name in your user document that stores the user's name
  }

  int _calculateTotalScore(Map<int, int> playerScores) {
    int totalScore = 0;
    playerScores.values.forEach((score) {
      totalScore += score;
    });
    return totalScore;
  }

  String _formatDateTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat('MM-dd-yyyy').format(dateTime); // Format date
    String formattedTime = DateFormat('hh:mm:ss a').format(dateTime); // Format time in 12-hour format
    return '$formattedDate - $formattedTime';
  }
}
