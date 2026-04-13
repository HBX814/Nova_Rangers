import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../config.dart';
import '../services/api_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────────────────

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _volunteers = [];
  Map<String, dynamic>? _activeAssignment;

  bool _isActiveAssignment(Map<String, dynamic> assignment) {
    final status = (assignment['status'] ?? '').toString().toUpperCase();
    return status == 'PENDING' || status == 'ACCEPTED' || status.isEmpty;
  }

  // ── demo volunteer (first available) ──────────────────────────────────────
  Map<String, dynamic>? get _volunteer =>
      _volunteers.isNotEmpty ? _volunteers.first : null;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final volunteers = await ApiService.instance.fetchVolunteers();
      if (!mounted) return;
      setState(() {
        _volunteers = volunteers;
        Map<String, dynamic>? selectedVolunteer;
        Map<String, dynamic>? selectedAssignment;

        for (final volunteer in volunteers) {
          final assignments =
              (volunteer['assignments'] ?? volunteer['active_assignments'])
                  as List?;
          if (assignments != null && assignments.isNotEmpty) {
            final parsedAssignments = assignments
                .whereType<Map>()
                .map((a) => Map<String, dynamic>.from(a))
                .toList();
            final activeAssignment = parsedAssignments.cast<Map<String, dynamic>?>().firstWhere(
                  (a) => a != null && _isActiveAssignment(a),
                  orElse: () => null,
                );
            if (activeAssignment == null) {
              continue;
            }
            selectedVolunteer = volunteer;
            selectedAssignment = activeAssignment;
            break;
          }
        }

        selectedVolunteer ??= volunteers.isNotEmpty ? volunteers.first : null;
        _activeAssignment = selectedAssignment;

        if (selectedVolunteer != null) {
          _volunteers = [
            selectedVolunteer,
            ...volunteers.where((v) => v['id'] != selectedVolunteer!['id']),
          ];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _acceptAssignment() async {
    final id = (_activeAssignment?['id'] ??
            _activeAssignment?['assignment_id'] ??
            '')
        .toString();
    if (id.isEmpty) return;
    try {
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/assignments/$id/accept'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment accepted!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        _loadData();
      } else {
        _showError('Accept failed [${res.statusCode}]');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _completeAssignment() async {
    final id = (_activeAssignment?['id'] ??
            _activeAssignment?['assignment_id'] ??
            '')
        .toString();
    if (id.isEmpty) return;
    try {
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/assignments/$id/complete'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment completed! Great work 🎉'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        setState(() => _activeAssignment = null);
      } else {
        _showError('Complete failed [${res.statusCode}]');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => context.go('/volunteer/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? _buildShimmer()
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  // ── content ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final cs = Theme.of(context).colorScheme;
    final name = (_volunteer?['name'] ?? _volunteer?['full_name'] ?? 'Volunteer')
        .toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting card ──────────────────────────────────────────────
        _GreetingCard(name: name, cs: cs),
        const SizedBox(height: 16),

        // ── Assignment section ─────────────────────────────────────────
        Text(
          'Current Assignment',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        _activeAssignment != null
            ? _AssignmentCard(
                assignment: _activeAssignment!,
                onAccept: _acceptAssignment,
                onComplete: _completeAssignment,
              )
            : _NoAssignmentCard(
                onBrowse: () => context.go('/volunteer/tasks'),
              ),

        const SizedBox(height: 24),

        // ── Quick stats ────────────────────────────────────────────────
        if (_volunteer != null) _StatsRow(volunteer: _volunteer!),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 110, radius: 16),
          const SizedBox(height: 16),
          _shimmerBox(width: 180, height: 20, radius: 6),
          const SizedBox(height: 12),
          _shimmerBox(height: 160, radius: 12),
          const SizedBox(height: 24),
          _shimmerBox(height: 80, radius: 12),
        ],
      ),
    );
  }

  Widget _shimmerBox(
      {double? width, double height = 60, double radius = 8}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: cs.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            const Text('Could not load data',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withOpacity(0.55)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Greeting card
// ────────────────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.name, required this.cs});
  final String name;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to make an impact?',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.volunteer_activism_rounded,
                size: 48, color: cs.primary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Assignment card
// ────────────────────────────────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onAccept,
    required this.onComplete,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onAccept;
  final VoidCallback onComplete;

  static const _green = Color(0xFF2E7D32);

  String get _needTitle =>
      (assignment['need_title'] ??
              assignment['title'] ??
              'Assigned Need')
          .toString();

  String get _district =>
      (assignment['district'] ??
              assignment['location'] ??
              '')
          .toString();

  String get _assignedAt =>
      (assignment['assigned_at'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _green, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            const Text(
              'ACTIVE ASSIGNMENT',
              style: TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Need title
            Text(
              _needTitle,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // District
            if (_district.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _district,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // Assigned at
            if (_assignedAt.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.schedule, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned: $_assignedAt',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAccept,
                    child: const Text('Accept Assignment'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onComplete,
                    child: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// No-assignment card
// ────────────────────────────────────────────────────────────────────────────

class _NoAssignmentCard extends StatelessWidget {
  const _NoAssignmentCard({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No active assignment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse available tasks and\npick one to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Browse Tasks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Quick stats row
// ────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.volunteer});
  final Map<String, dynamic> volunteer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed =
        ((volunteer['tasks_completed'] ?? volunteer['completed'] ?? 0) as num)
            .toInt();
    final rating =
        ((volunteer['rating'] ?? volunteer['performance_score'] ?? 0.0) as num)
            .toDouble();

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_outline,
            value: '$completed',
            label: 'Completed',
            color: const Color(0xFF2E7D32),
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_outline_rounded,
            value: rating.toStringAsFixed(1),
            label: 'Rating',
            color: const Color(0xFFFF6F00),
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.55))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
