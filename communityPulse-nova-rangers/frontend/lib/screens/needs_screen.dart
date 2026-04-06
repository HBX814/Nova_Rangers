import 'package:flutter/material.dart';

/// Needs Screen — Lists all community needs with filters
class NeedsScreen extends StatelessWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Needs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter bottom sheet (category, status, urgency)
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // TODO: Toggle map view
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // TODO: Replace with actual needs list from API
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: const Text('Need title'),
              subtitle: const Text('Category — Location'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to need detail
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create need form
        },
        icon: const Icon(Icons.add),
        label: const Text('New Need'),
      ),
    );
  }
}
