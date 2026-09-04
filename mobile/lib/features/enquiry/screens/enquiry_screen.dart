import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/data/services/api_service.dart';

class EnquiryScreen extends StatefulWidget {
  const EnquiryScreen({super.key});

  @override
  State<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends State<EnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int? _selectedCourseId;
  List<dynamic> _courses = [];
  bool _isLoading = false;
  bool _submitted = false;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCourses();
  }

  void _loadUser() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      _nameCtrl.text = auth.user!.fullName;
      _emailCtrl.text = auth.user!.email;
      _phoneCtrl.text = auth.user!.phone ?? '';
    }
  }

  Future<void> _loadCourses() async {
    final data = await _api.getCourses();
    if (mounted) setState(() => _courses = data);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.submitEnquiry({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'staff_remarks': _messageCtrl.text.trim(),
        if (_selectedCourseId != null) 'interested_course': _selectedCourseId,
      });
      if (mounted) setState(() { _isLoading = false; _submitted = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Enquiry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Enquiry Submitted!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            const Text(
              'Thank you for reaching out. Our team will get back to you soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We\'d love to hear from you!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Fill in the form and our team will contact you within 24 hours.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 28),

            _field('Full Name', _nameCtrl, Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Name required' : null),
            const SizedBox(height: 16),
            _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Phone required' : null),
            const SizedBox(height: 16),
            _field('Email', _emailCtrl, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                }),
            const SizedBox(height: 16),

            // Course dropdown
            const Text('Interested Course (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.school_outlined, color: AppColors.textSecondary, size: 20),
                hintText: 'Select a course',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No specific course')),
                ..._courses.map((c) =>
                    DropdownMenuItem(value: c['id'] as int, child: Text(c['title'] as String))),
              ],
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            const SizedBox(height: 16),

            const Text('Your Message',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Write your message...'),
              validator: (v) => v!.isEmpty ? 'Message required' : null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Enquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
