// lib/features/contact/widgets/send_message_form.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class SendMessageForm extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;

  const SendMessageForm({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  State<SendMessageForm> createState() => _SendMessageFormState();
}

class _SendMessageFormState extends State<SendMessageForm> {
  bool _isSending = false;
  bool _isNotEmpty = false;

  @override
  void initState() {
    super.initState();
    // تحقق من القيمة الحالية
    _isNotEmpty = widget.controller.text.trim().isNotEmpty;
    // استمع لتغييرات الحقل
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final isEmpty = widget.controller.text.trim().isEmpty;
    if (_isNotEmpty != !isEmpty) {
      setState(() {
        _isNotEmpty = !isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _isNotEmpty && !_isSending;

    return Column(
      children: [
        CustomText(
          text: 'آشرح وفسّر ما تريد إخباره لنا',
          color: AppColors.gray600,
          size: 14,
        ),
        const Gap(8),
        SizedBox(
          height: 120,
          child: TextField(
            controller: widget.controller,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'الشرح',
              hintStyle: TextStyle(color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.white,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.brandPrimary,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isEnabled
                ? () async {
                    setState(() {
                      _isSending = true;
                    });
                    await widget.onSend();
                    if (mounted) {
                      setState(() {
                        _isSending = false;
                      });
                    }
                  }
                : null,
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, size: 16),
            label: _isSending
                ? const Text('جاري الإرسال...')
                : const Text('آرسل الان'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? AppColors.brandPrimary
                  : AppColors.gray300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: isEnabled ? 2 : 0,
              shadowColor: AppColors.brandPrimary.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }
}
