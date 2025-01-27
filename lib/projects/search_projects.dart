import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firestore/models/project.dart';
import 'package:co_lab/projects/project.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchProjectsScreen extends StatefulWidget {
  const SearchProjectsScreen({super.key});

  @override
  State<SearchProjectsScreen> createState() => _SearchProjectsScreenState();
}

class _SearchProjectsScreenState extends State<SearchProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<ProjectModel>> _searchProjects(String query) {
    Query projectsQuery = FirebaseFirestore.instance.collection('projects');

    // Filter public projects only
    projectsQuery = projectsQuery.where('visibility', isEqualTo: 'public');

    if (query.isNotEmpty) {
      // Search by name, description, or tags
      projectsQuery = projectsQuery.where(
        Filter.or(
          Filter('searchTerms', arrayContains: query.toLowerCase()),
          Filter('tags', arrayContains: query.toLowerCase()),
        ),
      );
    }

    return projectsQuery
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search projects...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                FilterChip(
                  label: const Text('Most Recent'),
                  selected: true,
                  onSelected: (bool selected) {
                    // Add filter logic
                  },
                ),
                FilterChip(
                  label: const Text('Popular'),
                  selected: false,
                  onSelected: (bool selected) {
                    // Add filter logic
                  },
                ),
                FilterChip(
                  label: const Text('Open for Collaboration'),
                  selected: false,
                  onSelected: (bool selected) {
                    // Add filter logic
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProjectModel>>(
              stream: _searchProjects(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No public projects found'
                              : 'No projects match your search',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ProjectCard(
                      project: project,
                      onTap: () {
                        // Navigate to project details
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
