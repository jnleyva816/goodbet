import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'more_screen.dart';
import 'scorecard_screen.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _getUserData();
    _setupFCM();
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
        _initializePages();
      });
    }
  }

  void _initializePages() {
    _pages.clear();
    _pages.addAll([
      HomeContent(
        currentUser: _currentUser,
        onJoinRound: _showJoinRoundChoiceDialog,
        onCreateRound: _showHoleSelectionDialog,
      ),
      const HistoryScreen(),
      const NotificationsScreen(),
      const MoreScreen(),
    ]);
    setState(() {});
  }

  void _setupFCM() {
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground notifications
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.notification?.body ?? 'Notification received')),
      );
    });
  }

  void _showJoinRoundChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Round'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Rejoin Existing Session'),
              onTap: () {
                Navigator.of(context).pop();
                _showRejoinRoundDialog();
              },
            ),
            ListTile(
              title: const Text('Join New Session'),
              onTap: () {
                Navigator.of(context).pop();
                _showJoinRoundDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRejoinRoundDialog() {
    String accessCode = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoin Round'),
        content: TextField(
          onChanged: (value) => accessCode = value,
          decoration: const InputDecoration(labelText: 'Enter Access Code'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _joinRound(accessCode, rejoin: true);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showJoinRoundDialog() {
    String accessCode = '';
    double betAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Round'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => accessCode = value,
              decoration: const InputDecoration(labelText: 'Enter Access Code'),
            ),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) => betAmount = double.tryParse(value) ?? 0.0,
              decoration: const InputDecoration(labelText: 'Enter Bet Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _joinRound(accessCode, betAmount: betAmount);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _joinRound(String accessCode, {double betAmount = 0.0, bool rejoin = false}) async {
    try {
      final roundQuery = await FirebaseFirestore.instance
          .collection('rounds')
          .where('accessCode', isEqualTo: accessCode)
          .get();

      if (roundQuery.docs.isNotEmpty) {
        final roundDoc = roundQuery.docs.first;
        final roundId = roundDoc.id;

        final userId = FirebaseAuth.instance.currentUser!.uid;
        final roundData = roundDoc.data();
        final List<dynamic> players = roundData['players'];

        if (players.contains(userId)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScorecardScreen(roundId: roundId, accessCode: accessCode),
            ),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('rounds').doc(roundId).update({
          'players': FieldValue.arrayUnion([userId]),
          'bets.$userId': betAmount,
          'totalBets': FieldValue.increment(betAmount),
        });

        _sendFCMNotification(roundId, userId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScorecardScreen(roundId: roundId, accessCode: accessCode),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid access code'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  void _sendFCMNotification(String roundId, String userId) async {
    final roundDoc = await FirebaseFirestore.instance.collection('rounds').doc(roundId).get();
    final List<dynamic> players = roundDoc['players'];

    for (var playerId in players) {
      if (playerId != userId) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(playerId).get();
        final fcmToken = userDoc['fcmToken'];
        if (fcmToken != null) {
          _sendNotification(fcmToken, 'New Player Joined', 'A new player has joined the round.');
        }
      }
    }
  }

  Future<void> _sendNotification(String token, String title, String body) async {
    const String serverKey = 'YOUR_SERVER_KEY_HERE'; // Replace with your FCM server key

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final payload = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
    };

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      print('Error sending notification: ${response.body}');
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

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('rounds').doc(roundId).set({
      'leader': userId,
      'holes': holes,
      'accessCode': accessCode,
      'players': [userId],
      'bets': {userId: betAmount},
      'scores': {},
      'totalBets': betAmount,
      'date': DateTime.now().toIso8601String(), // Adding the date
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: _currentUser == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _currentUser!.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(_currentUser!.profileImageUrl)
                        : null,
                    child: _currentUser!.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                  ),
                ),
                Expanded(
                  child: _pages.isNotEmpty ? _pages[_selectedIndex] : const Center(child: CircularProgressIndicator()),
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

  const HomeContent({super.key, required this.currentUser, required this.onJoinRound, required this.onCreateRound});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onCreateRound,
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text('Create Round'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onJoinRound,
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text('Join Round'),
          ),
        ],
      ),
    );
  }
}

class HoleSelectionDialog extends StatelessWidget {
  final Function(int) onNext;

  const HoleSelectionDialog({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    int? selectedHoles;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('How many holes?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('9 Holes'),
                leading: Radio(
                  value: 9,
                  groupValue: selectedHoles,
                  onChanged: (value) {
                    setState(() {
                      selectedHoles = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('18 Holes'),
                leading: Radio(
                  value: 18,
                  groupValue: selectedHoles,
                  onChanged: (value) {
                    setState(() {
                      selectedHoles = value;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedHoles != null) {
                  onNext(selectedHoles!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please select the number of holes'),
                  ));
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}

class BetAmountInputDialog extends StatelessWidget {
  final Function(double) onNext;

  const BetAmountInputDialog({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    double? betAmount;

    return AlertDialog(
      title: const Text('How much to wager?'),
      content: TextField(
        keyboardType: TextInputType.number,
        onChanged: (value) {
          betAmount = double.tryParse(value) ?? 0.0;
        },
        decoration: const InputDecoration(labelText: 'Enter Bet Amount'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onNext(betAmount ?? 0.0);
          },
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class AccessCodeDialog extends StatelessWidget {
  final String accessCode;
  final VoidCallback onStartRound;

  const AccessCodeDialog({super.key, required this.accessCode, required this.onStartRound});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Access Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Share this access code with others to join the round:'),
          SelectableText(
            accessCode,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onStartRound,
          child: const Text('Start Round'),
        ),
      ],
    );
  }
}
