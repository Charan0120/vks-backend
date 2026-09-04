import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/data/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final admissions = await _api.getAllAdmissions();
      final enquiries = await _api.getAllEnquiries();
      final pending = admissions.where((a) => a['status'] == 'PENDING').length;
      final approved = admissions.where((a) => a['status'] == 'APPROVED').length;
      final newEnq = enquiries.where((e) => e['status'] == 'NEW').length;
      if (mounted) {
        setState(() {
          _stats = {
            'total': admissions.length,
            'pending': pending,
            'approved': approved,
            'enquiries': enquiries.length,
            'new_enquiries': newEnq,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { setState(() => _isLoading = true); _loadStats(); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.firstName ?? 'Admin'}! 👋',
                            style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.role ?? 'Staff',
                            style: const TextStyle(
                              fontSize: 13, color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats grid
                    const Text('Overview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard(
                          'Total Applications',
                          _stats['total'] ?? 0,
                          Icons.description_outlined,
                          AppColors.primary,
                          onTap: () => context.go('/admin/admissions'),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Pending Review',
                          _stats['pending'] ?? 0,
                          Icons.pending_outlined,
                          AppColors.warning,
                          onTap: () => context.go('/admin/admissions?status=PENDING'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard(
                          'Approved',
                          _stats['approved'] ?? 0,
                          Icons.check_circle_outline,
                          AppColors.success,
                          onTap: () => context.go('/admin/admissions?status=APPROVED'),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          'Total Enquiries',
                          _stats['enquiries'] ?? 0,
                          Icons.mail_outline,
                          AppColors.secondary,
                          onTap: () => context.go('/admin/enquiries'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Quick actions
                    const Text('Manage',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _actionTile(
                      icon: Icons.assignment_outlined,
                      title: 'Admission Applications',
                      subtitle: '${_stats['pending'] ?? 0} pending review',
                      color: AppColors.primary,
                      onTap: () => context.go('/admin/admissions'),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Enquiries',
                      subtitle: '${_stats['enquiries'] ?? 0} total · ${_stats['new_enquiries'] ?? 0} unread',
                      color: AppColors.secondary,
                      onTap: () => context.go('/admin/enquiries'),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.people_outline_rounded,
                      title: 'User Roles & Access',
                      subtitle: 'Manage permissions and roles',
                      color: const Color(0xFFE74C3C),
                      onTap: () => context.go('/admin/users'),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.school_outlined,
                      title: 'Manage Courses',
                      subtitle: 'Add, edit, or deactivate courses',
                      color: const Color(0xFF8E44AD),
                      onTap: () => context.go('/admin/courses'),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'Manage Activities',
                      subtitle: 'Add, edit, or delete NGO activities',
                      color: AppColors.success,
                      onTap: () => context.go('/admin/activities'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
              Text('$value',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
