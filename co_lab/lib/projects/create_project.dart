import 'package:flutter/material.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _projectNameController = TextEditingController();
  final _projectDescriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            TextField(
              controller: _projectDescriptionController,
              decoration:
                  const InputDecoration(labelText: 'Project Description'),
              maxLines: 3,
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement project creation logic
              },
              child: const Text('Create Project'),
            )
          ],
        ),
      ),
    );
  }
}
