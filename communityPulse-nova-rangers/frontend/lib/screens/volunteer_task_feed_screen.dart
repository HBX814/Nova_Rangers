import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../widgets/need_card.dart';

class VolunteerTaskFeedScreen extends StatefulWidget {
  const VolunteerTaskFeedScreen({super.key});

  @override
  State<VolunteerTaskFeedScreen> createState() => _VolunteerTaskFeedScreenState();
}

class _VolunteerTaskFeedScreenState extends State<VolunteerTaskFeedScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final volunteers = await ApiService.instance.fetchVolunteers();
      final volunteer =
          volunteers.isNotEmpty ? Map<String, dynamic>.from(volunteers.first) : null;
      final volunteerId = (volunteer?['id'] ?? volunteer?['volunteer_id'] ?? '').toString();

      List<Map<String, dynamic>> assignments = [];
      if (volunteerId.isNotEmpty) {
        assignments = await ApiService.instance.fetchVolunteerAssignments(volunteerId);
      } else if (volunteer?['assignments'] is List) {
        assignments = (volunteer!['assignments'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      final pendingOrAccepted = assignments.where((a) {
        final s = (a['status'] ?? '').toString().toUpperCase();
        return s == 'PENDING' || s == 'ACCEPTED' || s == 'IN_PROGRESS';
      }).toList();

      final needIds = pendingOrAccepted
          .map((a) => (a['need_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final needs = await Future.wait(
        needIds.map((id) => ApiService.instance.fetchNeedById(id)),
      );
      final needById = <String, Map<String, dynamic>>{
        for (final n in needs) (n['id'] ?? n['need_id']).toString(): n
      };

      final merged = pendingOrAccepted.map((a) {
        final needId = (a['need_id'] ?? '').toString();
        return {
          ...a,
          ...?needById[needId],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _tasks = merged;
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : _tasks.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 220),
                          Center(child: Text('No active tasks assigned right now.')),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final task = _tasks[i];
                          final needId = (task['id'] ?? task['need_id'] ?? '').toString();
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: needId.isEmpty ? null : () => context.go('/needs/$needId'),
                            child: NeedCard(needData: task),
                          );
                        },
                      ),
      ),
    );
  }
}
