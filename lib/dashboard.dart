import 'package:co_lab/projects/create_project.dart';
import 'package:co_lab/projects/list_project.dart';
import 'package:flutter/material.dart';
import 'package:co_lab/projects/project.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String titleText;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser?.displayName != null) {
      titleText =
          "${FirebaseAuth.instance.currentUser?.displayName}'s Dashboard";
    } else {
      titleText = 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create project screen
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateProjectScreen()),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Profile')),
              const PopupMenuItem(child: Text('Settings')),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ProjectListView(),
          // _buildActivities(),
          // _buildStats(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
