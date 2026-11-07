import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

/// The incident tracker: one step per status, from Submitted to Resolved.
/// Completed steps are green with a tick; later steps are grey circles.
/// Staff notes appear under the step they were added to.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  static const _done = Color(0xFF34C759);
  static const _todo = Color(0xFF5B6575);

  @override
  Widget build(BuildContext context) {
    const steps = IncidentStatus.values;
    final currentIndex = steps.indexOf(incident.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            status: steps[i],
            isDone: i <= currentIndex,
            isCurrent: i == currentIndex,
            isLast: i == steps.length - 1,
            // The line below this step is green if the next step is done.
            lineIsDone: i < currentIndex,
            updates: incident.history
                .where((u) => u.status == steps[i])
                .toList(),
            // "Submitted" always shows the real submission time, even if
            // staff later moved the report back to Pending.
            fixedTime: i == 0 ? incident.createdAt : null,
            doneColor: _done,
            todoColor: _todo,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.lineIsDone,
    required this.updates,
    required this.fixedTime,
    required this.doneColor,
    required this.todoColor,
  });

  final IncidentStatus status;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final bool lineIsDone;
  final List<StatusUpdate> updates;
  final DateTime? fixedTime;
  final Color doneColor;
  final Color todoColor;

  @override
  Widget build(BuildContext context) {
    // Otherwise use the latest time the report reached this step.
    final time = fixedTime ?? (updates.isNotEmpty ? updates.last.at : null);
    final notes = updates.where((u) => u.hasNote).toList();

    // IntrinsicHeight lets the connecting line stretch to the text height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Dot + line ----
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? doneColor : Colors.transparent,
                    border: Border.all(
                      color: isDone ? doneColor : todoColor,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineIsDone ? doneColor : todoColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ---- Text ----
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.timelineTitle,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isDone
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isDone && time != null)
                        Text(
                          formatDateTime(time),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.timelineSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final update in notes) ...[
                    const SizedBox(height: 8),
                    _NoteBubble(update: update),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A staff note shown under a timeline step.
class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.update});

  final StatusUpdate update;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  update.byName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                timeAgo(update.at),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(update.note!, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
