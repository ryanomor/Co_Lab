import 'package:flutter/material.dart';
import 'package:co_lab/firebase/helpers.dart';

class ProjectInvitationScreen extends StatefulWidget {
  final String projectId;
  final FirebaseRepository repository;

  const ProjectInvitationScreen({
    super.key, 
    required this.projectId,
    required this.repository,
  });

  @override
  _ProjectInvitationScreenState createState() => _ProjectInvitationScreenState();
}

class _ProjectInvitationScreenState extends State<ProjectInvitationScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendInvitation() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an email address'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.repository.inviteToProject(
        widget.projectId, 
        _emailController.text.trim()
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent successfully!'))
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invitation: ${e.toString()}'))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite to Project')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email to invite'
              ),
              enabled: !_isLoading,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendInvitation,
              child: _isLoading 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Send Invitation'),
            )
          ],
        ),
      ),
    );
  }
}