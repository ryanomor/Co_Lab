import 'package:co_lab/projects/project.dart';
import 'package:flutter/material.dart';

class ProjectListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement project fetching from Firestore
    return ListView.builder(
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        return ProjectCard(
          projectName: 'Project ${index + 1}',
          description: 'Project description goes here',
        );
      },
    );
  }
}
