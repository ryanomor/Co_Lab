import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String projectName;
  final String description;

  const ProjectCard({
    super.key,
    required this.projectName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(projectName),
        subtitle: Text(description),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // TODO: Navigate to project details
          },
        ),
      ),
    );
  }
}
