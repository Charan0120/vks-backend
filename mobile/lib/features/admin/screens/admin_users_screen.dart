import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/data/services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _filterRole = 'ALL';
  final _searchCtrl = TextEditingController();

  final _roles = ['ALL', 'ADMIN', 'STAFF', 'STUDENT', 'PUBLIC'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAllUsers(
        role: _filterRole == 'ALL' ? null : _filterRole,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    try {
      await _api.updateUserRole(userId, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User role updated successfully!'),
          backgroundColor: AppColors.success,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = user['role'] ?? 'PUBLIC';
    final currentUserId = context.read<AuthProvider>().user?.id;

    if (user['id'] == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You cannot change your own role.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change role for ${user['first_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['ADMIN', 'STAFF', 'STUDENT', 'PUBLIC'].map((r) {
              return ListTile(
                title: Text(r),
                trailing: currentRole == r ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  _changeRole(user['id'], r);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN': return const Color(0xFFE74C3C);
      case 'STAFF': return AppColors.secondary;
      case 'STUDENT': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () { _searchCtrl.clear(); _load(); },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),

          // Role filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _roles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final r = _roles[i];
                final selected = _filterRole == r;
                return ChoiceChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (_) { setState(() => _filterRole = r); _load(); },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _users.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            final fullName = '${u['first_name']} ${u['last_name']}'.trim();
                            final role = u['role'] ?? 'PUBLIC';
                            return GestureDetector(
                              onTap: () => _showRoleDialog(u),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _roleColor(role).withOpacity(0.1),
                                      child: Text(
                                        (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                                        style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(fullName.isNotEmpty ? fullName : 'No Name',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(u['email'] ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          if (u['phone'] != null && u['phone'].toString().isNotEmpty)
                                            Text(u['phone'],
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _roleColor(role).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor(role)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
