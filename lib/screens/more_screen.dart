import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  UserModel? _currentUser;
  bool _isDarkMode = false;

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

  void _navigateToEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen(user: _currentUser!)),
      );
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
      // Add logic to switch themes here.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text('${_currentUser!.firstName} ${_currentUser!.lastName}'),
                  accountEmail: Text(_currentUser!.email),
                  currentAccountPicture: GestureDetector(
                    onTap: _navigateToProfile,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(_currentUser!.profileImageUrl),
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('User Settings'),
                  onTap: _navigateToEditProfile,
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Funds'),
                  onTap: () {
                    // Navigate to Add Funds page when implemented
                  },
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                  secondary: const Icon(Icons.brightness_6),
                ),
              ],
            ),
    );
  }
}
