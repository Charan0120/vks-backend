import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/services/api_service.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _activities = [];
  List<dynamic> _projects = [];
  bool _isLoading = true;
  int? _selectedProject;
  int? _selectedYear;
  final _searchCtrl = TextEditingController();

  final List<int> _years =
      List.generate(DateTime.now().year - 2005, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getActivities(
          year: _selectedYear,
          projectId: _selectedProject,
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        ),
        _api.getProjects(),
      ]);
      if (mounted) {
        setState(() {
          _activities = (results[0] as Map)['results'] ?? [];
          _projects = results[1] as List;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadData(),
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadData();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                fillColor: AppColors.surfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Year filter
                DropdownButton<int?>(
                  value: _selectedYear,
                  hint: const Text('All Years',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Years')),
                    ..._years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedYear = v);
                    _loadData();
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 12),
                // Project filter
                DropdownButton<int?>(
                  value: _selectedProject,
                  hint: const Text('All Projects',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Projects')),
                    ..._projects.map((p) =>
                        DropdownMenuItem(value: p['id'] as int, child: Text(p['title'] as String))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedProject = v);
                    _loadData();
                  },
                  underline: const SizedBox(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _activities.isEmpty
                    ? const Center(
                        child: Text('No activities found.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activities.length,
                          itemBuilder: (_, i) => _ActivityCard(activity: _activities[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/activities/${activity['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${activity['year']}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                if (activity['project'] != null)
                  Expanded(
                    child: Text(
                      activity['project']['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              activity['title'] ?? '',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              activity['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(activity['location'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                const Spacer(),
                if ((activity['beneficiaries_count'] ?? 0) > 0)
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${activity['beneficiaries_count']} beneficiaries',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
