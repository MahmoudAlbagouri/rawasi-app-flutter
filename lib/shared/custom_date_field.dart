// lib/shared/custom_date_field.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class CustomDateField extends StatefulWidget {
  final String? hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onChanged;
  final bool required;

  /// Latest selectable date. Callers that have a rule stricter than "not in
  /// the future" pass it here so the picker cannot offer an invalid date at
  /// all - a birth date, for instance, must be strictly before today.
  final DateTime? lastDate;

  /// Error shown under the field straight away, rather than waiting for a
  /// form-level validate() on some later screen.
  final String? errorText;

  const CustomDateField({
    super.key,
    this.hint,
    this.selectedDate,
    this.onChanged,
    this.required = false,
    this.lastDate,
    this.errorText,
  });

  @override
  State<CustomDateField> createState() => _CustomDateFieldState();
}

class _CustomDateFieldState extends State<CustomDateField> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    _selectedDate = widget.selectedDate;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final last = widget.lastDate ?? DateTime.now();
    // showDatePicker asserts initialDate <= lastDate, so clamp it: with a
    // lastDate of yesterday, defaulting to "now" would throw.
    final initial = _selectedDate ?? (last.isBefore(DateTime.now()) ? last : DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: last,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.brandPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onChanged?.call(_selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return TextFormField(
      readOnly: true,
      validator: (value) {
        if (widget.required && _selectedDate == null) {
          return 'من فضلك قم باختيار ${widget.hint?.toLowerCase() ?? 'تاريخ'}';
        }
        return null;
      },
      onTap: () => _selectDate(context),
      // Re-validate as soon as a date is chosen, so the message appears on
      // this field rather than after the final submit two screens later.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: TextEditingController(
        text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
      ),
      cursorColor: AppColors.brandPrimary,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'اختر التاريخ',
        filled: true,
        fillColor: Colors.white,

        // ✅ الحدود العادية
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.gray200, width: 1.5),
        ),

        // ✅ عند التركيز (بدون خطأ)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 2.0,
          ),
        ),

        // ✅ عند وجود خطأ (بدون تركيز)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),

        // ✅ عند التركيز مع وجود خطأ
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: errorColor, width: 2.0),
        ),

        errorText: widget.errorText,
        suffixIcon: Icon(Icons.calendar_today, color: AppColors.gray600),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
        // يمكنك إظهار رسالة الخطأ تحت الحقل (موصى به):
        // errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
