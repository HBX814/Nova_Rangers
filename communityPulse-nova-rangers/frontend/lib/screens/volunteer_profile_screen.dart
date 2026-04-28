import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../config.dart';
import '../services/api_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────────────────

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _volunteer = {};
  bool _isAvailable = false;
  bool _isUpdatingStatus = false;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final volunteers =
          await ApiService.instance.fetchVolunteers(status: 'AVAILABLE');
      if (!mounted) return;
      final v = volunteers.isNotEmpty
          ? volunteers.first
          : <String, dynamic>{};
      setState(() {
        _volunteer = v;
        final status =
            (v['availability_status'] ?? v['status'] ?? 'UNAVAILABLE')
                .toString()
                .toUpperCase();
        _isAvailable = status == 'AVAILABLE';
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

  Future<void> _toggleAvailability(bool value) async {
    final id =
        (_volunteer['id'] ?? _volunteer['volunteer_id'] ?? '').toString();
    if (id.isEmpty) {
      setState(() => _isAvailable = value);
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      final newStatus = value ? 'AVAILABLE' : 'OFFLINE';
      final res = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/volunteers/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'availability_status': newStatus}),
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _isAvailable = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status updated to ${value ? "Available" : "Unavailable"}'),
            backgroundColor: value
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade700,
          ),
        );
      } else {
        _showError('Status update failed [${res.statusCode}]');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
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
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1565C0)],
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
            'My Profile',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── content ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final name =
        (_volunteer['name'] ?? _volunteer['full_name'] ?? 'Volunteer')
            .toString();
    final initials = _initials(name);
    final email =
        (_volunteer['email'] ?? '').toString();
    final phone =
        (_volunteer['phone'] ?? _volunteer['contact'] ?? '').toString();
    final score =
        ((_volunteer['performance_score'] ??
                    _volunteer['rating'] ??
                    0.0) as num)
                .toDouble();
    final completed =
        ((_volunteer['tasks_completed'] ??
                    _volunteer['completed'] ??
                    0) as num)
                .toInt();
    final district =
        (_volunteer['district'] ?? _volunteer['location'] ?? '').toString();
    final skills = _parseSkills();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Avatar + name + rating ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: tt.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Performance score
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(42, 42),
                      painter: _PerformanceArcPainter(
                        progress: (score / 5).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'performance score',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B8CAE),
                      ),
                    ),
                  ],
                ),
                if (district.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        district,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B8CAE),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Availability toggle ────────────────────────────────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              secondary: Icon(
                Icons.circle,
                size: 14,
                color: _isAvailable
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade400,
              ),
              title: const Text('Available for assignments',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _isAvailable
                    ? 'You are visible to coordinators'
                    : 'You will not receive new tasks',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              value: _isAvailable,
              onChanged: _isUpdatingStatus ? null : _toggleAvailability,
              activeThumbColor: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tasks completed card ───────────────────────────────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tasks completed',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Skills section ─────────────────────────────────────────────
          if (skills.isNotEmpty) ...[
            Text(
              'Skills',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Chip(
                      avatar: const Icon(Icons.bolt, size: 14),
                      label: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0C4DE),
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.transparent),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side:
                            const BorderSide(color: Color(0xFF2A5298), width: 1),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Contact info ───────────────────────────────────────────────
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            Text(
              'Contact',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (email.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.email_outlined, size: 20),
                      title: Text(email, style: const TextStyle(fontSize: 14)),
                      dense: true,
                    ),
                  if (email.isNotEmpty && phone.isNotEmpty)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  if (phone.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.phone_outlined, size: 20),
                      title: Text(phone, style: const TextStyle(fontSize: 14)),
                      dense: true,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<String> _parseSkills() {
    final raw = _volunteer['skills'] ?? _volunteer['skill_tags'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  // ── shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 48, backgroundColor: Colors.white),
            const SizedBox(height: 14),
            _shimmerBox(width: 160, height: 22, radius: 8),
            const SizedBox(height: 8),
            _shimmerBox(width: 120, height: 16, radius: 6),
            const SizedBox(height: 24),
            _shimmerBox(height: 70, radius: 12),
            const SizedBox(height: 12),
            _shimmerBox(height: 90, radius: 12),
            const SizedBox(height: 12),
            _shimmerBox(width: 100, height: 18, radius: 6),
            const SizedBox(height: 10),
            _shimmerBox(height: 40, radius: 20),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(
      {double? width, double height = 60, double radius = 8}) {
    return Container(
      width: width,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 56, color: cs.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            const Text('Could not load profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                )),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceArcPainter extends CustomPainter {
  _PerformanceArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final center = Offset(size.width / 2, size.height / 2);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A4A7F);
    canvas.drawArc(rect, 0, 2 * math.pi, false, basePaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    final sweep = (2 * math.pi) * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _PerformanceArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
