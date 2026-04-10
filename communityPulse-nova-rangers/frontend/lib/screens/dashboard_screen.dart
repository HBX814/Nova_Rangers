import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../config.dart';
import '../services/api_service.dart';

// ── Dashboard screen ────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _urgentNeeds = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

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
      final results = await Future.wait([
        ApiService.instance.fetchSummary(),
        ApiService.instance.fetchNeeds(status: 'OPEN', minUrgency: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _urgentNeeds =
            (results[1] as List<Map<String, dynamic>>).take(5).toList();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CommunityPulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => context.go('/submit'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Submit Report'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? _buildShimmer()
              : _error != null
                  ? _buildError(cs)
                  : _buildContent(context, cs),
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    final openNeeds =
        (_summary['open_needs'] ?? _summary['openNeeds'] ?? '--').toString();
    final volunteers = (_summary['available_volunteers'] ??
            _summary['availableVolunteers'] ??
            '--')
        .toString();
    final completed = (_summary['completed_assignments'] ??
            _summary['completedAssignments'] ??
            '--')
        .toString();
    final topCategory =
        (_summary['top_category'] ?? _summary['topCategory'] ?? '--')
            .toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting row ───────────────────────────────────────────────────
        Text(
          'Dashboard',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Live overview of community needs',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 16),

        // ── Summary grid ───────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SummaryCard(
              title: 'Open Needs',
              value: openNeeds,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF1565C0),
            ),
            SummaryCard(
              title: 'Volunteers',
              value: volunteers,
              icon: Icons.people_rounded,
              color: const Color(0xFF2E7D32),
            ),
            SummaryCard(
              title: 'Completed',
              value: completed,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF00838F),
            ),
            SummaryCard(
              title: 'Top Category',
              value: topCategory,
              icon: Icons.category_rounded,
              color: const Color(0xFF6A1B9A),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Urgent needs section ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Urgent Needs',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/needs'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _urgentNeeds.isEmpty
            ? _buildEmptyNeeds(cs)
            : Column(
                children: _urgentNeeds
                    .map((need) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NeedCard(need: need),
                        ))
                    .toList(),
              ),

        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }

  Widget _buildEmptyNeeds(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: cs.primary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No urgent needs right now',
              style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: cs.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Could not load data',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
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

  // ── Shimmer skeleton ───────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          _shimmerBox(width: 160, height: 28, radius: 8),
          const SizedBox(height: 8),
          _shimmerBox(width: 220, height: 16, radius: 6),
          const SizedBox(height: 20),

          // Grid skeleton
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section title skeleton
          _shimmerBox(width: 200, height: 22, radius: 6),
          const SizedBox(height: 16),

          // Need card skeletons
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
      {required double width, required double height, double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── SummaryCard ─────────────────────────────────────────────────────────────

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NeedCard ─────────────────────────────────────────────────────────────────

class NeedCard extends StatelessWidget {
  const NeedCard({super.key, required this.need});

  final Map<String, dynamic> need;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final title = (need['title'] ?? need['description'] ?? 'Untitled need')
        .toString();
    final category =
        (need['category'] ?? 'UNKNOWN').toString().toUpperCase();
    final urgency = (need['urgency_score'] ?? need['urgency'] ?? 0) as num;
    final district = (need['district'] ?? need['location'] ?? '').toString();
    final status = (need['status'] ?? 'OPEN').toString();

    final catColor =
        AppConfig.categoryColors[category] ?? cs.primary;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final id = (need['id'] ?? need['need_id'] ?? '').toString();
          if (id.isNotEmpty) context.go('/needs/$id');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category colour strip
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: status, cs: cs),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Meta row
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (district.isNotEmpty) ...[
                          Icon(Icons.location_on,
                              size: 12,
                              color: cs.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 2),
                          Text(
                            district,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        const Spacer(),

                        // Urgency pill
                        _UrgencyPill(urgency: urgency.toDouble()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: cs.onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.cs});
  final String status;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'OPEN' => (const Color(0xFF1565C0), 'Open'),
      'IN_PROGRESS' => (const Color(0xFFE65100), 'In Progress'),
      'RESOLVED' => (const Color(0xFF2E7D32), 'Resolved'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _UrgencyPill extends StatelessWidget {
  const _UrgencyPill({required this.urgency});
  final double urgency;

  Color get _color {
    if (urgency >= 8) return const Color(0xFFC62828);
    if (urgency >= 5) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, size: 13, color: _color),
        const SizedBox(width: 2),
        Text(
          urgency.toStringAsFixed(0),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: _color),
        ),
      ],
    );
  }
}
