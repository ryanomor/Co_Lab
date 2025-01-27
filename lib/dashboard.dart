import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/projects/list_project.dart';
import 'package:co_lab/projects/create_project.dart';
import 'package:co_lab/projects/search_projects.dart';
import 'package:co_lab/screens/profile.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/firebase/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;

  const DashboardScreen({super.key, required this.uid});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String titleText;
  int _selectedIndex = 0;
  final FirebaseService repository = FirebaseService();

  _getTitleText(UserModel? user) {
    return user?.username != null
        ? '${user!.username}\'s Dashboard'
        : 'Dashboard';
  }

  final List<Widget> _screens = [
    const SearchProjectsScreen(), // Browse/Search all projects
    const ProjectListView(),      // User's projects
    const CreateProjectScreen(),  // Create new project
    const ProfileScreen(),        // User profile & settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<UserModel?>(
          future: repository.getUser(uid: widget.uid),
          builder: (context, snapshot) {
            return Text(_getTitleText(snapshot.data));
          },
        ),
        actions: [
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
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'My Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
