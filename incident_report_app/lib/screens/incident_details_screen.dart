import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/user_role.dart';
import '../providers/incident_providers.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import '../widgets/loading_button.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import 'report_form_screen.dart';

/// Students can edit or delete their own pending reports; staff update the status.
class IncidentDetailsScreen extends ConsumerStatefulWidget {
  const IncidentDetailsScreen({
    super.key,
    required this.incidentId,
    required this.profile,
  });

  final String incidentId;
  final AppUser profile;

  @override
  ConsumerState<IncidentDetailsScreen> createState() =>
      _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends ConsumerState<IncidentDetailsScreen> {
  bool _isBusy = false;

  bool get _isStaff => widget.profile.role == UserRole.staff;

  Future<void> _openStatusSheet(Incident incident) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _StatusUpdateSheet(incident: incident, staff: widget.profile),
    );
  }

  Future<void> _edit(Incident incident) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReportFormScreen(profile: widget.profile, existing: incident),
      ),
    );
  }

  Future<void> _delete(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text(
          '${incident.code} will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(incidentServiceProvider).deleteIncident(incident.id);
      if (!mounted) return;
      showMessage(context, 'Report deleted');
      Navigator.of(context).pop();
    } on OfflineException {
      if (!mounted) return;
      showMessage(
        context,
        'You\'re offline. The report will be deleted when you reconnect.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isBusy = false);
        showMessage(context, 'Could not delete the report. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentProvider(widget.incidentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Incident Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: incidentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load this report',
            message: '$error',
          ),
          data: (incident) => incident == null
              ? const EmptyState(
                  icon: Icons.delete_outline,
                  title: 'Report not found',
                  message: 'It may have been deleted.',
                )
              : _buildDetails(incident),
        ),
      ),
    );
  }

  Widget _buildDetails(Incident incident) {
    final isOwner = incident.reporterId == widget.profile.uid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CASE FILE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    incident.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Divider(
                height: 24,
                color: AppColors.textSecondary.withValues(alpha: 0.15),
              ),
              Row(
                children: [
                  IncidentTypeIcon(type: incident.type, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      incident.typeLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StatusChip(status: incident.status),
                ],
              ),
              const SizedBox(height: 14),
              _MetaRow(
                icon: Icons.location_on_outlined,
                text: incident.locationLabel,
              ),
              _MetaRow(
                icon: Icons.person_outline,
                text: 'Reported by ${incident.reporterName}',
              ),
              _MetaRow(
                icon: Icons.calendar_today_outlined,
                text:
                    'Submitted ${formatDateTime(incident.createdAt)} '
                    '(${timeAgo(incident.createdAt)})',
              ),
              if (incident.updatedAt != null)
                _MetaRow(
                  icon: Icons.update,
                  text: 'Last updated ${timeAgo(incident.updatedAt!)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const _SectionTitle('Description'),
        _Card(
          padding: const EdgeInsets.all(16),
          child: Text(
            incident.description,
            style: const TextStyle(height: 1.5),
          ),
        ),

        if (incident.photoUrl != null) ...[
          const SizedBox(height: 22),
          const _SectionTitle('Evidence'),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              incident.photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, _, _) => const SizedBox(
                height: 120,
                child: Center(child: Text('Could not load photo')),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),

        const _SectionTitle('Incident Tracker'),
        _Card(
          padding: const EdgeInsets.all(16),
          child: StatusTimeline(incident: incident),
        ),
        const SizedBox(height: 28),

        if (_isStaff)
          ElevatedButton.icon(
            onPressed: () => _openStatusSheet(incident),
            icon: const Icon(Icons.edit_note),
            label: const Text('Update status'),
          ),
        if (!_isStaff && isOwner) _buildStudentActions(incident),
      ],
    );
  }

  Widget _buildStudentActions(Incident incident) {
    if (!incident.isEditable) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Staff are handling this report, so it can no longer '
                'be edited or deleted.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _delete(incident),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : () => _edit(incident),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ),
      ],
    );
  }
}

/// The optional note is shown to the student on the timeline.
class _StatusUpdateSheet extends ConsumerStatefulWidget {
  const _StatusUpdateSheet({required this.incident, required this.staff});

  final Incident incident;
  final AppUser staff;

  @override
  ConsumerState<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends ConsumerState<_StatusUpdateSheet> {
  late IncidentStatus _status = widget.incident.status;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _hasChange =>
      _status != widget.incident.status ||
      _noteController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(incidentServiceProvider)
          .updateStatus(
            widget.incident.id,
            status: _status,
            staff: widget.staff,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, 'Update submitted: ${_status.label}');
    } on OfflineException {
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(
        context,
        'You\'re offline. The update will sync when you reconnect.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        showMessage(context, 'Could not submit the update. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update ${widget.incident.code}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the new status. Your note will be shown to the student.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (var row = 0; row < IncidentStatus.values.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 10),
                  Expanded(
                    child: _StatusOption(
                      status: IncidentStatus.values[i],
                      isSelected: _status == IncidentStatus.values[i],
                      onTap: () =>
                          setState(() => _status = IncidentStatus.values[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Add a note for the student (optional)\n'
                  'e.g. Plumber assigned, coming tomorrow morning',
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 20),
          LoadingButton(
            label: 'Submit update',
            isLoading: _isSaving,
            onPressed: _hasChange ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? status.color.withValues(alpha: 0.18)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? status.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              status.icon,
              size: 20,
              color: isSelected ? status.color : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? status.color : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
