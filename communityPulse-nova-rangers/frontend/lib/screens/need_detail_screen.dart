import 'package:flutter/material.dart';

class NeedDetailScreen extends StatelessWidget {
  final String needId;
  const NeedDetailScreen({super.key, required this.needId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Need Detail')),
      body: Center(child: Text('Need Detail Screen for $needId — coming soon')),
    );
  }
}
