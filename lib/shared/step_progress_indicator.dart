import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class EnhancedLinearProgress
    extends StatelessWidget {
  final double
  progress; // من 0.0 إلى 1.0

  const EnhancedLinearProgress({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الخلفية "المتقطعة" (4 أقسام)
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth;
            final segmentWidth =
                width / 4;

            return Row(
              children: List.generate(4, (
                index,
              ) {
                return Container(
                  width: segmentWidth,
                  height: 8,
                  margin:
                      EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                  decoration: BoxDecoration(
                    color: AppColors
                        .primary100,
                    borderRadius:
                        index == 0
                        ? const BorderRadius.only(
                            topLeft:
                                Radius.circular(
                                  4,
                                ),
                            bottomLeft:
                                Radius.circular(
                                  4,
                                ),
                          )
                        : index == 3
                        ? const BorderRadius.only(
                            topRight:
                                Radius.circular(
                                  4,
                                ),
                            bottomRight:
                                Radius.circular(
                                  4,
                                ),
                          )
                        : null,
                  ),
                );
              }),
            );
          },
        ),
        // شريط التقدم الفعلي
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(
                  4,
                ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors
                  .transparent, // نخفي الخلفية الافتراضية
              color: AppColors
                  .brandPrimary,
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}
