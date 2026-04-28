import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../services/api_service.dart';
import '../widgets/need_card.dart';

// ── Category metadata ─────────────────────────────────────────────────────────

class _CategoryFilter {
  const _CategoryFilter({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}

const _kCategories = [
  _CategoryFilter(
      label: 'FLOOD',
      icon: Icons.water,
      color: Color(0xFF1565C0)),
  _CategoryFilter(
      label: 'MEDICAL',
      icon: Icons.medical_services_outlined,
      color: Color(0xFFC62828)),
  _CategoryFilter(
      label: 'FOOD',
      icon: Icons.restaurant_outlined,
      color: Color(0xFFE65100)),
  _CategoryFilter(
      label: 'DROUGHT',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFF5D4037)),
  _CategoryFilter(
      label: 'SHELTER',
      icon: Icons.home_outlined,
      color: Color(0xFF2E7D32)),
  _CategoryFilter(
      label: 'EDUCATION',
      icon: Icons.school_outlined,
      color: Color(0xFF6A1B9A)),
  _CategoryFilter(
      label: 'INFRASTRUCTURE',
      icon: Icons.construction_outlined,
      color: Color(0xFF546E7A)),
  _CategoryFilter(
      label: 'WATER',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF00838F)),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class NeedsListScreen extends ConsumerStatefulWidget {
  const NeedsListScreen({super.key});

  @override
  ConsumerState<NeedsListScreen> createState() => _NeedsListScreenState();
}

class _NeedsListScreenState extends ConsumerState<NeedsListScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allNeeds = [];
  List<Map<String, dynamic>> _filteredNeeds = [];

  String? _selectedCategory; // null = All
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Color _darkenColor(Color color, [double amount = 0.25]) {
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchNeeds();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchNeeds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final needs = await ApiService.instance
          .fetchNeeds(category: _selectedCategory);
      if (!mounted) return;
      setState(() {
        _allNeeds = needs;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    _applyFilters();
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
    _fetchNeeds();
  }

  void _applyFilters() {
    var results = List<Map<String, dynamic>>.from(_allNeeds);

    if (_searchQuery.isNotEmpty) {
      results = results.where((n) {
        final title =
            (n['title'] ?? n['description'] ?? '').toString().toLowerCase();
        final loc = (n['primary_location_text'] ??
                n['location'] ??
                n['district'] ??
                '')
            .toString()
            .toLowerCase();
        return title.contains(_searchQuery) || loc.contains(_searchQuery);
      }).toList();
    }

    setState(() => _filteredNeeds = results);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            'Community Needs',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            tooltip: 'Sort',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2A4A7F),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Color(0xFF6B8CAE)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1565C0),
                      decoration: InputDecoration(
                        hintText: 'Search needs by title or location…',
                        hintStyle: const TextStyle(color: Color(0xFF6B8CAE)),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18, color: Color(0xFF6B8CAE)),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Category filter chips ──────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectCategory(null),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _selectedCategory == null
                              ? LinearGradient(
                                  colors: [
                                    cs.primary,
                                    _darkenColor(cs.primary),
                                  ],
                                )
                              : null,
                          color: _selectedCategory == null
                              ? null
                              : const Color(0xFF1A2744),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (_selectedCategory == null
                                    ? cs.primary
                                    : cs.primary.withValues(alpha: 0.4)),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apps_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'All',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Category chips
                ..._kCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _selectCategory(isSelected ? null : cat.label),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cat.color,
                                      _darkenColor(cat.color),
                                    ],
                                  )
                                : null,
                            color:
                                isSelected ? null : const Color(0xFF1A2744),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color
                                  : cat.color.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B8CAE),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _toTitleCase(cat.label),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B8CAE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.12)),

          // ── Results count ─────────────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_filteredNeeds.length} need${_filteredNeeds.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B8CAE),
                ),
              ),
            ),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _error != null
                    ? _buildError(cs)
                    : _filteredNeeds.isEmpty
                        ? _buildEmpty(cs)
                        : RefreshIndicator(
                            onRefresh: _fetchNeeds,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filteredNeeds.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) => NeedCard(
                                needData: _filteredNeeds[index],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── State widgets ──────────────────────────────────────────────────────────

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No needs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different category or search term',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              _selectCategory(null);
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: cs.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            const Text(
              'Could not load needs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _fetchNeeds,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2744),
      highlightColor: const Color(0xFF22355A),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Util ───────────────────────────────────────────────────────────────────

  String _toTitleCase(String s) =>
      s[0].toUpperCase() + s.substring(1).toLowerCase();
}
