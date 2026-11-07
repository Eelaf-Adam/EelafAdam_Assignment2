const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "7 Nov 2026"
String formatDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// e.g. "5 min ago", "2h ago", "Yesterday"; the date after a week.
String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDate(date);
}

/// e.g. "7 Nov 2026, 14:05"
String formatDateTime(DateTime date) {
  final d = date.toLocal();
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)}, $hour:$minute';
}
