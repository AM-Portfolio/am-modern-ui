import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A premium, user-friendly date-time picker
class ModernDateTimePicker extends StatefulWidget {
  const ModernDateTimePicker({required this.onDateTimeChanged, super.key, this.initialDateTime});
  final DateTime? initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<ModernDateTimePicker> createState() => _ModernDateTimePickerState();
}

class _ModernDateTimePickerState extends State<ModernDateTimePicker> {
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _currentDateTime = widget.initialDateTime ?? DateTime.now();
  }

  void _setNow() {
    final now = DateTime.now();
    setState(() {
      _currentDateTime = now;
    });
    widget.onDateTimeChanged(now);
  }

  Future<void> _showCalendarPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_currentDateTime),
      );

      if (pickedTime != null && mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _currentDateTime = newDateTime;
        });
        widget.onDateTimeChanged(newDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM dd, yyyy').format(_currentDateTime);
    final formattedTime = DateFormat('HH:mm').format(_currentDateTime);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date & Time clickable area
          InkWell(
            onTap: _showCalendarPicker,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          
          // Now Button
          InkWell(
            onTap: _setNow,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Now',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
