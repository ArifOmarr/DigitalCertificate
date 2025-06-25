import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(selectedDate == null
          ? label
          : '$label: ${DateFormat.yMMMd().format(selectedDate!)}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}
