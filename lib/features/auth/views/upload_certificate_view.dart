import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_repo.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

enum UploadState { idle, uploading, success, error }

class UploadCertificateView extends StatefulWidget {
  final int planId;
  final String planName;
  final double planPrice;
  final bool hasDiscount; // 👈 إضافة الخاصية الجديدة

  const UploadCertificateView({
    super.key,
    required this.planId,
    required this.planName,
    required this.planPrice,
    required this.hasDiscount, // 👈 تمرير الخاصية الجديدة
  });

  @override
  State<UploadCertificateView> createState() => _UploadCertificateViewState();
}

class _UploadCertificateViewState extends State<UploadCertificateView> {
  XFile? _image;
  UploadState _uploadState = UploadState.idle;
  String _errorMessage = '';
  int _countdown = 3;
  Timer? _timer;
  final ImagePicker _picker = ImagePicker();

  // 👇 حقول كود الخصم
  final _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  String? _appliedCouponCode;
  double? _discountedPrice;
  double? _discountAmount;

  @override
  void dispose() {
    _timer?.cancel();
    _couponController.dispose();
    super.dispose();
  }

  // 👇 دالة نسخ رقم المحفظة
  void _copyPhoneNumber() {
    final phone = '01027252071';
    Clipboard.setData(ClipboardData(text: phone)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('تم نسخ رقم المحفظة بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.success600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    if (_uploadState == UploadState.uploading ||
        _uploadState == UploadState.success)
      return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = image;
        _uploadState = UploadState.idle;
        _errorMessage = '';
      });
    }
  }

  // 👇 تطبيق كود الخصم
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      _showError('يرجى إدخال كود الخصم');
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final response = await SubscriptionRepo().applyCoupon(
        widget.planId,
        code,
      );

      if (response.success && response.data != null) {
        setState(() {
          _appliedCouponCode = code;
          _discountAmount = response.data!.plan.discountAmount;
          _discountedPrice = response.data!.plan.finalPrice;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تطبيق كود الخصم "$code" بنجاح!'),
              backgroundColor: AppColors.success600,
            ),
          );
        }
      } else {
        throw Exception(response.message ?? 'كود الخصم غير صالح');
      }
    } catch (e) {
      if (e is ApiError) {
        _showError(e.message);
      } else {
        _showError('فشل تطبيق الكود: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCoupon = false;
        });
      }
    }
  }

  Future<void> _uploadCertificate() async {
    if (_image == null) {
      _showError('يرجى اختيار صورة الإيصال أولًا');
      return;
    }

    final path = _image!.path.toLowerCase();
    if (!path.endsWith('.png') &&
        !path.endsWith('.jpg') &&
        !path.endsWith('.jpeg')) {
      _showError('يرجى اختيار صورة بصيغة PNG أو JPG');
      return;
    }

    final token = await PrefHelper.getToken();
    if (token == null || token.isEmpty) {
      _showError('يرجى تسجيل الدخول أولاً');
      return;
    }

    setState(() {
      _uploadState = UploadState.uploading;
      _errorMessage = '';
    });

    try {
      final bytes = await _image!.readAsBytes();
      final formData = FormData.fromMap({
        'paid_certificate': MultipartFile.fromBytes(
          bytes,
          filename: 'payment_proof.${_image!.name.split('.').last}',
          contentType: _image!.mimeType != null
              ? DioMediaType.parse(_image!.mimeType!)
              : null,
        ),
        'plan_id': widget.planId.toString(),
        if (_appliedCouponCode != null) 'coupon': _appliedCouponCode,
      });

      final response = await ApiServices().postFormData(
        '/upload-paid-certificate',
        formData,
      );

      if (response is ApiError) {
        _showError(response.message);
      } else if (response is Map<String, dynamic> &&
          response['success'] == true) {
        // ✅ نجاح: عرض رسالة + عدّ تنازلي
        if (!mounted) return;
        setState(() {
          _uploadState = UploadState.success;
          _countdown = 3;
        });

        // بدء العدّ التنازلي
        _startCountdown();
      } else {
        _showError('استجابة غير متوقعة من الخادم. يرجى المحاولة لاحقًا.');
      }
    } catch (e) {
      _showError('خطأ فني: ${e.toString()}');
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0 && mounted) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          // التوجيه إلى الصفحة الرئيسية
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
            (route) => false,
          );
        }
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error600),
    );
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
          'إثبات الدفع',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات الباقة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray200.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: AppColors.brandPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    color: AppColors.gray900,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'السعر: ${widget.planPrice.toInt()} ج.م',
                                  style: TextStyle(
                                    color: AppColors.gray600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_discountedPrice != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.discount,
                              color: AppColors.success600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'بعد الخصم: ${_discountedPrice!.toInt()} ج.م',
                              style: TextStyle(
                                color: AppColors.success700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                'وفر ${_discountAmount!.toInt()} ج.م',
                                style: TextStyle(
                                  color: AppColors.success700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(24),

                // 👇 قسم رقم المحفظة المميز (جديد)
                _buildWalletNumberSection(),

                const Gap(20),

                CustomText(
                  text: 'يرجى رفع صورة من إيصال الدفع لتفعيل اشتراكك',
                  color: AppColors.gray600,
                  size: 14,
                ),
                const Gap(24),

                // منطقة الصورة أو رسالة النجاح
                if (_uploadState == UploadState.success)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 80,
                          color: AppColors.success600,
                        ),
                        const Gap(24),
                        CustomText(
                          text: 'تم الرفع بنجاح!',
                          color: AppColors.gray900,
                          size: 22,
                          weight: FontWeight.bold,
                        ),
                        const Gap(8),
                        CustomText(
                          text:
                              'سيتم تحويلك إلى الصفحة الرئيسية بعد $_countdown ثواني...',
                          color: AppColors.gray700,
                          size: 15,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: GestureDetector(
                      onTap: _uploadState != UploadState.uploading
                          ? _pickImage
                          : null,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _image != null
                              ? Colors.transparent
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _uploadState == UploadState.error
                                ? AppColors.error500
                                : AppColors.gray300,
                            width: _uploadState == UploadState.error ? 2 : 1,
                          ),
                        ),
                        child: _buildImageOrPlaceholder(),
                      ),
                    ),
                  ),
                const Gap(24),

                if (_uploadState == UploadState.error)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomText(
                      text: _errorMessage,
                      color: AppColors.error600,
                      size: 14,
                      align: TextAlign.center,
                    ),
                  ),

                const Gap(24),
                _buildCouponSection(),

                const Gap(24),

                // زر الرفع (يختفي عند النجاح)
                if (_uploadState != UploadState.success)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadState == UploadState.uploading
                          ? null
                          : _uploadCertificate,
                      icon: _buildButtonIcon(),
                      label: _buildButtonText(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👇 ويدجت قسم رقم المحفظة المميز (جديد)
  Widget _buildWalletNumberSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, Color(0xFF1a3a8f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyPhoneNumber,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // أيقونة المحفظة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // رقم المحفظة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم محفظة الدفع',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '01027252071',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // زر النسخ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.copy,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          File(_image!.path),
          fit: BoxFit.cover,
          width: 200,
          height: 200,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload, size: 48, color: AppColors.gray400),
        const Gap(12),
        CustomText(
          text: 'اضغط لاختيار صورة',
          color: AppColors.gray600,
          size: 14,
        ),
      ],
    );
  }

  Widget _buildButtonIcon() {
    switch (_uploadState) {
      case UploadState.uploading:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case UploadState.error:
        return const Icon(Icons.refresh, size: 16);
      default:
        return const Icon(Icons.file_upload, size: 16);
    }
  }

  Widget _buildButtonText() {
    switch (_uploadState) {
      case UploadState.uploading:
        return const Text('جاري الرفع...');
      case UploadState.error:
        return const Text('إعادة المحاولة');
      default:
        return const Text('رفع الإيصال');
    }
  }

  Color _getButtonColor() {
    if (_uploadState == UploadState.uploading) return AppColors.gray300;
    if (_uploadState == UploadState.error) return AppColors.error600;
    return AppColors.brandPrimary;
  }

  // 👇 قسم كود الخصم
  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppColors.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'كود الخصم',
                style: TextStyle(
                  color: AppColors.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _appliedCouponCode != null
                          ? AppColors.success500
                          : AppColors.gray300,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: _appliedCouponCode != null
                          ? '✓ تم تطبيق: $_appliedCouponCode'
                          : 'أدخل كود الخصم',
                      hintStyle: TextStyle(
                        color: _appliedCouponCode != null
                            ? AppColors.success700
                            : AppColors.gray500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _appliedCouponCode != null
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppColors.gray500,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _appliedCouponCode = null;
                                  _discountedPrice = null;
                                  _discountAmount = null;
                                  _couponController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    enabled: _appliedCouponCode == null,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isApplyingCoupon || _appliedCouponCode != null
                      ? null
                      : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appliedCouponCode != null
                        ? AppColors.success100
                        : AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _appliedCouponCode != null ? 'مطبق' : 'تطبيق',
                          style: TextStyle(
                            color: _appliedCouponCode != null
                                ? AppColors.success700
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
