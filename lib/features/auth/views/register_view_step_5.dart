// lib/features/auth/views/register_view_step_5.dart
//
// Complete-profile part B: institute, location, supervisors, quran level.
// Submits AuthRepo.completeProfile(), then moves to payment certificate upload.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/upload_certificate_view.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep5View extends StatefulWidget {
  final RegistrationData registrationData;
  const RegisterStep5View({super.key, required this.registrationData});

  @override
  State<RegisterStep5View> createState() => _RegisterStep5ViewState();
}

class _RegisterStep5ViewState extends State<RegisterStep5View> {
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _quranLevelController = TextEditingController();
  final TextEditingController _supervisorNameController =
      TextEditingController();
  final TextEditingController _supervisorPhoneController =
      TextEditingController();
  final TextEditingController _supervisor2NameController =
      TextEditingController();
  final TextEditingController _supervisor2PhoneController =
      TextEditingController();

  bool _isWhatsapp = true;
  bool _showSecondSupervisor = false;

  final Map<String, List<String>> _governoratesAndCities = {
    'القاهرة': ['القاهرة', 'القاهرة الجديدة', 'المعادي', 'الزمالك', 'شبرا', 'المنيل'],
    'الإسكندرية': ['الإسكندرية', 'سموحة', 'العجمي', 'كرموز', 'برج العرب', 'أبو قير'],
    'الجيزة': ['الجيزة', '6 أكتوبر', 'الشيخ زايد', 'العمرانية', 'كرداسة', 'أوسيم'],
    'القليوبية': ['بنها', 'شبرا الخيمة', 'قليوب', 'طوخ', 'كفر شكر', 'القناطر الخيرية'],
    'الغربية': ['طنطا', 'المحلة الكبرى', 'زفتى', 'سمنود', 'قطور', 'بسيون'],
    'الدقهلية': ['المنصورة', 'ميت غمر', 'دكرنس', 'أجا', 'بلقاس', 'منية النصر'],
    'الشرقية': ['الزقازيق', 'الإسماعيلية', 'أولاد صقر', 'ديرب نجم', 'ههيا', 'منيا القمح'],
    'المنوفية': ['شبين الكوم', 'قويسنا', 'بركة السبع', 'الباجور', 'أشمون', 'سرس الليان'],
    'الفيوم': ['الفيوم', 'أبشواي', 'إطسا', 'سنورس', 'طامية', 'يوسف الصديق'],
    'بني سويف': ['بني سويف', 'الواسطى', 'ناصر', 'إهناسيا', 'ببا', 'سمسطا'],
    'المنيا': ['المنيا', 'مغاغة', 'بني مزار', 'مطاي', 'أبو قرقاص', 'ديرمواس'],
    'أسيوط': ['أسيوط', 'أبنوب', 'أسيوط الجديدة', 'منفلوط', 'الغنايم', 'البداري'],
    'سوهاج': ['سوهاج', 'أخميم', 'دار السلام', 'طما', 'جهينة', 'المراغة'],
    'قنا': ['قنا', 'القوصية', 'نجع حمادي', 'أبو تشت', 'فرشوط', 'ديروط'],
    'الأقصر': ['الأقصر', 'إسنا', 'الزينية', 'أرمنت', 'طيبة'],
    'أسوان': ['أسوان', 'كوم أمبو', 'إدفو', 'درة', 'نصر النوبة'],
    'البحر الأحمر': ['الغردقة', 'رأس غارب', 'سفاجا', 'مرسى علم', 'القصير'],
    'الوادي الجديد': ['الخارجة', 'باريس', 'الفرافرة', 'الداخلة', 'الضبعة'],
    'مطروح': ['مرسى مطروح', 'السلوم', 'الضبعة', 'النجيلة', 'سيدي براني'],
    'شمال سيناء': ['العريش', 'الشيخ زويد', 'رفح', 'بئر العبد', 'الحسنة'],
    'جنوب سيناء': ['شرم الشيخ', 'الطور', 'دهب', 'أبو رديس', 'نبق', 'سانت كاترين'],
    'دمياط': ['دمياط', 'كفر سعد', 'عزبة البرج', 'فارسكور', 'الروضة'],
    'بورسعيد': ['بورسعيد', 'الزهور', 'الضواحي', 'المنصورة الجديدة'],
    'الإسماعيلية': ['الإسماعيلية', 'فايد', 'القصاصين', 'أبو صوير', 'التل الكبير'],
    'كفر الشيخ': ['كفر الشيخ', 'دسوق', 'فوه', 'مطوبس', 'بيلا', 'البرلس'],
    'السويس': ['السويس', 'العين السخنة', 'فيصل', 'الجناين', 'عتاقة'],
    'البحيرة': ['دمنهور', 'رشيد', 'إدكو', 'أبو المطامير', 'المحمودية', 'حوش عيسى'],
  };

  String? _selectedGovernorate;
  String? _selectedCity;
  String? _selectedRelation;
  String? _selectedRelation2;

  final List<String> _relations = ['أب', 'أم', 'أخ', 'أخت', 'وصي', 'صديق'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepo _authRepo = AuthRepo();
  bool isLoading = false;

  String? _validateRequiredText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'الرجاء إدخال هذا الحقل';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(text)) {
      return 'رقم الهاتف غير صالح (11 رقمًا يبدأ بـ 010, 011, 012, أو 015)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGovernorate == null ||
        _selectedCity == null ||
        _selectedRelation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      String? supervisor2Name;
      String? supervisor2Relation;
      String? supervisor2Phone;
      if (_showSecondSupervisor) {
        final name = _supervisor2NameController.text.trim();
        final phone = _supervisor2PhoneController.text.trim();
        if (name.isNotEmpty && phone.isNotEmpty && _selectedRelation2 != null) {
          supervisor2Name = name;
          supervisor2Relation = _selectedRelation2;
          supervisor2Phone = phone;
        }
      }

      final data = widget.registrationData;
      final student = await _authRepo.completeProfile(
        firstName: data.firstName,
        lastName: data.lastName,
        gender: data.gender,
        birthDate: data.birthDate,
        madhab: data.madhab,
        isFinalSecondary: data.isFinalSecondary,
        schoolBranch: data.schoolBranch,
        termLevel: data.termLevel,
        instituteName: _instituteController.text.trim(),
        governorate: _selectedGovernorate!,
        city: _selectedCity!,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone2: _phone2Controller.text.trim().isEmpty
            ? null
            : _phone2Controller.text.trim(),
        isWhatsapp: _isWhatsapp,
        quranLevel: int.tryParse(_quranLevelController.text.trim()),
        supervisor1Name: _supervisorNameController.text.trim(),
        supervisor1Relation: _selectedRelation!,
        supervisor1Phone: _supervisorPhoneController.text.trim(),
        supervisor2Name: supervisor2Name,
        supervisor2Relation: supervisor2Relation,
        supervisor2Phone: supervisor2Phone,
      );

      if (!mounted) return;
      // A student completing their profile later (from the home banner) may have
      // already paid, so only send them to the upload screen if they still owe it.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => student.isUploadPaidCertificate
              ? const HomeView()
              : UploadCertificateView(
                  planId: student.planId ?? data.planId,
                  planName: '',
                  planPrice: 0,
                  hasDiscount: false,
                ),
        ),
        (route) => false,
      );
    } catch (e) {
      final msg = e is ApiError ? e.message : 'حدث خطأ غير متوقع';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _instituteController.dispose();
    _emailController.dispose();
    _phone2Controller.dispose();
    _quranLevelController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    _supervisor2NameController.dispose();
    _supervisor2PhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFlowPopScope(
      isBusy: isLoading,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.gray50,
          appBar: ProfileFlowAppBar(
            title: 'استكمال البيانات',
            isBusy: isLoading,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final bool isCompleted = index < 5;
                        final bool isCurrent = index == 4;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isCurrent || isCompleted
                                  ? AppColors.brandPrimary
                                  : AppColors.primary100,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    Gap(24),
                    Expanded(
                      child: ListView(
                        children: [
                          Text(
                            'أدخل بيانات معهدك والمشرف عليك',
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontSize: 16,
                            ),
                          ),
                          Gap(24),
                          _buildField(
                            title: 'اسم المعهد',
                            child: CustomTextField(
                              hint: 'اسم المعهد',
                              isPassword: false,
                              controller: _instituteController,
                              validator: _validateRequiredText,
                            ),
                          ),
                          _buildField(
                            title: 'المحافظة',
                            child: CustomDropdown<String>(
                              hint: 'اختر المحافظة',
                              items: _governoratesAndCities.keys.toList(),
                              itemAsString: (item) => item,
                              value: _selectedGovernorate,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGovernorate = value;
                                  _selectedCity = null;
                                });
                              },
                              required: true,
                            ),
                          ),
                          _buildField(
                            title: 'المدينة',
                            child: CustomDropdown<String>(
                              hint: 'اختر المدينة',
                              items: _selectedGovernorate != null
                                  ? _governoratesAndCities[_selectedGovernorate]!
                                  : [],
                              itemAsString: (item) => item,
                              value: _selectedCity,
                              onChanged: (value) =>
                                  setState(() => _selectedCity = value),
                              required: true,
                            ),
                          ),
                          _buildField(
                            title: 'البريد الإلكتروني (اختياري)',
                            child: CustomTextField(
                              hint: 'example@example.com',
                              isPassword: false,
                              controller: _emailController,
                            ),
                          ),
                          _buildField(
                            title: 'رقم هاتف إضافي (اختياري)',
                            child: CustomTextField(
                              hint: '01012345678',
                              isPassword: false,
                              controller: _phone2Controller,
                            ),
                          ),
                          _buildField(
                            title: 'عدد الأجزاء المحفوظة (اختياري)',
                            child: CustomTextField(
                              hint: 'من 0 إلى 30',
                              isPassword: false,
                              controller: _quranLevelController,
                            ),
                          ),
                          Gap(4),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.brandPrimary,
                            title: CustomText(
                              text: 'رقم الهاتف الأساسي على واتساب',
                              color: AppColors.gray900,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                            value: _isWhatsapp,
                            onChanged: (value) =>
                                setState(() => _isWhatsapp = value),
                          ),
                          Gap(16),
                          _buildField(
                            title: 'اسم المشرف',
                            child: CustomTextField(
                              hint: 'اسم المشرف',
                              isPassword: false,
                              controller: _supervisorNameController,
                              validator: _validateRequiredText,
                            ),
                          ),
                          _buildField(
                            title: 'صلة الإشراف',
                            child: CustomDropdown<String>(
                              hint: 'اختر صلة الإشراف',
                              items: _relations,
                              itemAsString: (item) => item,
                              value: _selectedRelation,
                              onChanged: (value) =>
                                  setState(() => _selectedRelation = value),
                              required: true,
                            ),
                          ),
                          _buildField(
                            title: 'رقم هاتف المشرف',
                            child: CustomTextField(
                              hint: '01110022133',
                              isPassword: false,
                              controller: _supervisorPhoneController,
                              validator: _validatePhone,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showSecondSupervisor = !_showSecondSupervisor;
                                  if (!_showSecondSupervisor) {
                                    _supervisor2NameController.clear();
                                    _supervisor2PhoneController.clear();
                                    _selectedRelation2 = null;
                                  }
                                });
                              },
                              icon: Icon(
                                _showSecondSupervisor ? Icons.remove : Icons.add,
                                color: AppColors.brandPrimary,
                              ),
                              label: Text(
                                _showSecondSupervisor
                                    ? 'إخفاء المشرف الثاني'
                                    : 'أضف مُشرفًا آخر (اختياري)',
                                style: TextStyle(color: AppColors.brandPrimary),
                              ),
                            ),
                          ),
                          if (_showSecondSupervisor) ...[
                            const Divider(color: AppColors.gray200, height: 24),
                            _buildField(
                              title: 'اسم المشرف الثاني (اختياري)',
                              child: CustomTextField(
                                hint: 'اسم المشرف',
                                isPassword: false,
                                controller: _supervisor2NameController,
                              ),
                            ),
                            _buildField(
                              title: 'صلة الإشراف (اختياري)',
                              child: CustomDropdown<String>(
                                hint: 'اختر صلة الإشراف',
                                items: _relations,
                                itemAsString: (item) => item,
                                value: _selectedRelation2,
                                onChanged: (value) =>
                                    setState(() => _selectedRelation2 = value),
                              ),
                            ),
                            _buildField(
                              title: 'رقم هاتف المشرف الثاني (اختياري)',
                              child: CustomTextField(
                                hint: '01110022133',
                                isPassword: false,
                                controller: _supervisor2PhoneController,
                              ),
                            ),
                          ],
                          CustomElevatedButton(
                            text: isLoading ? 'جاري الإرسال...' : 'إنشاء',
                            icon: const Icon(Icons.check),
                            onPressed: isLoading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          color: AppColors.gray900,
          size: 16,
          weight: FontWeight.w600,
        ),
        Gap(2),
        child,
        Gap(24),
      ],
    );
  }
}
