import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/services/api_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _activity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // We get full details by filtering activities for the specific year/project and finding by id
    // For simplicity we fetch all and filter — in production add a detail endpoint
    try {
      final data = await _api.getActivities();
      final results = data['results'] as List? ?? [];
      final found = results.firstWhere(
        (a) => a['id'] == widget.activityId,
        orElse: () => null,
      );
      if (mounted) setState(() { _activity = found; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/activities'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _activity == null
              ? const Center(child: Text('Activity not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Year badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_activity!['year']}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _activity!['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      // Meta row
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (_activity!['location']?.isNotEmpty ?? false)
                            _MetaChip(
                                icon: Icons.location_on_outlined,
                                label: _activity!['location'],
                                color: AppColors.secondary),
                          if ((_activity!['beneficiaries_count'] ?? 0) > 0)
                            _MetaChip(
                                icon: Icons.people_outline,
                                label: '${_activity!['beneficiaries_count']} beneficiaries',
                                color: AppColors.success),
                          if (_activity!['event_date'] != null)
                            _MetaChip(
                                icon: Icons.calendar_today_outlined,
                                label: _activity!['event_date'],
                                color: AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection('Description', _activity!['description']),
                      if (_activity!['impact']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 20),
                        _buildSection('Impact', _activity!['impact'],
                            iconColor: AppColors.success, icon: Icons.emoji_events_outlined),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, String? content,
      {Color? iconColor, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
              ),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            content ?? '',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.7),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
