import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

class MoreScreen extends StatefulWidget {
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      });
    }
  }

  void _navigateToProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(user: _currentUser!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('More'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _currentUser == null
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: ElevatedButton(
                onPressed: _navigateToProfile,
                child: Text('User Profile'),
              ),
            ),
    );
  }
}
