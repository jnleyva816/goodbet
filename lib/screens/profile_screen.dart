import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'scorecard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _currentUser;
  List<Map<String, dynamic>> _roundHistory = [];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _fetchRoundHistory();
  }

  Future<void> _fetchRoundHistory() async {
    final rounds = await FirebaseFirestore.instance
        .collection('rounds')
        .where('players', arrayContains: _currentUser.uid)
        .get();

    setState(() {
      _roundHistory = rounds.docs.map((doc) {
        var data = doc.data();
        data['roundId'] = doc.id; // Adding roundId to the data
        return data;
      }).toList();
    });
  }

  void _viewRoundDetails(String roundId, String accessCode, Map<String, dynamic> courseDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScorecardScreen(
          roundId: roundId,
          accessCode: accessCode,
          courseDetails: courseDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_currentUser.profileImageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_currentUser.firstName} ${_currentUser.lastName}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _currentUser.email,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Handicap: ${_currentUser.handicap}',
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Funds: \$${_currentUser.funds.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Game History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _roundHistory.length,
                itemBuilder: (context, index) {
                  final round = _roundHistory[index];
                  return Card(
                    color: round['winner'] == _currentUser.uid ? Colors.green[100] : Colors.red[100],
                    child: ListTile(
                      title: Text('Round ${index + 1}'),
                      subtitle: Text('Score: ${round['scores'][_currentUser.uid]}'),
                      trailing: Text(round['winner'] == _currentUser.uid ? 'Won' : 'Lost'),
                      onTap: () => _viewRoundDetails(
                        round['roundId'],
                        round['accessCode'],
                        round['courseDetails'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
