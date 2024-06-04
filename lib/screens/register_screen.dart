import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String firstName = '';
  String lastName = '';
  String handicap = '';
  bool isLoading = false;

  void register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        if (userCredential.user != null) {
          UserModel newUser = UserModel(
            uid: userCredential.user!.uid,
            firstName: firstName,
            lastName: lastName,
            handicap: int.tryParse(handicap) ?? 0,
            funds: 0.0,
            email: email, // Ensure email is set
          );
          
          // Save user data to Firestore
          await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

          // Initialize an empty rounds subcollection for the user
          await _firestore.collection('users').doc(newUser.uid).collection('rounds').add({
            'initialized': true, // You can add an initial document or just create an empty subcollection
          });

          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          firstName = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          lastName = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          handicap = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Handicap'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your handicap';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.surface, backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
