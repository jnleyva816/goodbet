import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  ProfileScreen({required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _navigateToEditProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: _currentUser)),
    );
    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser; // Refresh user data after editing
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_currentUser.profileImageUrl),
            ),
            SizedBox(height: 16),
            Text(
              '${_currentUser.firstName} ${_currentUser.lastName}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Handicap: ${_currentUser.handicap}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Funds: \$${_currentUser.funds.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                child: Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
