import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/services/api_service.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _activities = [];
  List<dynamic> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final actData = await _api.getActivities(page: 1);
      final projData = await _api.getProjects();
      if (mounted) {
        setState(() {
          _activities = (actData['results'] as List?) ?? [];
          _projects = projData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load activities: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _api.deleteActivity(id);
      _load();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showFormDialog({Map<String, dynamic>? activity}) {
    final isEdit = activity != null;
    final titleCtrl = TextEditingController(text: activity?['title']);
    final descCtrl = TextEditingController(text: activity?['description']);
    final locCtrl = TextEditingController(text: activity?['location']);
    final impactCtrl = TextEditingController(text: activity?['impact']);
    final beneficiariesCtrl = TextEditingController(text: activity?['beneficiaries_count']?.toString() ?? '0');
    
    DateTime? selectedDate = activity?['event_date'] != null
        ? DateTime.parse(activity!['event_date'])
        : DateTime.now();

    int? selectedProjectId = activity?['project'];

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Activity' : 'Add Activity'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Activity Title'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        contentPadding: EdgeInsets.zero,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: locCtrl,
                        decoration: const InputDecoration(labelText: 'Location'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: impactCtrl,
                        decoration: const InputDecoration(labelText: 'Impact Summary'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: beneficiariesCtrl,
                        decoration: const InputDecoration(labelText: 'Beneficiaries Count'),
                        keyboardType: TextInputType.number,
                        validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid number' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedProjectId,
                        decoration: const InputDecoration(labelText: 'Project Category'),
                        items: _projects.map<DropdownMenuItem<int>>((p) {
                          return DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['title'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedProjectId = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    final data = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'location': locCtrl.text.trim(),
                      'impact': impactCtrl.text.trim(),
                      'beneficiaries_count': int.parse(beneficiariesCtrl.text.trim()),
                      'event_date': selectedDate != null
                          ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                          : null,
                      'year': selectedDate?.year ?? DateTime.now().year,
                      'project': selectedProjectId,
                    };

                    setState(() => _isLoading = true);
                    try {
                      if (isEdit) {
                        await _api.updateActivity(activity['id'], data);
                      } else {
                        await _api.createActivity(data);
                      }
                      _load();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Save failed: $e'),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _activities.isEmpty
              ? const Center(child: Text('No activities found', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final a = _activities[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['title'] ?? '',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(a['location'] ?? 'VKS Organisation',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (a['event_date'] != null)
                                    Text('Date: ${a['event_date']}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showFormDialog(activity: a),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () => _delete(a['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
