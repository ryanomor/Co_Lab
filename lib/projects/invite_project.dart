import 'package:flutter/material.dart';
import 'package:co_lab/firebase/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firestore/models/project.dart';

class ProjectInviteScreen extends StatefulWidget {
  final String projectId;
  final FirebaseRepository repository;

  const ProjectInviteScreen({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  _ProjectInviteScreenState createState() => _ProjectInviteScreenState();
}

class _ProjectInviteScreenState extends State<ProjectInviteScreen> {
  bool _isLoading = false;
  final List<Object> _suggestions = [];
  TextEditingController _emailController = TextEditingController();

  Future<void> _sendInvitation(String email) async {
    setState(() => _isLoading = true);

    try {
      final user = await widget.repository.getUser(email: email);

      final invitation = ProjectInvitation(
        projectId: widget.projectId,
        inviterId: FirebaseAuth.instance.currentUser!.uid,
        inviteeId: user!.uid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await widget.repository
          .inviteToProject(invitation);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send invitation: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite to Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                        isGreaterThanOrEqualTo: textEditingValue.text)
                    .where('email', isLessThan: textEditingValue.text + 'z')
                    .limit(5)
                    .get();

                final QuerySnapshot usernameResults = await FirebaseFirestore
                    .instance
                    .collection('users')
                    .where('userName',
                        isGreaterThanOrEqualTo: textEditingValue.text)
                    .where('userName', isLessThan: textEditingValue.text + 'z')
                    .limit(5)
                    .get();

                final allResults = [
                  ...emailResults.docs,
                  ...usernameResults.docs
                ]
                  .map((doc) => {
                      'email': doc['email'] as String,
                      'userName': doc['userName'] as String
                    })
                  .where((user) => !_suggestions.contains(user['email']))
                  .toList();

                return allResults;
              },
              displayStringForOption: (option) =>
                  '${option['userName']} (${option['email']})',
              onSelected: (Map<String, dynamic> user) {
                setState(() {
                  _suggestions.add({'username': user['userName'] as String, 'email': user['email'] as String});
                  _emailController.clear();
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                _emailController = controller;
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
                            child: CircularProgressIndicator(),
                          )
                        : null,
                  ),
                  enabled: !_isLoading,
                );
              },
            ),
            Wrap(
              spacing: 8.0,
              children: _suggestions
                  .map((suggestionObj) => Chip(
                        label: Text((suggestionObj as Map<String, dynamic>)['email']),
                        onDeleted: () {
                          setState(() {
                            _suggestions.remove(suggestionObj);
                          });
                        },
                      ))
                  .toList(),
            ),
            ElevatedButton(
              onPressed: _suggestions.isEmpty
                  ? null
                  : () {
                      for (var suggestionObj in _suggestions) {
                        _sendInvitation((suggestionObj as Map<String, dynamic>)['email']);
                      }
                    },
              child: _suggestions.length > 1 ? Text('Send Invites') : Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
