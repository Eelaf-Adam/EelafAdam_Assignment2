import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'highlighted_text.dart';
import 'status_chip.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showReporter = false,
    this.highlight = '',
  });

  final Incident incident;
  final VoidCallback onTap;
  final bool showReporter;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    const metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              _Thumbnail(incident: incident),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HighlightedText(
                            incident.title,
                            highlight: highlight,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(timeAgo(incident.createdAt), style: metaStyle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    HighlightedText(
                      incident.description,
                      highlight: highlight,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: HighlightedText(
                            showReporter
                                ? '${incident.code} · ${incident.reporterName}'
                                : incident.code,
                            highlight: highlight,
                            maxLines: 1,
                            style: metaStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: incident.status),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evidence photo with a type badge, or just the type icon if there's no photo.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.incident});

  final Incident incident;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    final url = incident.thumbnailUrl;
    if (url == null) {
      return IncidentTypeIcon(type: incident.type, size: _size);
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  IncidentTypeIcon(type: incident.type, size: _size),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(color: AppColors.accent.withValues(alpha: 0.15)),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Icon(incident.type.icon, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentTypeIcon extends StatelessWidget {
  const IncidentTypeIcon({super.key, required this.type, this.size = 44});

  final IncidentType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(type.icon, color: AppColors.accent, size: size * 0.5),
    );
  }
}
