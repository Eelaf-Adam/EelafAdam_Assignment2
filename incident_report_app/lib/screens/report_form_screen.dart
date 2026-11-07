import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../providers/incident_providers.dart';
import '../services/cloudinary_service.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/dashed_border_box.dart';
import '../widgets/loading_button.dart';

/// Pass [existing] to edit. Pops with true once saved.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, required this.profile, this.existing});

  final AppUser profile;
  final Incident? existing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _otherTypeController;
  late final TextEditingController _otherLocationController;

  IncidentType? _type;
  CampusLocation? _location;
  bool _isSaving = false;

  /// Only uploaded when the form is submitted.
  File? _newPhoto;

  String? _existingPhotoUrl;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type;
    _location = existing?.location;
    _existingPhotoUrl = existing?.photoUrl;
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _otherTypeController = TextEditingController(
      text: existing?.otherType ?? '',
    );
    _otherLocationController = TextEditingController(
      text: existing?.otherLocation ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _otherTypeController.dispose();
    _otherLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.accent,
                ),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.accent,
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      // Smaller files upload faster on mobile data.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        setState(() => _newPhoto = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not open the camera or gallery.');
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _newPhoto = null;
      _existingPhotoUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final service = ref.read(incidentServiceProvider);

    try {
      var photoUrl = _existingPhotoUrl;
      if (_newPhoto != null) {
        photoUrl = await ref
            .read(cloudinaryServiceProvider)
            .uploadImage(_newPhoto!);
      }

      if (_isEditing) {
        await service.updateIncident(
          widget.existing!.id,
          type: _type!,
          otherType: _otherTypeController.text,
          description: _descriptionController.text,
          location: _location!,
          otherLocation: _otherLocationController.text,
          photoUrl: photoUrl,
        );
        if (!mounted) return;
        showMessage(context, 'Report updated');
        Navigator.of(context).pop(true);
      } else {
        final code = await service.createIncident(
          reporter: widget.profile,
          type: _type!,
          otherType: _otherTypeController.text,
          description: _descriptionController.text,
          location: _location!,
          otherLocation: _otherLocationController.text,
          photoUrl: photoUrl,
        );
        if (!mounted) return;
        await _showSubmittedDialog(code);
        if (mounted) Navigator.of(context).pop(true);
      }
    } on OfflineException catch (e) {
      if (!mounted) return;
      if (e.code != null) {
        await _showSubmittedDialog(e.code!, offline: true);
      } else {
        showMessage(
          context,
          'You\'re offline. Changes will sync when you reconnect.',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CloudinaryException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not save the report. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showSubmittedDialog(String code, {bool offline = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          offline ? Icons.cloud_off : Icons.check_circle,
          color: offline
              ? IncidentStatus.pending.color
              : const Color(0xFF34C759),
          size: 56,
        ),
        title: Text(
          offline ? 'Saved offline' : 'Report submitted',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your Incident ID is',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              offline
                  ? 'You\'re offline. The report will be sent automatically '
                        'when you reconnect.'
                  : 'Use it to track the progress of your report.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Report' : 'Report an Incident',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Incident Type'),
                DropdownButtonFormField<IncidentType>(
                  initialValue: _type,
                  hint: const Text('Select incident type'),
                  dropdownColor: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  items: [
                    for (final type in IncidentType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, color: AppColors.accent, size: 20),
                            const SizedBox(width: 12),
                            Text(type.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                  validator: (value) =>
                      value == null ? 'Please choose an incident type' : null,
                ),
                if (_type == IncidentType.others) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _otherTypeController,
                    label: 'What kind of incident?',
                    icon: Icons.edit_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please describe the incident type'
                        : null,
                  ),
                ],
                const SizedBox(height: 22),

                const _FieldLabel('Incident Description'),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe what happened, where exactly, '
                        'and any safety concerns...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please describe the incident';
                    }
                    if (v.trim().length < 10) {
                      return 'Please add a bit more detail (10+ characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                const _FieldLabel('Location'),
                DropdownButtonFormField<CampusLocation>(
                  initialValue: _location,
                  hint: const Text('Select location'),
                  dropdownColor: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  items: [
                    for (final location in CampusLocation.values)
                      DropdownMenuItem(
                        value: location,
                        child: Text(location.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _location = value),
                  validator: (value) =>
                      value == null ? 'Please choose a location' : null,
                ),
                if (_location == CampusLocation.others) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _otherLocationController,
                    label: 'Specify the location',
                    hint: 'e.g. Library, 2nd floor',
                    icon: Icons.edit_location_alt_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please specify the location'
                        : null,
                  ),
                ],
                const SizedBox(height: 22),

                const _FieldLabel('Attach Evidence (optional)'),
                if (_newPhoto != null || _existingPhotoUrl != null)
                  _PhotoPreview(
                    image: _newPhoto != null
                        ? Image.file(_newPhoto!, fit: BoxFit.cover)
                        : Image.network(_existingPhotoUrl!, fit: BoxFit.cover),
                    onChange: _isSaving ? null : _pickPhoto,
                    onRemove: _isSaving ? null : _removePhoto,
                  )
                else
                  DashedBorderBox(
                    onTap: _pickPhoto,
                    child: const SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.accent,
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload Photo or Take Photo',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                LoadingButton(
                  label: _isEditing ? 'Save Changes' : 'Submit Report',
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'You will receive an Incident ID to track progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.image,
    required this.onChange,
    required this.onRemove,
  });

  final Image image;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              top: 8,
              right: 8,
              child: _CircleButton(icon: Icons.close, onTap: onRemove),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: TextButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
