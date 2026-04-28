import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';

// ── Reusable NeedCard widget ─────────────────────────────────────────────────

class NeedCard extends StatelessWidget {
  const NeedCard({super.key, required this.needData});

  final Map<String, dynamic> needData;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _id =>
      (needData['id'] ?? needData['need_id'] ?? '').toString();

  String get _title =>
      (needData['title'] ?? needData['description'] ?? 'Untitled need')
          .toString();

  String get _category =>
      (needData['need_category'] ?? needData['category'] ?? 'UNKNOWN')
          .toString()
          .toUpperCase();

  String get _location =>
      (needData['primary_location_text'] ??
              needData['location'] ??
              needData['district'] ??
              'Location unknown')
          .toString();

  String get _status =>
      (needData['status'] ?? 'OPEN').toString().toUpperCase();

  double get _urgency =>
      ((needData['urgency_score'] ?? needData['urgency'] ?? 0) as num)
          .toDouble();

  int get _affectedPop =>
      ((needData['affected_population'] ??
              needData['affected_count'] ??
              0) as num)
          .toInt();

  Color _urgencyColor() {
    if (_urgency > 7) return const Color(0xFFC62828);
    if (_urgency > 4) return const Color(0xFFF59E0B);
    return const Color(0xFF2E7D32);
  }

  LinearGradient _urgencyGradient() {
    if (_urgency > 7) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE53935), Color(0xFFC62828)],
      );
    }
    if (_urgency > 4) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    );
  }

  Color get _catColor =>
      AppConfig.categoryColors[_category] ?? const Color(0xFF546E7A);

  String get _catInitial =>
      _category.isNotEmpty ? _category[0].toUpperCase() : '?';

  IconData get _categoryIcon => switch (_category) {
        'FLOOD' => Icons.flood_rounded,
        'MEDICAL' => Icons.local_hospital_rounded,
        'FOOD' => Icons.restaurant_rounded,
        'DROUGHT' => Icons.wb_sunny_rounded,
        'SHELTER' => Icons.home_rounded,
        'EDUCATION' => Icons.school_rounded,
        'INFRASTRUCTURE' => Icons.construction_rounded,
        'WATER' => Icons.water_drop_rounded,
        _ => Icons.category_rounded,
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2744), Color(0xFF0F1B2D)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A4A7F).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_id.isNotEmpty) context.go('/needs/$_id');
          },
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _catColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _catColor,
                                    _catColor.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _categoryIcon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: Color(0xFF6B8CAE),
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          _location,
                                          style: const TextStyle(
                                            color: Color(0xFF6B8CAE),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: _urgencyGradient(),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _urgency.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _CategoryChip(category: _category, color: _catColor),
                            const Spacer(),
                            if (_affectedPop > 0) ...[
                              const Icon(
                                Icons.people_outline,
                                size: 13,
                                color: Color(0xFF6B8CAE),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$_affectedPop people',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B8CAE),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            StatusChip(status: _status),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF2A5298),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── CategoryChip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.color});
  final String category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── StatusChip (exported for reuse) ──────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  (Color, String) get _meta => switch (status) {
        'OPEN' => (const Color(0xFF1565C0), 'Open'),
        'IN_PROGRESS' => (const Color(0xFFE65100), 'In Progress'),
        'RESOLVED' => (const Color(0xFF2E7D32), 'Resolved'),
        'ESCALATED' => (const Color(0xFFC62828), 'Escalated'),
        _ => (Colors.grey, status),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _meta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
