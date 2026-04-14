import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _categoryData = [];
  late final AnimationController _barsController;
  late final Animation<double> _barsAnim;

  @override
  void initState() {
    super.initState();
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barsAnim = CurvedAnimation(parent: _barsController, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _barsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.fetchSummary(),
        ApiService.instance.fetchAnalyticsByCategory(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _categoryData = (results[1] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
      _barsController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final openNeeds = (_summary['open_needs'] ?? _summary['total_needs_open'] ?? '--').toString();
    final volunteers =
        (_summary['available_volunteers'] ?? _summary['total_volunteers_available'] ?? '--')
            .toString();
    final completed = (_summary['completed_assignments_this_week'] ??
            _summary['total_assignments_completed_this_week'] ??
            '--')
        .toString();
    final rawAvg = _summary['avg_response_time_hours'];
    final avg = rawAvg == null ? '--' : '${(rawAvg as num).toStringAsFixed(1)}h';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('Analytics'),
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildShimmer()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _glassSection(
                        child: Column(
                          children: [
                            _metricTile('Open Needs', openNeeds, Icons.warning_amber_rounded),
                            _metricTile('Volunteers Available', volunteers, Icons.people_rounded),
                            _metricTile('Completed This Week', completed, Icons.check_circle_rounded),
                            _metricTile('Avg Response Time', avg, Icons.timer_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _glassSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Needs by Category',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildAnimatedBars(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _glassSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volunteer Performance',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            ..._buildPerformanceList(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF90CAF9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFFB0C4DE)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2744), Color(0xFF0F1B2D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A4A7F), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildAnimatedBars() {
    if (_categoryData.isEmpty) {
      return const Text(
        'No category data available.',
        style: TextStyle(color: Color(0xFF6B8CAE)),
      );
    }

    final maxCount = _categoryData
        .map((e) => ((e['count'] ?? 0) as num).toDouble())
        .fold<double>(1, (a, b) => b > a ? b : a);

    return SizedBox(
      height: 190,
      child: AnimatedBuilder(
        animation: _barsAnim,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _categoryData.map((row) {
              final category = (row['category'] ?? 'UNKNOWN').toString().toUpperCase();
              final count = ((row['count'] ?? 0) as num).toDouble();
              final color = AppConfig.categoryColors[category] ?? const Color(0xFF546E7A);
              final factor = maxCount == 0 ? 0 : (count / maxCount);
              final barHeight = (140 * factor * _barsAnim.value).clamp(6, 140).toDouble();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [color.withOpacity(0.9), color.withOpacity(0.55)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.length > 4 ? category.substring(0, 4) : category,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF6B8CAE)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<Widget> _buildPerformanceList() {
    if (_categoryData.isEmpty) {
      return const [
        Text(
          'No performance entries.',
          style: TextStyle(color: Color(0xFF6B8CAE)),
        ),
      ];
    }
    final maxCount = _categoryData
        .map((e) => ((e['count'] ?? 0) as num).toDouble())
        .fold<double>(1, (a, b) => b > a ? b : a);

    return _categoryData.map((row) {
      final category = (row['category'] ?? 'UNKNOWN').toString().toUpperCase();
      final count = ((row['count'] ?? 0) as num).toDouble();
      final ratio =
          maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0).toDouble();
      final color = AppConfig.categoryColors[category] ?? const Color(0xFF546E7A);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2744), Color(0xFF0F1B2D)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A4A7F), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  count.toStringAsFixed(0),
                  style: const TextStyle(color: Color(0xFFB0C4DE)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
              ).createShader(bounds),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFF23304B),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
