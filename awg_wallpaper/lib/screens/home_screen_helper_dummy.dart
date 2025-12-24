String _getFormattedDate() {
  final now = DateTime.now();
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return '${now.day} ${months[now.month - 1]}';
}
