import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/need_card.dart';

class NeedDetailScreen extends StatefulWidget {
  final String needId;
  const NeedDetailScreen({super.key, required this.needId});

  @override
  State<NeedDetailScreen> createState() => _NeedDetailScreenState();
}

class _NeedDetailScreenState extends State<NeedDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _need;

  @override
  void initState() {
    super.initState();
    _loadNeed();
  }

  Future<void> _loadNeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final need = await ApiService.instance.fetchNeedById(widget.needId);
      if (!mounted) return;
      setState(() {
        _need = need;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Need Detail')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 52, color: cs.error.withOpacity(0.75)),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load need details',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadNeed,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNeed,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_need != null) NeedCard(needData: _need!),
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('Need ID', (widget.needId)),
                              _kv('Category', (_need?['need_category'] ?? '--').toString()),
                              _kv('Status', (_need?['status'] ?? '--').toString()),
                              _kv('Urgency', (_need?['urgency_score'] ?? '--').toString()),
                              _kv('Affected Population',
                                  (_need?['affected_population'] ?? '--').toString()),
                              _kv('Location',
                                  (_need?['primary_location_text'] ??
                                          _need?['location'] ??
                                          _need?['district'] ??
                                          '--')
                                      .toString()),
                              _kv('Description',
                                  (_need?['description'] ?? '--').toString()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}
