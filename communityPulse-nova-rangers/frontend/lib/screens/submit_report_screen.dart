import 'package:flutter/material.dart';

import 'submission_screen.dart';

/// Legacy entrypoint kept for compatibility; reuses the real upload flow.
class SubmitReportScreen extends StatelessWidget {
  const SubmitReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubmissionScreen();
  }
}
