// lib/features/auth/views/register_view_step_3.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep3View extends StatefulWidget {
  final RegistrationData initialData;
  const RegisterStep3View({super.key, required this.initialData});

  @override
  State<RegisterStep3View> createState() => _RegisterStep3ViewState();
}

class _RegisterStep3ViewState extends State<RegisterStep3View> {
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _supervisorNameController =
      TextEditingController();
  final TextEditingController _supervisorPhoneController =
      TextEditingController();
  final TextEditingController _supervisor2NameController =
      TextEditingController();
  final TextEditingController _supervisor2PhoneController =
      TextEditingController();

  bool _showSecondSupervisor = false;

  final Map<String, List<String>> _governoratesAndCities = {
    'القاهرة': [
      'القاهرة',
      'القاهرة الجديدة',
      'المعادي',
      'الزمالك',
      'شبرا',
      'المنيل',
    ],
    'الإسكندرية': [
      'الإسكندرية',
      'سموحة',
      'العجمي',
      'كرموز',
      'برج العرب',
      'أبو قير',
    ],
    'الجيزة': [
      'الجيزة',
      '6 أكتوبر',
      'الشيخ زايد',
      'العمرانية',
      'كرداسة',
      'أوسيم',
    ],
    'القليوبية': [
      'بنها',
      'شبرا الخيمة',
      'قليوب',
      'طوخ',
      'كفر شكر',
      'القناطر الخيرية',
    ],
    'الغربية': ['طنطا', 'المحلة الكبرى', 'زفتى', 'سمنود', 'قطور', 'بسيون'],
    'الدقهلية': ['المنصورة', 'ميت غمر', 'دكرنس', 'أجا', 'بلقاس', 'منية النصر'],
    'الشرقية': [
      'الزقازيق',
      'الإسماعيلية',
      'أولاد صقر',
      'ديرب نجم',
      'ههيا',
      'منيا القمح',
    ],
    'المنوفية': [
      'شبين الكوم',
      'قويسنا',
      'بركة السبع',
      'الباجور',
      'أشمون',
      'سرس الليان',
    ],
    'الفيوم': ['الفيوم', 'أبشواي', 'إطسا', 'سنورس', 'طامية', 'يوسف الصديق'],
    'بني سويف': ['بني سويف', 'الواسطى', 'ناصر', 'إهناسيا', 'ببا', 'سمسطا'],
    'المنيا': ['المنيا', 'مغاغة', 'بني مزار', 'مطاي', 'أبو قرقاص', 'ديرمواس'],
    'أسيوط': [
      'أسيوط',
      'أبنوب',
      'أسيوط الجديدة',
      'منفلوط',
      'الغنايم',
      'البداري',
    ],
    'سوهاج': ['سوهاج', 'أخميم', 'دار السلام', 'طما', 'جهينة', 'المراغة'],
    'قنا': ['قنا', 'القوصية', 'نجع حمادي', 'أبو تشت', 'فرشوط', 'ديروط'],
    'الأقصر': ['الأقصر', 'إسنا', 'الزينية', 'أرمنت', 'طيبة'],
    'أسوان': ['أسوان', 'كوم أمبو', 'إدفو', 'درة', 'نصر النوبة'],
    'البحر الأحمر': ['الغردقة', 'رأس غارب', 'سفاجا', 'مرسى علم', 'القصير'],
    'الوادي الجديد': ['الخارجة', 'باريس', 'الفرافرة', 'الداخلة', 'الضبعة'],
    'مطروح': ['مرسى مطروح', 'السلوم', 'الضبعة', 'النجيلة', 'سيدي براني'],
    'شمال سيناء': ['العريش', 'الشيخ زويد', 'رفح', 'بئر العبد', 'الحسنة'],
    'جنوب سيناء': [
      'شرم الشيخ',
      'الطور',
      'دهب',
      'أبو رديس',
      'نبق',
      'سانت كاترين',
    ],
    'دمياط': ['دمياط', 'كفر سعد', 'عزبة البرج', 'فارسكور', 'الروضة'],
    'بورسعيد': ['بورسعيد', 'الزهور', 'الضواحي', 'المنصورة الجديدة'],
    'الإسماعيلية': [
      'الإسماعيلية',
      'فايد',
      'القصاصين',
      'أبو صوير',
      'التل الكبير',
    ],
    'كفر الشيخ': ['كفر الشيخ', 'دسوق', 'فوه', 'مطوبس', 'بيلا', 'البرلس'],
    'السويس': ['السويس', 'العين السخنة', 'فيصل', 'الجناين', 'عتاقة'],
    'البحيرة': [
      'دمنهور',
      'رشيد',
      'إدكو',
      'أبو المطامير',
      'المحمودية',
      'حوش عيسى',
    ],
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
    if (text == null || text.isEmpty) {
      return 'الرجاء إدخال هذا الحقل';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(text)) {
      return 'رقم الهاتف غير صالح (11 رقمًا يبدأ بـ 010, 011, 012, أو 015)';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
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
          if (name.isNotEmpty &&
              phone.isNotEmpty &&
              _selectedRelation2 != null) {
            supervisor2Name = name;
            supervisor2Relation = _selectedRelation2;
            supervisor2Phone = phone;
          }
        }

        final success = await _authRepo.register(
          firstName: widget.initialData.firstName,
          lastName: widget.initialData.lastName,
          gender: widget.initialData.gender,
          birthDate: widget.initialData.birthDate,
          isFinalSecondary: widget.initialData.branch == 'science',
          schoolBranch: widget.initialData.branch,
          instituteName: _instituteController.text.trim(),
          governorate: _selectedGovernorate!,
          city: _selectedCity!,
          phone1: widget.initialData.mainPhone,
          phone2: widget.initialData.secondaryPhone,
          isWhatsapp: true,
          email: widget.initialData.email,
          quranLevel: 'beginner',
          doctrine: 'sunni',
          supervisorName: _supervisorNameController.text.trim(),
          supervisorRelation: _selectedRelation!,
          supervisorPhone: _supervisorPhoneController.text.trim(),
          supervisor2Name: supervisor2Name,
          supervisor2Relation: supervisor2Relation,
          supervisor2Phone: supervisor2Phone,
          password: widget.initialData.password,
          confirmPassword: widget.initialData.confirmPassword,
          referralCode: widget.initialData.referralCode,
        );

        if (success) {
          // ✅ إنشاء كائن بيانات كامل للشاشة التالية
          final completeData = RegistrationData(
            email: widget.initialData.email,
            password: widget.initialData.password,
            confirmPassword: widget.initialData.confirmPassword,
            firstName: widget.initialData.firstName,
            lastName: widget.initialData.lastName,
            mainPhone: widget.initialData.mainPhone,
            secondaryPhone: widget.initialData.secondaryPhone,
            gender: widget.initialData.gender,
            branch: widget.initialData.branch,
            birthDate: widget.initialData.birthDate,
            referralCode: widget.initialData.referralCode,

            // 👇 الحقول من هذه الشاشة
            instituteName: _instituteController.text.trim(),
            governorate: _selectedGovernorate!,
            city: _selectedCity!,
            supervisorName: _supervisorNameController.text.trim(),
            supervisorRelation: _selectedRelation!,
            supervisorPhone: _supervisorPhoneController.text.trim(),
            supervisor2Name: supervisor2Name,
            supervisor2Relation: supervisor2Relation,
            supervisor2Phone: supervisor2Phone,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterStep4View(
                phoneNumber: widget.initialData.mainPhone,
                registrationData: completeData, // ✅ تم التصحيح هنا
              ),
            ),
          );
        }
      } catch (e) {
        String msg = e is ApiError ? e.message : 'حدث خطأ غير متوقع';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
            onPressed: () => Navigator.pop(context),
          ),
          scrolledUnderElevation: 0,
          title: CustomText(
            text: 'إنشاء الحساب',
            color: AppColors.brandPrimary,
            size: 18,
            weight: FontWeight.w600,
          ),
          centerTitle: true,
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
                    children: List.generate(4, (index) {
                      final bool isCompleted = index < 2;
                      final bool isCurrent = index == 2;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.brandPrimary
                                : isCurrent
                                ? AppColors.primary300
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
                          'أدخل بيانات معهدك',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontSize: 16,
                          ),
                        ),
                        Gap(32),

                        _buildField(
                          title: "اسم المعهد",
                          child: CustomTextField(
                            hint: "اسم المعهد",
                            isPassword: false,
                            controller: _instituteController,
                            validator: _validateRequiredText,
                          ),
                        ),
                        _buildField(
                          title: "المحافظة",
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
                          title: "المدينة",
                          child: CustomDropdown<String>(
                            hint: 'اختر المدينة',
                            items: _selectedGovernorate != null
                                ? _governoratesAndCities[_selectedGovernorate]!
                                : [],
                            itemAsString: (item) => item,
                            value: _selectedCity,
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                            },
                            required: true,
                          ),
                        ),
                        _buildField(
                          title: "اسم المشرف",
                          child: CustomTextField(
                            hint: "اسم المشرف",
                            isPassword: false,
                            controller: _supervisorNameController,
                            validator: _validateRequiredText,
                          ),
                        ),
                        _buildField(
                          title: "صلة الاشراف",
                          child: CustomDropdown<String>(
                            hint: 'اختر صلة الاشراف',
                            items: _relations,
                            itemAsString: (item) => item,
                            value: _selectedRelation,
                            onChanged: (value) {
                              setState(() {
                                _selectedRelation = value;
                              });
                            },
                            required: true,
                          ),
                        ),
                        _buildField(
                          title: "رقم هاتف المشرف",
                          child: CustomTextField(
                            hint: "01110022133",
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
                                  ? 'إخفاء المشرف الجديد'
                                  : 'أضف مُشرفًا جديدًا (اختياري)',
                              style: TextStyle(color: AppColors.brandPrimary),
                            ),
                          ),
                        ),

                        if (_showSecondSupervisor) ...[
                          const Divider(color: AppColors.gray200, height: 24),
                          _buildField(
                            title: "اسم المشرف الجديد (اختياري)",
                            child: CustomTextField(
                              hint: "اسم المشرف",
                              isPassword: false,
                              controller: _supervisor2NameController,
                            ),
                          ),
                          _buildField(
                            title: "صلة الاشراف (اختياري)",
                            child: CustomDropdown<String>(
                              hint: 'اختر صلة الاشراف',
                              items: _relations,
                              itemAsString: (item) => item,
                              value: _selectedRelation2,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRelation2 = value;
                                });
                              },
                            ),
                          ),
                          _buildField(
                            title: "رقم هاتف المشرف الجديد (اختياري)",
                            child: CustomTextField(
                              hint: "01110022133",
                              isPassword: false,
                              controller: _supervisor2PhoneController,
                            ),
                          ),
                        ],

                        CustomElevatedButton(
                          text: isLoading ? 'جاري التسجيل...' : 'إنشاء',
                          icon: const Icon(Icons.check),
                          onPressed: isLoading ? null : _register,
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

  @override
  void dispose() {
    _instituteController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    _supervisor2NameController.dispose();
    _supervisor2PhoneController.dispose();
    super.dispose();
  }
}
