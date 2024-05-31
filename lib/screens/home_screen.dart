import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 // Import Google Fonts
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
import '../models/user_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'more_screen.dart';
import 'scorecard_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _getUserData();
    _pages.addAll([
      HomeContent(
        currentUser: _currentUser,
        onJoinRound: _showJoinRoundDialog,
        onCreateRound: _showHoleSelectionDialog,
      ),
      HistoryScreen(),
      NotificationsScreen(),
      MoreScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _pages[0] = HomeContent(
          currentUser: _currentUser,
          onJoinRound: _showJoinRoundDialog,
          onCreateRound: _showHoleSelectionDialog,
        );
      });
    }
  }

  void _showJoinRoundDialog() {
    String accessCode = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Round'),
        content: TextField(
          onChanged: (value) => accessCode = value,
          decoration: InputDecoration(labelText: 'Enter Access Code'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _joinRound(accessCode);
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  void _joinRound(String accessCode) async {
    try {
      final roundQuery = await FirebaseFirestore.instance
          .collection('rounds')
          .where('accessCode', isEqualTo: accessCode)
          .get();

      if (roundQuery.docs.isNotEmpty) {
        final roundDoc = roundQuery.docs.first;
        final roundData = roundDoc.data();
        final List<dynamic> players = roundData['players'];
        final Map<String, dynamic> playerBets = Map<String, dynamic>.from(roundData['bets'] ?? {});

        for (var playerId in players) {
          DocumentSnapshot playerDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
          playerBets[playerId] = playerDoc['betAmount'] ?? 0.0;
        }

        _showBetAmountDialog(accessCode, roundDoc.id, playerBets);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invalid access code'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  void _showBetAmountDialog(String accessCode, String roundId, Map<String, dynamic> playerBets) {
    double betAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Bet Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Other players bets:'),
            for (var player in playerBets.entries)
              Text('${player.key}: \$${player.value.toStringAsFixed(2)}'),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                betAmount = double.tryParse(value) ?? 0.0;
              },
              decoration: InputDecoration(labelText: 'Your Bet Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _finalizeJoinRound(roundId, accessCode, betAmount);
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }

  void _finalizeJoinRound(String roundId, String accessCode, double betAmount) async {
    try {
      if (_currentUser != null) {
        await FirebaseFirestore.instance.collection('rounds').doc(roundId).update({
          'players': FieldValue.arrayUnion([_currentUser!.uid]),
          'bets.${_currentUser!.uid}': betAmount,
          'totalBets': FieldValue.increment(betAmount),
        });

        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'betAmount': betAmount,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScorecardScreen(roundId: roundId, accessCode: accessCode),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  void _showHoleSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => HoleSelectionDialog(
        onNext: (int holes) {
          Navigator.of(context).pop();
          _showBetAmountInputDialog(holes);
        },
      ),
    );
  }

  void _showBetAmountInputDialog(int holes) {
    showDialog(
      context: context,
      builder: (context) => BetAmountInputDialog(
        onNext: (double betAmount) {
          Navigator.of(context).pop();
          _generateAccessCode(holes, betAmount);
        },
      ),
    );
  }

  void _generateAccessCode(int holes, double betAmount) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final accessCode = String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(Random().nextInt(chars.length))),
    );

    showDialog(
      context: context,
      builder: (context) => AccessCodeDialog(
        accessCode: accessCode,
        onStartRound: () {
          Navigator.of(context).pop();
          _createRound(holes, betAmount, accessCode);
        },
      ),
    );
  }

  void _createRound(int holes, double betAmount, String accessCode) async {
    final roundId = FirebaseFirestore.instance.collection('rounds').doc().id;

    await FirebaseFirestore.instance.collection('rounds').doc(roundId).set({
      'leader': _currentUser!.uid,
      'holes': holes,
      'accessCode': accessCode,
      'players': [_currentUser!.uid],
      'bets': {_currentUser!.uid: betAmount},
      'scores': {},
      'totalBets': betAmount,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScorecardScreen(roundId: roundId, accessCode: accessCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg', // Your background image
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: _currentUser == null
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: _currentUser!.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(_currentUser!.profileImageUrl)
                              : null,
                          child: _currentUser!.profileImageUrl.isEmpty ? Icon(Icons.person, size: 30) : null,
                        ),
                      ),
                      Expanded(
                        child: _pages[_selectedIndex],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}

class HomeContent extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onJoinRound;
  final VoidCallback onCreateRound;

  HomeContent({required this.currentUser, required this.onJoinRound, required this.onCreateRound});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onCreateRound,
            child: Text('Create Round'),
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onJoinRound,
            child: Text('Join Round'),
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoleSelectionDialog extends StatelessWidget {
  final Function(int) onNext;

  HoleSelectionDialog({required this.onNext});

  @override
  Widget build(BuildContext context) {
    int? _selectedHoles;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('How many holes?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('9 Holes'),
                leading: Radio(
                  value: 9,
                  groupValue: _selectedHoles,
                  onChanged: (value) {
                    setState(() {
                      _selectedHoles = value as int?;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text('18 Holes'),
                leading: Radio(
                  value: 18,
                  groupValue: _selectedHoles,
                  onChanged: (value) {
                    setState(() {
                      _selectedHoles = value as int?;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedHoles != null) {
                  onNext(_selectedHoles!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please select the number of holes'),
                  ));
                }
              },
              child: Text('Next'),
            ),
          ],
        );
      },
    );
  }
}

class BetAmountInputDialog extends StatelessWidget {
  final Function(double) onNext;

  BetAmountInputDialog({required this.onNext});

  @override
  Widget build(BuildContext context) {
    double? _betAmount;

    return AlertDialog(
      title: Text('How much to wager?'),
      content: TextField(
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _betAmount = double.tryParse(value) ?? 0.0;
        },
        decoration: InputDecoration(labelText: 'Enter Bet Amount'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onNext(_betAmount ?? 0.0);
          },
          child: Text('Next'),
        ),
      ],
    );
  }
}

class AccessCodeDialog extends StatelessWidget {
  final String accessCode;
  final VoidCallback onStartRound;

  AccessCodeDialog({required this.accessCode, required this.onStartRound});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Access Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Share this access code with others to join the round:'),
          SelectableText(
            accessCode,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onStartRound,
          child: Text('Start Round'),
        ),
      ],
    );
  }
}
