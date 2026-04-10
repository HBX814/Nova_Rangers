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

  Color get _catColor =>
      AppConfig.categoryColors[_category] ?? const Color(0xFF546E7A);

  String get _catInitial =>
      _category.isNotEmpty ? _category[0].toUpperCase() : '?';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_id.isNotEmpty) context.go('/needs/$_id');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: avatar | title + location | urgency ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _catColor,
                    child: Text(
                      _catInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13,
                                color: cs.onSurface.withOpacity(0.45)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _location,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
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
                  const SizedBox(width: 8),

                  // Urgency badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _urgencyColor(),
                      borderRadius: BorderRadius.circular(12),
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
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),

              // ── Bottom row: category chip | pop | status ───────────────
              Row(
                children: [
                  // Category chip
                  _CategoryChip(category: _category, color: _catColor),

                  const Spacer(),

                  // Affected population
                  if (_affectedPop > 0) ...[
                    Icon(Icons.people_outline,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      '$_affectedPop people',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                  ],

                  // Status chip
                  StatusChip(status: _status),
                ],
              ),
            ],
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
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.35), width: 0.8),
      label: Text(
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
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.45), width: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
