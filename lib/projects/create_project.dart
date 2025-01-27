import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:co_lab/firebase/firebase_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isLoading = false;
  ProjectVisibility _visibility = ProjectVisibility.public;
  final List<String> _tags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final processedTag = tag.trim().toLowerCase();
    if (processedTag.isNotEmpty && !_tags.contains(processedTag)) {
      setState(() {
        _tags.add(processedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final project = ProjectModel(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: user.uid,
        createdAt: Timestamp.now(),
        visibility: _visibility,
        tags: _tags,
        members: [
          ProjectMember(
            userId: user.uid,
            role: ProjectMemberRole.admin,
            joinedAt: Timestamp.now(),
          ),
        ],
      );

      // Create searchable terms
      final searchTerms = _generateSearchTerms(
        project.name,
        project.description,
        project.tags,
      );
      final projectData = {
        ...project.toFirestore(),
        'searchTerms': searchTerms,
      };

      await FirebaseFirestore.instance
          .collection('projects')
          .add(projectData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _generateSearchTerms(
    String name,
    String description,
    List<String> tags,
  ) {
    final terms = <String>{};
    
    // Add full name lowercase
    terms.add(name.toLowerCase());
    
    // Add each word from name
    terms.addAll(
      name.toLowerCase().split(' ').where((term) => term.length > 2)
    );
    
    // Add description words
    terms.addAll(
      description.toLowerCase().split(' ').where((term) => term.length > 2)
    );

    // Add tags
    terms.addAll(tags);
    
    return terms.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'Enter a name for your project',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                if (value.length < 3) {
                  return 'Project name must be at least 3 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your project',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
              maxLines: 3,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Tags',
                      hintText: 'Add tags to help others find your project',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _isLoading
                            ? null
                            : () => _addTag(_tagController.text),
                      ),
                    ),
                    enabled: !_isLoading,
                    onSubmitted: _isLoading ? null : _addTag,
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: _isLoading ? null : () => _removeTag(tag),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Project Visibility',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<ProjectVisibility>(
              title: const Text('Public'),
              subtitle: const Text(
                'Anyone can find and view this project',
              ),
              value: ProjectVisibility.public,
              groupValue: _visibility,
              onChanged: _isLoading
                  ? null
                  : (ProjectVisibility? value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
            ),
            RadioListTile<ProjectVisibility>(
              title: const Text('Private'),
              subtitle: const Text(
                'Only project members can access this project',
              ),
              value: ProjectVisibility.private,
              groupValue: _visibility,
              onChanged: _isLoading
                  ? null
                  : (ProjectVisibility? value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
            ),
            RadioListTile<ProjectVisibility>(
              title: const Text('Unlisted'),
              subtitle: const Text(
                'Anyone with the link can view this project',
              ),
              value: ProjectVisibility.unlisted,
              groupValue: _visibility,
              onChanged: _isLoading
                  ? null
                  : (ProjectVisibility? value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createProject,
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
                  : const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
