import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'results_screen.dart'; // Import the ResultsScreen

class ScorecardScreen extends StatefulWidget {
  final String roundId;
  final String accessCode;

  ScorecardScreen({required this.roundId, required this.accessCode});

  @override
  _ScorecardScreenState createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  Map<String, Map<int, int>> _scores = {};
  List<String> _playerIds = [];
  Map<String, String> _playerNames = {};
  Map<String, double> _bets = {};
  int _holes = 18;
  double _totalBets = 0.0;
  Map<int, Map<String, bool>> _highlightWinners = {};
  Map<int, Map<String, bool>> _highlightLosers = {};
  Map<int, Map<String, bool>> _highlightTies = {};

  @override
  void initState() {
    super.initState();
    _getRoundData();
  }

  void _getRoundData() async {
    final roundDoc = await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).get();
    final roundData = roundDoc.data();

    if (roundData != null) {
      List<String> playerIds = List<String>.from(roundData['players'] ?? []);
      Map<String, dynamic> betsMap = Map<String, dynamic>.from(roundData['bets'] ?? {});
      double totalBets = roundData['totalBets']?.toDouble() ?? 0.0;

      // Convert dynamic bets to double
      betsMap.forEach((key, value) {
        _bets[key] = (value as num).toDouble();
      });

      // Fetch player names
      for (String playerId in playerIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
        if (userDoc.exists) {
          _playerNames[playerId] = "${userDoc['firstName']} ${userDoc['lastName']}";
        }
      }

      setState(() {
        _playerIds = playerIds;
        _holes = roundData['holes'] ?? 18;
        _scores = _playerIds.asMap().map((_, playerId) => MapEntry(playerId, {}));
        _totalBets = totalBets;
      });
    }
  }

  void _submitScores() async {
    // Convert scores to a format suitable for Firestore
    Map<String, Map<String, int>> firestoreScores = _scores.map((playerId, scores) {
      return MapEntry(playerId, scores.map((hole, score) {
        return MapEntry(hole.toString(), score);
      }));
    });

    try {
      await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
        'scores': firestoreScores,
      });
      // Navigate to ResultsScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            scores: _scores,
            playerNames: _playerNames,
            holes: _holes,
            bets: _bets,
          ),
        ),
      );
    } catch (e) {
      print('Error updating scores: $e');
    }
  }

  void _addPlayer(String name, double betAmount) async {
    String newPlayerId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add player to Firestore
    await FirebaseFirestore.instance.collection('rounds').doc(widget.roundId).update({
      'players': FieldValue.arrayUnion([newPlayerId]),
      'bets.$newPlayerId': betAmount,
      'scores.$newPlayerId': {},
      'totalBets': FieldValue.increment(betAmount), // Increment total bets
    });

    // Update local state
    setState(() {
      _playerNames[newPlayerId] = name;
      _playerIds.add(newPlayerId);
      _bets[newPlayerId] = betAmount;
      _scores[newPlayerId] = {};
      _totalBets += betAmount;
    });
  }

  void _showAddPlayerDialog() {
    String name = '';
    double betAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => name = value,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) => betAmount = double.tryParse(value) ?? 0.0,
              decoration: InputDecoration(labelText: 'Bet Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addPlayer(name, betAmount);
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateScores(String playerId, int hole, int score) {
    setState(() {
      _scores[playerId]![hole] = score;
      _highlightWinnersAndLosers(hole);
    });
  }

  void _highlightWinnersAndLosers(int hole) {
    if (_playerIds.isEmpty) return;

    int? minScore;
    int? maxScore;
    for (String playerId in _playerIds) {
      int score = _scores[playerId]![hole] ?? 0;
      if (minScore == null || score < minScore) {
        minScore = score;
      }
      if (maxScore == null || score > maxScore) {
        maxScore = score;
      }
    }

    setState(() {
      _highlightWinners[hole] = {};
      _highlightLosers[hole] = {};
      _highlightTies[hole] = {};

      for (String playerId in _playerIds) {
        int score = _scores[playerId]![hole] ?? 0;
        if (score == minScore && score == maxScore) {
          _highlightTies[hole]![playerId] = true;
        } else if (score == minScore) {
          _highlightWinners[hole]![playerId] = true;
        } else if (score == maxScore) {
          _highlightLosers[hole]![playerId] = true;
        }
      }
    });
  }

  Widget _buildScoreInput(String playerId, int hole) {
    int? currentScore = _scores[playerId]![hole];
    return DropdownButton<int>(
      value: currentScore,
      items: List.generate(10, (i) => i).map((score) {
        return DropdownMenuItem(
          value: score,
          child: Text(score.toString()),
        );
      }).toList(),
      onChanged: (value) {
        _updateScores(playerId, hole, value!);
      },
    );
  }

  Color _getCellColor(String playerId, int hole) {
    if (_highlightWinners[hole] != null && _highlightWinners[hole]![playerId] == true) {
      return Colors.green;
    } else if (_highlightLosers[hole] != null && _highlightLosers[hole]![playerId] == true) {
      return Colors.red;
    } else if (_highlightTies[hole] != null && _highlightTies[hole]![playerId] == true) {
      return Colors.yellow;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scorecard - Code: ${widget.accessCode}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Text(
              'Total Bets: \$${_totalBets.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 120,
                  child: Center(child: Text('Player')),
                ),
                for (int hole = 1; hole <= _holes; hole++)
                  Container(
                    width: 60,
                    child: Center(child: Text('Hole $hole')),
                  ),
              ],
            ),
            for (String playerId in _playerIds)
              Row(
                children: [
                  Container(
                    width: 120,
                    child: Center(child: Text(_playerNames[playerId] ?? playerId)),
                  ),
                  for (int hole = 1; hole <= _holes; hole++)
                    Container(
                      width: 60,
                      color: _getCellColor(playerId, hole),
                      child: _buildScoreInput(playerId, hole),
                    ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _submitScores,
              child: Text('Submit Scores'),
            ),
            ElevatedButton(
              onPressed: _showAddPlayerDialog,
              child: Text('Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}
