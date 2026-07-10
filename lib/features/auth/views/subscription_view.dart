import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_repo.dart';
import 'package:rawasi_app_n/features/auth/views/upload_certificate_view.dart';
import 'package:rawasi_app_n/features/auth/widgets/card_subscription.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
// ... (جميع الاستيرادات كما هي)

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late Future<StudentProfile?> _profileFuture;
  late Future<List<SubscriptionPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _plansFuture = SubscriptionRepo().fetchPlans();
  }

  Future<StudentProfile?> _loadProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) return null;
    try {
      return await ProfileRepository().fetchProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الاشتراك',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<StudentProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = snapshot.data;

            if (profile == null) {
              return const Center(
                child: CustomText(
                  text: 'يرجى تسجيل الدخول أولًا',
                  color: AppColors.gray700,
                  size: 16,
                ),
              );
            }

            // الحالة 1: لم يرفع إيصال الدفع بعد → نعرض الباقات
            if (!profile.isUploadPaidCertificate) {
              return _buildSubscriptionPlans();
            }

            // الحالة 2: رفع الإيصال لكن غير مفعل
            if (profile.isUploadPaidCertificate && !profile.isActive) {
              return _buildPendingReviewScreen();
            }

            // الحالة 3: مفعل بالكامل
            if (profile.isUploadPaidCertificate && profile.isActive) {
              return _buildSuccessScreen();
            }

            return _buildSubscriptionPlans();
          },
        ),
      ),
    );
  }

  // 👇 عرض الباقات من الـ API
  Widget _buildSubscriptionPlans() {
    return FutureBuilder<List<SubscriptionPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: AppColors.error500, size: 60),
                const SizedBox(height: 16),
                CustomText(
                  text: 'فشل تحميل الباقات',
                  color: AppColors.gray900,
                  size: 18,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                CustomText(
                  text: '${snapshot.error}',
                  color: AppColors.gray700,
                  size: 14,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _plansFuture = SubscriptionRepo().fetchPlans();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final plans = snapshot.data ?? [];
        if (plans.isEmpty) {
          return Center(
            child: CustomText(
              text: 'لا توجد باقات متاحة حاليًا',
              color: AppColors.gray700,
              size: 16,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Text(
                'رواسي',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'نظام تعليمي متكامل يساعدك على التعلم بذكاء',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray600, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: plans.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return SubscriptionCard(
                      plan: plan,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadCertificateView(
                              planId: plan.id,
                              planName: plan.name,
                              planPrice: plan.price,
                              hasDiscount:
                                  plan.hasDiscount, // 👈 التغيير الوحيد هنا
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingReviewScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: AppColors.warning600),
            const SizedBox(height: 24),
            CustomText(
              text: 'قيد المراجعة',
              color: AppColors.gray900,
              size: 22,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            CustomText(
              text:
                  'تم استلام طلبك بنجاح. نحن نراجع إثبات الدفع وسنتواصل معك قريبًا.',
              color: AppColors.gray700,
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: AppColors.success600),
            const SizedBox(height: 24),
            CustomText(
              text: 'تم الاشتراك بنجاح!',
              color: AppColors.gray900,
              size: 22,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            CustomText(
              text: 'حسابك مفعل الآن ويمكنك الاستفادة من جميع مزايا البرنامج.',
              color: AppColors.gray700,
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
