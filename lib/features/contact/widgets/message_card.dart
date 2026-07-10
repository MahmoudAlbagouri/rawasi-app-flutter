// lib/features/contact/widgets/message_card.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/contact/data/contact_message.dart';

class MessageCard extends StatelessWidget {
  final ContactMessage message;
  final Animation<double>? animation;

  const MessageCard({super.key, required this.message, this.animation});

  // تحويل التاريخ إلى نص عربي جميل
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
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '$day $month $year - $hour:$minute $period';
  }

  void _showMessageDetails(BuildContext context, ContactMessage msg) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Text(
                'تفاصيل الرسالة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const Gap(16),

              // السؤال
              Text(
                'السؤال:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary,
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg.message,
                  style: TextStyle(fontSize: 15, color: AppColors.gray800),
                  textAlign: TextAlign.right,
                ),
              ),
              const Gap(16),

              // الرد (إن وُجد)
              if (msg.reply != null && msg.reply!.isNotEmpty) ...[
                Text(
                  'الرد:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success700,
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg.reply!,
                    style: TextStyle(fontSize: 15, color: AppColors.success800),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Gap(16),
              ],

              // التاريخ
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const Gap(6),
                  Text(
                    _formatDate(msg.createdAt),
                    style: TextStyle(color: AppColors.gray600, fontSize: 13),
                  ),
                ],
              ),

              const Gap(20),

              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onTap: () => _showMessageDetails(context, message),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.question_mark,
                size: 16,
                color: AppColors.brandPrimary,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(6),
                  Text(
                    '${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}',
                    style: TextStyle(color: AppColors.gray500, fontSize: 12),
                  ),
                ],
              ),
            ),
            // أيقونة مؤشر أن الرسالة قابلة للفتح
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gray400),
          ],
        ),
      ),
    );

    if (animation != null) {
      return FadeTransition(
        opacity: animation!,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(animation!),
          child: content,
        ),
      );
    }

    return content;
  }
}
