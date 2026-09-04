import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/services/api_service.dart';

class AdminAdmissionDetailScreen extends StatefulWidget {
  final int admissionId;
  const AdminAdmissionDetailScreen({super.key, required this.admissionId});

  @override
  State<AdminAdmissionDetailScreen> createState() => _AdminAdmissionDetailScreenState();
}

class _AdminAdmissionDetailScreenState extends State<AdminAdmissionDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _admission;
  bool _isLoading = true;
  bool _isUpdating = false;
  final _remarksCtrl = TextEditingController();
  String _selectedStatus = 'PENDING';

  final _statuses = ['PENDING', 'APPROVED', 'REJECTED', 'ENROLLED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getAdmissionDetail(widget.admissionId);
      if (mounted) {
        setState(() {
          _admission = data;
          _selectedStatus = data['status'] ?? 'PENDING';
          _remarksCtrl.text = data['admin_remarks'] ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _update() async {
    setState(() => _isUpdating = true);
    try {
      await _api.updateAdmissionStatus(widget.admissionId, _selectedStatus, _remarksCtrl.text.trim());
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Status updated successfully!'),
          backgroundColor: AppColors.success,
        ));
        context.go('/admin/admissions');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'APPROVED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      case 'ENROLLED': return AppColors.secondary;
      default: return AppColors.warning;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/admissions'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _admission == null
              ? const Center(child: Text('Not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student info card
                      _sectionCard('Student Details', [
                        _infoRow('Name', _admission!['student_name'] ?? ''),
                        _infoRow('Father', _admission!['father_name'] ?? ''),
                        _infoRow('Mother', _admission!['mother_name'] ?? ''),
                        _infoRow('Gender', _admission!['gender'] ?? ''),
                        _infoRow('DOB', _admission!['date_of_birth'] ?? ''),
                        _infoRow('Mobile', _admission!['mobile_number'] ?? ''),
                        _infoRow('Email', _admission!['email'] ?? ''),
                        _infoRow('Qualification', _admission!['qualification'] ?? ''),
                        _infoRow('Address', _admission!['address'] ?? ''),
                      ]),
                      const SizedBox(height: 14),

                      // Course info
                      _sectionCard('Course Applied', [
                        _infoRow('Course',
                            (_admission!['selected_course_detail'] != null)
                                ? _admission!['selected_course_detail']['title']
                                : 'N/A'),
                        _infoRow('Applied On',
                            _admission!['created_at'] != null
                                ? DateFormat('dd MMM yyyy').format(DateTime.parse(_admission!['created_at']))
                                : ''),
                      ]),
                      const SizedBox(height: 14),

                      // Documents
                      if ((_admission!['documents'] as List?)?.isNotEmpty == true) ...[
                        _sectionCard('Uploaded Documents',
                          (_admission!['documents'] as List).map<Widget>((doc) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${doc['document_type']} — ${doc['original_filename']}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Update status card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Update Status',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: _statuses.map((s) {
                                final selected = _selectedStatus == s;
                                return ChoiceChip(
                                  label: Text(s),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _selectedStatus = s),
                                  selectedColor: _statusColor(s),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: selected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _remarksCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Admin Remarks (optional)',
                                hintText: 'Add a note for the student...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUpdating ? null : _update,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _statusColor(_selectedStatus),
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        height: 20, width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('Set as $_selectedStatus',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}
