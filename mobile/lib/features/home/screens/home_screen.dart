import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/core/constants/app_constants.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/data/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _activities = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final activitiesData = await _api.getActivities(page: 1);
      final coursesData = await _api.getCourses();
      if (mounted) {
        setState(() {
          _activities = (activitiesData['results'] as List?) ?? [];
          _courses = coursesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                ),
                                child: const Center(
                                  child: Text('VKS',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(kAppName,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (auth.isLoggedIn)
                                PopupMenuButton(
                                  icon: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.person, color: Colors.white, size: 20),
                                  ),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      child: const Text('Sign Out'),
                                      onTap: () async {
                                        await auth.logout();
                                        if (context.mounted) context.go('/login');
                                      },
                                    ),
                                  ],
                                )
                              else
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text('Sign In',
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            auth.isLoggedIn
                                ? 'Hello, ${auth.user?.firstName ?? 'User'} 👋'
                                : 'Welcome to VKS Sharanya',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            kAppTagline,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              // Admin Banner (visible to staff/admin only)
              if (auth.isStaff)
                SliverToBoxAdapter(child: _buildAdminBanner(context)),

              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions(context, auth)),

              // Stats Banner
              SliverToBoxAdapter(child: _buildStatsBanner()),

              // Recent Activities
              SliverToBoxAdapter(child: _buildSectionHeader('Recent Activities', '/activities')),
              SliverToBoxAdapter(child: _buildActivitiesRow()),

              // Courses
              SliverToBoxAdapter(child: _buildSectionHeader('Our Courses', '/courses')),
              SliverToBoxAdapter(child: _buildCoursesList()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider auth) {
    final actions = [
      _QuickAction('Activities', Icons.calendar_month_outlined, AppColors.secondary, '/activities'),
      _QuickAction('Courses', Icons.school_outlined, const Color(0xFF8E44AD), '/courses'),
      _QuickAction('Gallery', Icons.photo_library_outlined, AppColors.info, '/gallery'),
      _QuickAction(
        'Apply Now',
        Icons.assignment_outlined,
        AppColors.success,
        auth.isLoggedIn ? '/admissions' : '/login',
      ),
      if (auth.isStaff)
        _QuickAction('Admin', Icons.admin_panel_settings_outlined, const Color(0xFFE74C3C), '/admin')
      else
        _QuickAction(
          'Enquiry',
          Icons.chat_bubble_outline_rounded,
          AppColors.warning,
          auth.isLoggedIn ? '/enquiry' : '/login',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions
                .map((a) => GestureDetector(
                      onTap: () => context.go(a.route),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: a.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(a.icon, color: a.color, size: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(a.label,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/admin'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFE74C3C), size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Panel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE74C3C))),
                  Text('Manage admissions & enquiries', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('15+', 'Years'),
          _buildStatDivider(),
          _buildStat('50K+', 'Beneficiaries'),
          _buildStatDivider(),
          _buildStat('9', 'States'),
          _buildStatDivider(),
          _buildStat('100+', 'Partners'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStatDivider() => Container(
        height: 30, width: 1, color: Colors.white24);

  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          TextButton(
            onPressed: () => context.go(route),
            child: const Text('View All',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesRow() {
    if (_activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No activities yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activities.length > 5 ? 5 : _activities.length,
        itemBuilder: (_, i) {
          final a = _activities[i];
          return GestureDetector(
            onTap: () => context.go('/activities/${a['id']}'),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${a['year']}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          a['location'] ?? 'India',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCourseDetails(BuildContext context, Map<String, dynamic> course, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final color = AppColors.secondary;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['code'] ?? '',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${course['duration_months']} months', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                course['title'] ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              const Text(
                'About this Course',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                course['description'] ?? 'No description available.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (auth.isLoggedIn) {
                      context.go('/admissions?courseId=${course['id']}');
                    } else {
                      context.go('/login');
                    }
                  },
                  child: const Text('Apply for this Course'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoursesList() {
    if (_courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No courses available.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    final auth = context.read<AuthProvider>();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _courses.length > 4 ? 4 : _courses.length,
      itemBuilder: (_, i) {
        final c = _courses[i];
        return GestureDetector(
          onTap: () => _showCourseDetails(context, c, auth),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined,
                      color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text('${c['duration_months']} months • ${c['code']}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textLight),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
