import 'package:flutter/material.dart';

/// Volunteers Screen — Directory of registered volunteers
class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search volunteers by name, skill, or location
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // TODO: Replace with actual volunteers list from API
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: const Text('Volunteer Name'),
              subtitle: const Text('Skills — District'),
              trailing: const Chip(label: Text('AVAILABLE')),
              onTap: () {
                // TODO: Navigate to volunteer profile
              },
            ),
          );
        },
      ),
    );
  }
}
