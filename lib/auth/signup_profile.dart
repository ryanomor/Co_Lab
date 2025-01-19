import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/firebase/firebase_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;

  const ProfileSetupScreen({super.key, required this.uid});

  @override
  State createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _imageFile;
  final FirebaseService firestore = FirebaseService();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionLabelText =
      'Short bio about yourelf and skills you can bring to a project';
  final Set<Skills> _selectedSkills = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            _buildSkillsSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _descriptionLabelText,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Complete Profile'),
            ),
            ElevatedButton(
              onPressed: _cancelProfileSetup,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Future<void> _pickImage(ImageSource source) async {
      final themeColor = Theme.of(context).primaryColor;
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarColor: themeColor,
              statusBarColor: themeColor,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              aspectRatioLockEnabled: true,
              minimumAspectRatio: 1.0,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = File(croppedFile.path);
          });
        }
      }
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
          child: _imageFile == null ? const Icon(Icons.person, size: 50) : null,
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_camera),
          label: const Text('Change Photo'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Select Image Source'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Camera'),
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  TextButton(
                    child: const Text('Library'),
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkillsSelector() {
    final Map<Skills, String> _availableSkills = {
      Skills.editor: 'Editor',
      Skills.storyboard: 'Storyboard',
      Skills.projectManagement: 'Project Manager',
      Skills.graphicDesign: 'Graphic Design',
      Skills.webDesign: 'Web Design',
      Skills.development: 'Development',
      Skills.marketing: 'Marketing',
      Skills.writer: 'Writer',
      Skills.illustrator: 'Illustrator',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your skills:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _availableSkills.entries.map((entry) {
            final isSelected = _selectedSkills.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(entry.key);
                  } else {
                    _selectedSkills.remove(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required')),
      );
      return;
    }

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadProfilePhoto();
      }

      final profile = {
        'username': _usernameController.text,
        'photoUrl': photoUrl,
        'description': _descriptionController.text,
        'skills': _selectedSkills.toList(),
      };

      await firestore.updateUser(widget.uid, profile);

      Navigator.pushNamed(
        context,
        '/dashboard',
        arguments: widget.uid,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<String> _uploadProfilePhoto() async {
    final fileName =
        '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
    final ref =
        FirebaseStorage.instance.ref().child('profile_photos/$fileName');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _cancelProfileSetup() async {
    try {
      await firestore.deleteUser(uid: widget.uid);
      await FirebaseAuth.instance.currentUser!.delete();
      Navigator.pop(context);
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
