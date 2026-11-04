// Tiny date/time formatting helpers (no intl dependency).

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String formatTime(DateTime d) {
  final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String formatDateTime(DateTime d) => '${formatDate(d)} · ${formatTime(d)}';
