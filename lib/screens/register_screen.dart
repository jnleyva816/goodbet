import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String email = '';
  String password = '';
  String firstName = '';
  String lastName = '';
  String handicap = '';

  void register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          handicap: int.tryParse(handicap) ?? 0,
          funds: 0.0,
        );
        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  firstName = value;
                });
              },
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  lastName = value;
                });
              },
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  handicap = value;
                });
              },
              decoration: InputDecoration(labelText: 'Handicap'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: register,
              child: Text('Register'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.background, backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
