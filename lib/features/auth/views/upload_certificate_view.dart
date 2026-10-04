import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

enum UploadState { idle, uploading, success, error }

class UploadCertificateView extends StatefulWidget {
  final int planId;
  final String planName;
  final double planPrice;
  final bool hasDiscount; // 👈 إضافة الخاصية الجديدة

  /// Where to transfer the money — from the dashboard, per package.
  final List<PaymentAccount> paymentAccounts;

  const UploadCertificateView({
    super.key,
    required this.planId,
    required this.planName,
    required this.planPrice,
    required this.hasDiscount, // 👈 تمرير الخاصية الجديدة
    this.paymentAccounts = const [],
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The accounts to show: the package's own, or the legacy number when an
  /// older backend sent none.
  List<PaymentAccount> get _accounts => widget.paymentAccounts.isNotEmpty
      ? widget.paymentAccounts
      : PaymentAccount.legacy;

  // 👇 نسخ رقم الحساب
  void _copyAccount(String value) {
    Clipboard.setData(ClipboardData(text: value)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('تم نسخ الرقم بنجاح!'),
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
          // Back to the plan list with `true`, which closes it too and lands
          // the student on the course they were in — now showing the request
          // as pending. Not home: they came here from a lesson.
          Navigator.pop(context, true);
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
                    ],
                  ),
                ),
                const Gap(24),

                // The amount, then where to send it — payment is outside the app.
                _buildAmountToTransfer(),
                const Gap(12),
                for (final account in _accounts) ...[
                  _buildWalletNumberSection(account),
                  const Gap(10),
                ],

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
                          text: 'تم استلام إيصال الدفع',
                          color: AppColors.gray900,
                          size: 22,
                          weight: FontWeight.bold,
                        ),
                        const Gap(8),
                        CustomText(
                          text:
                              'سيتم تفعيل اشتراكك بعد مراجعة الإيصال، وتكمل دروسك من حيث توقفت.\nالعودة خلال $_countdown ثوانٍ...',
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

  Widget _buildAmountToTransfer() {
    final amount = widget.planPrice.toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.success50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success500.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          CustomText(
            text: 'المبلغ المطلوب تحويله',
            color: AppColors.gray700,
            size: 14,
          ),
          const Gap(4),
          CustomText(
            text: '$amount ج.م',
            color: AppColors.success700,
            size: 26,
            weight: FontWeight.bold,
          ),
          const Gap(4),
          CustomText(
            text: 'حوّل المبلغ على أحد الحسابات التالية ثم ارفع صورة الإيصال',
            color: AppColors.gray600,
            size: 12,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 👇 بطاقة حساب دفع واحد (من لوحة التحكم)
  Widget _buildWalletNumberSection(PaymentAccount account) {
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
          onTap: () => _copyAccount(account.value),
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
                        account.label.isEmpty ? 'رقم الحساب' : account.label,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.value,
                        textDirection: TextDirection.ltr,
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
}
