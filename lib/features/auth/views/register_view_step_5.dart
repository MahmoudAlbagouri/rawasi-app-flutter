// lib/features/auth/views/register_view_step_5.dart
//
// Complete-profile part B: institute and location. Submits
// AuthRepo.completeProfile(), then goes straight to home.
//
// free first month: البريد الإلكتروني, عدد أجزاء الحفظ and the supervisor
// blocks are gone - the backend no longer accepts them, and supervisor1_* is
// no longer required. There is no payment step either, so a completed profile
// lands on home and waits for an admin to activate the account.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep5View extends StatefulWidget {
  final RegistrationDraft draft;
  const RegisterStep5View({super.key, required this.draft});

  @override
  State<RegisterStep5View> createState() => _RegisterStep5ViewState();
}

class _RegisterStep5ViewState extends State<RegisterStep5View> {
  late final TextEditingController _instituteController;
  late final TextEditingController _phone2Controller;

  bool _isWhatsapp = true;

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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepo _authRepo = AuthRepo();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Seeded from the draft, so coming back here from step 4 restores every
    // value instead of showing an empty form.
    final d = widget.draft.data;
    _instituteController = TextEditingController(text: d.instituteName);
    _phone2Controller = TextEditingController(text: d.phone2 ?? '');
    _isWhatsapp = d.isWhatsapp;

    if (_governoratesAndCities.containsKey(d.governorate)) {
      _selectedGovernorate = d.governorate;
      if (_governoratesAndCities[d.governorate]!.contains(d.city)) {
        _selectedCity = d.city;
      }
    }
  }

  void _saveToDraft() {
    widget.draft.save((current) => current.copyWith(
          instituteName: _instituteController.text.trim(),
          governorate: _selectedGovernorate ?? '',
          city: _selectedCity ?? '',
          phone2: _phone2Controller.text.trim().isEmpty
              ? null
              : _phone2Controller.text.trim(),
          isWhatsapp: _isWhatsapp,
        ));
  }

  String? _validateRequiredText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'الرجاء إدخال هذا الحقل';
    return null;
  }

  String? _validateOptionalPhone(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(text)) {
      return 'رقم الهاتف غير صالح (11 رقمًا يبدأ بـ 010, 011, 012, أو 015)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGovernorate == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    _saveToDraft();
    setState(() => isLoading = true);
    try {
      final data = widget.draft.data;
      await _authRepo.completeProfile(
        firstName: data.firstName,
        lastName: data.lastName,
        gender: data.gender,
        birthDate: data.birthDate,
        madhab: data.madhab,
        schoolBranch: data.schoolBranch,
        instituteName: data.instituteName,
        governorate: data.governorate,
        city: data.city,
        phone2: data.phone2,
        isWhatsapp: data.isWhatsapp,
      );

      if (!mounted) return;

      // free first month: no receipt to upload and nothing to pay, so the
      // student goes straight home. Home shows the "حسابك قيد المراجعة" gate
      // until an admin activates the account.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
        (route) => false,
      );
    } catch (e) {
      final msg = e is ApiError ? e.message : 'حدث خطأ غير متوقع';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _saveToDraft();
    _instituteController.dispose();
    _phone2Controller.dispose();
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const Gap(24),
                    Expanded(
                      child: ListView(
                        children: [
                          const Text(
                            'أدخل بيانات معهدك',
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontSize: 16,
                            ),
                          ),
                          const Gap(24),
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
                            title: 'رقم هاتف إضافي (اختياري)',
                            child: CustomTextField(
                              hint: '01xxxxxxxxx',
                              isPassword: false,
                              controller: _phone2Controller,
                              validator: _validateOptionalPhone,
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.brandPrimary,
                            title: const CustomText(
                              text: 'هذا الرقم متاح على واتساب',
                              color: AppColors.gray900,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                            value: _isWhatsapp,
                            onChanged: (value) =>
                                setState(() => _isWhatsapp = value),
                          ),
                          const Gap(24),
                          CustomElevatedButton(
                            text: isLoading ? 'جارٍ الحفظ...' : 'إنهاء التسجيل',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,
            color: AppColors.gray900,
            size: 14,
            weight: FontWeight.w600,
          ),
          const Gap(8),
          child,
        ],
      ),
    );
  }
}
