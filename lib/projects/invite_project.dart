import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firebase/firebase_service.dart';

class ProjectInviteScreen extends StatefulWidget {
  final String projectId;
  final FirebaseService repository;

  const ProjectInviteScreen({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  State createState() => _ProjectInviteScreenState();
}

class _ProjectInviteScreenState extends State<ProjectInviteScreen> {
  bool _isLoading = false;
  final List<Map<String, String>> _selectedUsers = [];
  TextEditingController _searchController = TextEditingController();
  ProjectModel? _project;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    try {
      final project = await widget.repository.getProject(widget.projectId);
      setState(() => _project = project);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load project details: $e')),
        );
      }
    }
  }

  Future<void> _sendInvitation(String email) async {
    if (_project == null) return;
    
    try {
      // Check if user exists
      final user = await widget.repository.getUser(email: email);
      if (user == null) {
        throw Exception('User not found');
      }

      // Check if user is already a member
      if (_project!.members.any((member) => member['userId'] == user.uid)) {
        throw Exception('User is already a member of this project');
      }

      // Check if user is already invited
      if (_project!.invitedUsers.contains(user.uid)) {
        throw Exception('User has already been invited to this project');
      }

      final invitation = ProjectInvitation(
        projectId: widget.projectId,
        inviterId: FirebaseAuth.instance.currentUser!.uid,
        inviteeId: user.uid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await widget.repository.inviteToProject(invitation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to ${user.username}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _sendInvitations() async {
    setState(() => _isLoading = true);

    try {
      for (var user in _selectedUsers) {
        await _sendInvitation(user['email']!);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite to Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 3) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }

                final QuerySnapshot emailResults = await FirebaseFirestore
                    .instance
                    .collection('users')
                    .where('email',
                        isGreaterThanOrEqualTo: textEditingValue.text.toLowerCase())
                    .where('email',
                        isLessThan: textEditingValue.text.toLowerCase() + 'z')
                    .limit(5)
                    .get();

                final QuerySnapshot usernameResults = await FirebaseFirestore
                    .instance
                    .collection('users')
                    .where('username',
                        isGreaterThanOrEqualTo: textEditingValue.text.toLowerCase())
                    .where('username',
                        isLessThan: textEditingValue.text.toLowerCase() + 'z')
                    .limit(5)
                    .get();

                final allResults = [
                  ...emailResults.docs,
                  ...usernameResults.docs
                ]
                    .map((doc) => {
                          'email': doc['email'] as String,
                          'username': doc['username'] as String,
                          'uid': doc.id,
                        })
                    .where((user) =>
                        !_selectedUsers
                            .any((selected) => selected['email'] == user['email']) &&
                        !(_project?.members.any((member) =>
                                member['userId'] == user['uid']) ??
                            false) &&
                        !(_project?.invitedUsers.contains(user['uid']) ?? false))
                    .toList();

                return allResults;
              },
              displayStringForOption: (option) =>
                  '${option['username']} (${option['email']})',
              onSelected: (Map<String, dynamic> user) {
                setState(() {
                  _selectedUsers.add({
                    'username': user['username'],
                    'email': user['email'],
                  });
                  _searchController.clear();
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                _searchController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search users',
                    hintText: 'Type username or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  enabled: !_isLoading,
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedUsers.isNotEmpty) ...[
              const Text(
                'Selected Users:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedUsers
                    .map((user) => Chip(
                          avatar: CircleAvatar(
                            child: Text(user['username']![0].toUpperCase()),
                          ),
                          label: Text(user['username']!),
                          onDeleted: () {
                            setState(() {
                              _selectedUsers.remove(user);
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedUsers.isEmpty || _isLoading 
                  ? null 
                  : _sendInvitations,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedUsers.length == 1
                          ? 'Send Invite'
                          : 'Send ${_selectedUsers.length} Invites',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
