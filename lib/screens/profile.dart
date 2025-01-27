import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/auth/auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = UserModel.fromFirestore(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userData.photoUrl != null
                          ? NetworkImage(userData.photoUrl!)
                          : null,
                      child: userData.photoUrl == null
                          ? Text(
                              userData.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Add photo upload logic
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Username'),
                subtitle: Text(userData.username),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(userData.email ?? 'No email'),
              ),
              if (userData.phoneNumber != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(userData.phoneNumber!),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true, // Replace with actual notification settings
                  onChanged: (bool value) {
                    // Update notification settings
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (bool value) {
                    // Update theme settings
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                onTap: () {
                  // Navigate to help screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () {
                  // Navigate to privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: _signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}
