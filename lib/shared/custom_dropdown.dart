// lib/shared/custom_dropdown.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) itemAsString;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool required;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.itemAsString,
    this.value,
    this.onChanged,
    this.hint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    // لون الخطأ (يمكنك تغييره حسب تصميمك)
    final errorColor = Theme.of(context).colorScheme.error;

    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      validator: (value) {
        if (required && (value == null)) {
          return 'من فضلك قم باختيار ${hint?.toLowerCase() ?? 'قيمة'}';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
        alignLabelWithHint: true,
        // لإخفاء المساحة الزائدة للرسالة (إذا أردت إظهارها، احذف هذه السطر)
        // errorStyle: const TextStyle(height: 0),
      ),
      items: items.map<DropdownMenuItem<T>>((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemAsString(item),
            style: const TextStyle(fontSize: 16, color: AppColors.gray800),
          ),
        );
      }).toList(),
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: AppColors.gray600),
      dropdownColor: Colors.white,
      // elevation: 4,
    );
  }
}
