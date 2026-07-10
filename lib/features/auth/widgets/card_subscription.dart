import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback? onPressed;

  const SubscriptionCard({super.key, required this.plan, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: plan.isFeatured
            ? Border.all(color: AppColors.brandPrimary, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          if (plan.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: plan.isFeatured
                    ? AppColors.brandPrimary
                    : AppColors.success500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan.badge!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Gap(plan.isFeatured ? 12 : 0),
          ],
          // اسم الخطة
          Text(
            plan.name,
            style: TextStyle(
              color: plan.isFeatured
                  ? AppColors.brandPrimary
                  : AppColors.brandSecondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(4),
          // الوصف
          if (plan.description.isNotEmpty)
            Text(
              plan.description,
              style: TextStyle(color: AppColors.gray600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          Gap(12),
          // السعر
          Column(
            children: [
              if (plan.originalPrice != null &&
                  plan.originalPrice! > plan.price) ...[
                Text(
                  '${plan.originalPrice!.toInt()} ج.م',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Gap(4),
              ],
              Text(
                '${plan.price.toInt()} ج.م',
                style: TextStyle(
                  color: plan.isFeatured
                      ? AppColors.brandPrimary
                      : AppColors.brandSecondary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (plan.originalPrice != null &&
                  plan.originalPrice! > plan.price) ...[
                Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'وفر ${(plan.originalPrice! - plan.price).toInt()} ج.م',
                    style: TextStyle(
                      color: AppColors.success700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Gap(8),
          // المدة
          if (plan.getDurationText().isNotEmpty)
            Text(
              plan.getDurationText(),
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
          Gap(16),
          // المميزات
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature.isIncluded ? Icons.check_circle : Icons.cancel,
                    color: feature.isIncluded
                        ? (plan.isFeatured
                              ? AppColors.brandPrimary
                              : AppColors.success600)
                        : AppColors.gray400,
                    size: 18,
                  ),
                  Gap(8),
                  Text(
                    feature.featureText,
                    style: TextStyle(
                      color: feature.isIncluded
                          ? AppColors.gray800
                          : AppColors.gray400,
                      fontSize: 14,
                      decoration: feature.isIncluded
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Gap(20),
          // زر الاشتراك
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isFeatured
                    ? AppColors.brandPrimary
                    : AppColors.gray800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'اشترك الآن',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
