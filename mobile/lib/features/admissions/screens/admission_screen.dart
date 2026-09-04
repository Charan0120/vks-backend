import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vks_app/core/theme/app_theme.dart';
import 'package:vks_app/data/providers/auth_provider.dart';
import 'package:vks_app/data/services/api_service.dart';

class AdmissionScreen extends StatefulWidget {
  final int? initialCourseId;
  const AdmissionScreen({super.key, this.initialCourseId});

  @override
  State<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends State<AdmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Controllers
  final _studentNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();

  String _gender = 'MALE';
  DateTime? _dob;
  int? _selectedCourseId;
  List<dynamic> _courses = [];
  bool _isLoading = false;
  bool _submitted = false;

  // Document upload variables
  int? _createdAdmissionId;
  Map<String, String> _uploadedDocs = {}; // doc_type -> filename
  String? _uploadingDocType; // Tracks which document type is currently uploading

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCourses();
  }

  void _loadUser() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      _emailCtrl.text = auth.user!.email;
      _mobileCtrl.text = auth.user!.phone ?? '';
    }
  }

  Future<void> _loadCourses() async {
    final data = await _api.getCourses();
    if (mounted) {
      setState(() {
        _courses = data;
        if (widget.initialCourseId != null) {
          _selectedCourseId = widget.initialCourseId;
        }
      });
    }
  }

  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select date of birth'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a course'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _api.submitAdmission({
        'student_name': _studentNameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'mother_name': _motherNameCtrl.text.trim(),
        'gender': _gender,
        'date_of_birth':
            '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
        'mobile_number': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'qualification': _qualificationCtrl.text.trim(),
        'selected_course': _selectedCourseId,
      });
      if (mounted) {
        setState(() {
          _createdAdmissionId = response['id'];
          _isLoading = false;
          _submitted = true;
        });
      }
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
    _studentNameCtrl.dispose(); _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose(); _mobileCtrl.dispose();
    _emailCtrl.dispose(); _addressCtrl.dispose();
    _qualificationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admission Application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Future<void> _pickAndUpload(String docType) async {
    if (_createdAdmissionId == null) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _uploadingDocType = docType);
    try {
      final bytes = await image.readAsBytes();
      await _api.uploadDocument(
        _createdAdmissionId!,
        bytes,
        image.name,
        docType,
      );
      if (mounted) {
        setState(() {
          _uploadedDocs[docType] = image.name;
          _uploadingDocType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Document uploaded successfully!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingDocType = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Widget _buildSuccess() {
    final docTypes = [
      {'type': 'PHOTO', 'label': 'Passport Size Photo'},
      {'type': 'AADHAAR', 'label': 'Aadhaar Card Copy'},
      {'type': 'MARKS_MEMO', 'label': 'Marks Memo / Certificate'},
      {'type': 'TC', 'label': 'Transfer Certificate (TC)'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Application Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          const Text(
            'Your application has been received. Please upload the required documents below to speed up your approval.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 30),

          // Upload list card
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
                const Text('Required Documents',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ...docTypes.map((doc) {
                  final type = doc['type']!;
                  final label = doc['label']!;
                  final isUploaded = _uploadedDocs.containsKey(type);
                  final isCurrentlyUploading = _uploadingDocType == type;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUploaded ? AppColors.success.withOpacity(0.3) : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUploaded ? Icons.check_circle : Icons.upload_file_outlined,
                          color: isUploaded ? AppColors.success : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              if (isUploaded)
                                Text(_uploadedDocs[type]!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCurrentlyUploading)
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else if (!isUploaded)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _pickAndUpload(type),
                            child: const Text('Upload', style: TextStyle(fontSize: 12)),
                          )
                        else
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Finish & Go Home'),
            ),
          ),
        ],
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
            _sectionTitle('Personal Information', Icons.person_outline),
            const SizedBox(height: 14),
            _field('Student Full Name', _studentNameCtrl, Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _field("Father's Name", _fatherNameCtrl, Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _field("Mother's Name", _motherNameCtrl, Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),

            // Gender
            const Text('Gender',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: ['MALE', 'FEMALE', 'OTHER'].map((g) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gender == g ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gender == g ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(g,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _gender == g ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Date of Birth
            const Text('Date of Birth',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dob != null
                          ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                          : 'Select date of birth',
                      style: TextStyle(
                          fontSize: 14,
                          color: _dob != null ? AppColors.textPrimary : AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Contact Details', Icons.contact_phone_outlined),
            const SizedBox(height: 14),
            _field('Mobile Number', _mobileCtrl, Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            _field('Email', _emailCtrl, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                }),
            const SizedBox(height: 14),
            const Text('Address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Full address...'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 24),
            _sectionTitle('Academic Details', Icons.school_outlined),
            const SizedBox(height: 14),
            _field('Last Qualification', _qualificationCtrl, Icons.verified_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),

            // Course
            const Text('Select Course',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.book_outlined, color: AppColors.textSecondary, size: 20),
                hintText: 'Choose a course',
              ),
              items: _courses
                  .map((c) => DropdownMenuItem<int>(
                      value: c['id'] as int, child: Text(c['title'] as String)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
              validator: (v) => v == null ? 'Please select a course' : null,
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After submission, you can upload supporting documents from your application status page.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
