import 'package:careconnect_mobile/core/network/api_exception.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/features/admin/data/admin_repository.dart';
import 'package:careconnect_mobile/features/admin/domain/admin_dashboard.dart';
import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';
import 'package:flutter/material.dart';

class AdminDoctorFormScreen extends StatefulWidget {
  const AdminDoctorFormScreen({
    required this.repository,
    required this.users,
    required this.clinics,
    required this.specialties,
    this.doctor,
    super.key,
  });

  final AdminDataSource repository;
  final List<AdminUser> users;
  final List<AdminClinic> clinics;
  final List<CareSpecialty> specialties;
  final AdminDoctor? doctor;

  @override
  State<AdminDoctorFormScreen> createState() => _AdminDoctorFormScreenState();
}

class _AdminDoctorFormScreenState extends State<AdminDoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  String? _userId;
  late bool _verified;
  late Set<String> _specialtyIds;
  late Set<String> _clinicIds;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    final doctor = widget.doctor;
    _userId = doctor?.userId;
    _licenseController = TextEditingController(text: doctor?.licenseNumber);
    _experienceController = TextEditingController(
      text: doctor?.yearsOfExperience?.toString() ?? '',
    );
    _bioController = TextEditingController(text: doctor?.bio);
    _verified = doctor?.isVerified ?? false;
    _specialtyIds = doctor?.specialties.map((item) => item.id).toSet() ?? {};
    _clinicIds = doctor?.clinics.map((item) => item.id).toSet() ?? {};
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final experience = _experienceController.text.trim().isEmpty
          ? null
          : int.parse(_experienceController.text.trim());
      if (_editing) {
        await widget.repository.updateDoctor(
          id: widget.doctor!.id,
          bio: _bioController.text,
          yearsOfExperience: experience,
          isVerified: _verified,
        );
      } else {
        await widget.repository.createDoctor(
          userId: _userId!,
          licenseNumber: _licenseController.text,
          bio: _bioController.text,
          yearsOfExperience: experience,
          isVerified: _verified,
          specialtyIds: _specialtyIds.toList(growable: false),
          clinicIds: _clinicIds.toList(growable: false),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The doctor profile could not be saved.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit doctor' : 'Add doctor')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                _editing
                    ? widget.doctor!.displayName
                    : 'Create a professional profile',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                _editing
                    ? 'Update professional information and verification.'
                    : 'Select an existing CareConnect user. The backend will assign the DOCTOR role.',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              if (!_editing) ...[
                DropdownButtonFormField<String>(
                  key: const Key('admin-doctor-user'),
                  initialValue: _userId,
                  decoration: _decoration('CareConnect user'),
                  items: widget.users
                      .map(
                        (user) => DropdownMenuItem(
                          value: user.id,
                          child: Text(user.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _userId = value),
                  validator: (value) => value == null ? 'Select a user' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('admin-doctor-license'),
                  controller: _licenseController,
                  decoration: _decoration('License number (optional)'),
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                key: const Key('admin-doctor-experience'),
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Years of experience'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0 || number > 80) {
                    return 'Enter a value between 0 and 80';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('admin-doctor-bio'),
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: _decoration('Professional biography'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                key: const Key('admin-doctor-verified'),
                value: _verified,
                onChanged: (value) => setState(() => _verified = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Verified professional'),
                subtitle: const Text(
                  'Only verify after credentials have been reviewed.',
                ),
              ),
              if (!_editing) ...[
                const SizedBox(height: 16),
                _ChoiceSection(
                  title: 'Specialties',
                  emptyLabel: 'No specialties configured',
                  items: widget.specialties
                      .map((item) => MapEntry(item.id, item.name))
                      .toList(),
                  selected: _specialtyIds,
                  onChanged: (value) => setState(() => _specialtyIds = value),
                ),
                const SizedBox(height: 20),
                _ChoiceSection(
                  title: 'Clinics',
                  emptyLabel: 'No clinics configured',
                  items: widget.clinics
                      .map((item) => MapEntry(item.id, item.name))
                      .toList(),
                  selected: _clinicIds,
                  onChanged: (value) => setState(() => _clinicIds = value),
                ),
              ] else ...[
                const SizedBox(height: 14),
                const Text(
                  'Clinic and specialty assignments are managed separately by the backend.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('admin-save-doctor'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminClinicFormScreen extends StatefulWidget {
  const AdminClinicFormScreen({
    required this.repository,
    this.clinic,
    super.key,
  });

  final AdminDataSource repository;
  final AdminClinic? clinic;

  @override
  State<AdminClinicFormScreen> createState() => _AdminClinicFormScreenState();
}

class _AdminClinicFormScreenState extends State<AdminClinicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _telephone;
  late final TextEditingController _email;
  late bool _active;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.clinic != null;

  @override
  void initState() {
    super.initState();
    final clinic = widget.clinic;
    _name = TextEditingController(text: clinic?.name);
    _description = TextEditingController(text: clinic?.description);
    _address = TextEditingController(text: clinic?.addressLine1);
    _city = TextEditingController(text: clinic?.city);
    _country = TextEditingController(text: clinic?.country ?? 'Sri Lanka');
    _telephone = TextEditingController(text: clinic?.telephone);
    _email = TextEditingController(text: clinic?.email);
    _active = clinic?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _telephone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final previous = widget.clinic;
    final clinic = AdminClinic(
      id: previous?.id ?? '',
      name: _name.text.trim(),
      description: _optional(_description.text),
      addressLine1: _address.text.trim(),
      addressLine2: previous?.addressLine2,
      city: _city.text.trim(),
      district: previous?.district,
      province: previous?.province,
      postalCode: previous?.postalCode,
      country: _country.text.trim(),
      telephone: _optional(_telephone.text),
      email: _optional(_email.text),
      status: _active ? 'ACTIVE' : 'INACTIVE',
    );
    try {
      if (_editing) {
        await widget.repository.updateClinic(clinic);
      } else {
        await widget.repository.createClinic(clinic);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The clinic could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit clinic' : 'Add clinic')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                _editing ? widget.clinic!.name : 'Add a care location',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 22),
              _requiredField(
                'Clinic name',
                _name,
                const Key('admin-clinic-name'),
              ),
              const SizedBox(height: 14),
              _requiredField(
                'Address line 1',
                _address,
                const Key('admin-clinic-address'),
              ),
              const SizedBox(height: 14),
              _requiredField('City', _city, const Key('admin-clinic-city')),
              const SizedBox(height: 14),
              _requiredField(
                'Country',
                _country,
                const Key('admin-clinic-country'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Telephone (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email (optional)'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isNotEmpty && !text.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: _decoration('Description (optional)'),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Active clinic'),
                subtitle: const Text(
                  'Inactive clinics are hidden from public discovery.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('admin-save-clinic'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save clinic'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requiredField(
    String label,
    TextEditingController controller,
    Key key,
  ) {
    return TextFormField(
      key: key,
      controller: controller,
      decoration: _decoration(label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String emptyLabel;
  final List<MapEntry<String, String>> items;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(emptyLabel, style: const TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) {
                  return FilterChip(
                    label: Text(item.value),
                    selected: selected.contains(item.key),
                    onSelected: (enabled) {
                      final updated = {...selected};
                      enabled
                          ? updated.add(item.key)
                          : updated.remove(item.key);
                      onChanged(updated);
                    },
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);
