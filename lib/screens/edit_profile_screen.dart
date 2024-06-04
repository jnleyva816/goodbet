import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  File? _profileImage;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _handicapController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _handicapController = TextEditingController(text: widget.user.handicap.toString());
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
          androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          iosUiSettings: const IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        );
        if (croppedFile != null) {
          setState(() {
            _profileImage = croppedFile;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String> _uploadProfileImage(File image) async {
    String fileName = 'profile_${widget.user.uid}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_images').child(fileName);
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  void _updateUser() async {
    String imageUrl = widget.user.profileImageUrl;
    if (_profileImage != null) {
      imageUrl = await _uploadProfileImage(_profileImage!);
    }

    UserModel updatedUser = UserModel(
      uid: widget.user.uid,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      handicap: int.parse(_handicapController.text),
      funds: widget.user.funds,
      profileImageUrl: imageUrl,
      email: widget.user.email, // Make sure to pass the email field
    );

    try {
      await _firestore.collection('users').doc(updatedUser.uid).update(updatedUser.toMap());
      Navigator.pop(context, updatedUser); // Return the updated user
    } catch (e) {
      print('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : NetworkImage(widget.user.profileImageUrl) as ImageProvider,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _handicapController,
              decoration: const InputDecoration(labelText: 'Handicap'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.surface, backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
