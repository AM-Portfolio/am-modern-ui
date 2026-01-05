import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact date-time picker with inline input fields
class ModernDateTimePicker extends StatefulWidget {
  const ModernDateTimePicker({required this.onDateTimeChanged, super.key, this.initialDateTime});
  final DateTime? initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  State<ModernDateTimePicker> createState() => _ModernDateTimePickerState();
}

class _ModernDateTimePickerState extends State<ModernDateTimePicker> {
  late final TextEditingController _dayController;
  late final TextEditingController _monthController;
  late final TextEditingController _yearController;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  late final FocusNode _dayFocus;
  late final FocusNode _monthFocus;
  late final FocusNode _yearFocus;
  late final FocusNode _hourFocus;
  late final FocusNode _minuteFocus;

  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _currentDateTime = widget.initialDateTime ?? DateTime.now();

    _dayController = TextEditingController(text: _currentDateTime.day.toString().padLeft(2, '0'));
    _monthController = TextEditingController(text: _currentDateTime.month.toString().padLeft(2, '0'));
    _yearController = TextEditingController(text: _currentDateTime.year.toString());
    _hourController = TextEditingController(text: _currentDateTime.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _currentDateTime.minute.toString().padLeft(2, '0'));

    _dayFocus = FocusNode();
    _monthFocus = FocusNode();
    _yearFocus = FocusNode();
    _hourFocus = FocusNode();
    _minuteFocus = FocusNode();
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _updateDateTime() {
    try {
      final day = int.tryParse(_dayController.text) ?? _currentDateTime.day;
      final month = int.tryParse(_monthController.text) ?? _currentDateTime.month;
      final year = int.tryParse(_yearController.text) ?? _currentDateTime.year;
      final hour = int.tryParse(_hourController.text) ?? _currentDateTime.hour;
      final minute = int.tryParse(_minuteController.text) ?? _currentDateTime.minute;

      final newDateTime = DateTime(year, month, day, hour, minute);
      if (newDateTime != _currentDateTime) {
        setState(() {
          _currentDateTime = newDateTime;
        });
        widget.onDateTimeChanged(newDateTime);
      }
    } catch (e) {
      // Invalid date, ignore
    }
  }

  void _setNow() {
    final now = DateTime.now();
    setState(() {
      _currentDateTime = now;
      _dayController.text = now.day.toString().padLeft(2, '0');
      _monthController.text = now.month.toString().padLeft(2, '0');
      _yearController.text = now.year.toString();
      _hourController.text = now.hour.toString().padLeft(2, '0');
      _minuteController.text = now.minute.toString().padLeft(2, '0');
    });
    widget.onDateTimeChanged(now);
  }

  Future<void> _showCalendarPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_currentDateTime));

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
          _dayController.text = newDateTime.day.toString().padLeft(2, '0');
          _monthController.text = newDateTime.month.toString().padLeft(2, '0');
          _yearController.text = newDateTime.year.toString();
          _hourController.text = newDateTime.hour.toString().padLeft(2, '0');
          _minuteController.text = newDateTime.minute.toString().padLeft(2, '0');
        });
        widget.onDateTimeChanged(newDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _showCalendarPicker,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            _CompactInput(
              controller: _dayController,
              focusNode: _dayFocus,
              nextFocus: _monthFocus,
              width: 28,
              maxLength: 2,
              hintText: 'DD',
              onChanged: (_) => _updateDateTime(),
            ),
            Text('/', style: theme.textTheme.bodyMedium),
            _CompactInput(
              controller: _monthController,
              focusNode: _monthFocus,
              nextFocus: _yearFocus,
              width: 28,
              maxLength: 2,
              hintText: 'MM',
              onChanged: (_) => _updateDateTime(),
            ),
            Text('/', style: theme.textTheme.bodyMedium),
            _CompactInput(
              controller: _yearController,
              focusNode: _yearFocus,
              nextFocus: _hourFocus,
              width: 46,
              maxLength: 4,
              hintText: 'YYYY',
              onChanged: (_) => _updateDateTime(),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            _CompactInput(
              controller: _hourController,
              focusNode: _hourFocus,
              nextFocus: _minuteFocus,
              width: 28,
              maxLength: 2,
              hintText: 'HH',
              onChanged: (_) => _updateDateTime(),
            ),
            Text(':', style: theme.textTheme.bodyMedium),
            _CompactInput(
              controller: _minuteController,
              focusNode: _minuteFocus,
              width: 28,
              maxLength: 2,
              hintText: 'MM',
              onChanged: (_) => _updateDateTime(),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _setNow,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Now',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
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

class _CompactInput extends StatelessWidget {
  const _CompactInput({
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.maxLength,
    required this.hintText,
    this.nextFocus,
    this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final double width;
  final int maxLength;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLength)],
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (value) {
        if (value.length == maxLength && nextFocus != null) {
          nextFocus!.requestFocus();
        }
        onChanged?.call(value);
      },
    ),
  );
}
