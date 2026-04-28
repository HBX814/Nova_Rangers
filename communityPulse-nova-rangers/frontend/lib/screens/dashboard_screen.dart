import 'dart:ui';
import 'dart:math' as math;

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

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _urgentNeeds = [];
  late final AnimationController _cardShimmerController;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cardShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _cardShimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic>? summary;
    List<Map<String, dynamic>> urgentNeeds = [];
    String? summaryError;
    String? urgentNeedsError;

    try {
      summary = await ApiService.instance.fetchSummary();
    } catch (e, st) {
      summaryError = e.toString();
      print('Dashboard _loadData fetchSummary error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    try {
      urgentNeeds = (await ApiService.instance
              .fetchNeeds(status: 'OPEN', minUrgency: 5))
          .take(5)
          .toList();
    } catch (e, st) {
      urgentNeedsError = e.toString();
      urgentNeeds = [];
      print('Dashboard _loadData fetchNeeds error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _summary = summary ?? {};
      _urgentNeeds = urgentNeeds;
      _error = summaryError ?? urgentNeedsError;
      _isLoading = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF1565C0),
              ],
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFF90CAF9)],
          ).createShader(bounds),
          child: const Text(
            'CommunityPulse',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'dashboard_fab',
          onPressed: () => context.go('/submit'),
          elevation: 8,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.upload_file),
          label: const Text('Submit Report'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF0D2137),
                Color(0xFF1A2744),
              ],
              stops: [0.0, 0.34, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 106, 16, 16),
            child: _isLoading
                ? _buildShimmer()
                : _error != null
                    ? _buildError(cs)
                    : _buildContent(context, cs),
          ),
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    // ── Map real API field names from GET /analytics/summary ────────────────
    final openNeeds =
        (_summary['open_needs'] ?? _summary['total_needs_open'] ?? '--').toString();
    final volunteers = (_summary['available_volunteers'] ??
            _summary['total_volunteers_available'] ??
            '--')
        .toString();
    final completed = (_summary['completed_assignments_this_week'] ??
            _summary['total_assignments_completed_this_week'] ??
            '--')
        .toString();
    final rawAvgTime = _summary['avg_response_time_hours'];
    final avgTime = rawAvgTime == null
        ? '--'
        : '${(rawAvgTime as num).toStringAsFixed(1)}h';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E2D4A).withValues(alpha: 0.9),
                    const Color(0xFF162236).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF2A5298).withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Dashboard'),
                  const SizedBox(height: 4),
                  const Text(
                    'Live overview of community needs',
                    style: TextStyle(
                      color: Color(0xFF6B8CAE),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ── Summary grid ───────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.08,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SummaryCard(
              title: 'Open Needs',
              value: openNeeds,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF1565C0),
              shimmerController: _cardShimmerController,
              shimmerDelay: 0.00,
            ),
            SummaryCard(
              title: 'Volunteers Available',
              value: volunteers,
              icon: Icons.people_rounded,
              color: const Color(0xFF2E7D32),
              shimmerController: _cardShimmerController,
              shimmerDelay: 0.15,
            ),
            SummaryCard(
              title: 'Completed This Week',
              value: completed,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF00838F),
              shimmerController: _cardShimmerController,
              shimmerDelay: 0.30,
            ),
            SummaryCard(
              title: 'Avg Response Time',
              value: avgTime,
              icon: Icons.timer_outlined,
              color: const Color(0xFF6A1B9A),
              shimmerController: _cardShimmerController,
              shimmerDelay: 0.45,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Urgent needs section ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Recent Urgent Needs'),
            TextButton(
              onPressed: () => context.go('/needs'),
              child: const Text(
                'View all',
                style: TextStyle(color: Color(0xFF90CAF9)),
              ),
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

  Widget _buildSectionHeader(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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
                size: 48, color: cs.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No urgent needs right now',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
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
                size: 56, color: cs.error.withValues(alpha: 0.7)),
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
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
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
    required this.shimmerController,
    required this.shimmerDelay,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AnimationController shimmerController;
  final double shimmerDelay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final phase = (shimmerController.value + shimmerDelay) % 1.0;
        final wave = (math.sin(phase * 2 * math.pi) + 1) / 2;
        final opacity = 0.7 + (wave * 0.3);
        return Opacity(opacity: opacity, child: child);
      },
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B8CAE),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2D4A), Color(0xFF162236)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2A5298).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
    final isDark = cs.brightness == Brightness.dark;

    final title = (need['title'] ?? need['description'] ?? 'Untitled need')
        .toString();
    final category = (need['need_category'] ?? need['category'] ?? 'UNKNOWN')
        .toString()
        .toUpperCase();
    final urgency = (need['urgency_score'] ?? need['urgency'] ?? 0) as num;
    final district = (need['primary_location_text'] ??
            need['district'] ??
            need['location'] ??
            '')
        .toString();
    final status = (need['status'] ?? 'OPEN').toString();

    final catColor =
        AppConfig.categoryColors[category] ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: isDark ? 12 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final id = (need['id'] ?? need['need_id'] ?? '').toString();
            if (id.isNotEmpty) context.go('/needs/$id');
          },
          borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? cs.surfaceContainerHighest : Colors.white,
                    isDark ? cs.surfaceContainer : catColor.withValues(alpha: 0.06),
                  ],
                ),
              ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category colour strip
                  Container(
                    width: 5,
                    height: 58,
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: cs.onSurface,
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
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? catColor.withValues(alpha: 0.92)
                                      : catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            if (district.isNotEmpty) ...[
                              Icon(Icons.location_on,
                                  size: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 2),
                              Text(
                                district,
                               style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.70),
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
                      size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
                ],
              ),
            ),
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
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
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
