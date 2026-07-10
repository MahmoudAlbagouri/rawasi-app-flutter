// // lib/features/contact/views/contact_view.dart

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:rawasi_app_n/core/constants/app_colors.dart';
// import 'package:rawasi_app_n/core/network/api_services.dart';
// import 'package:rawasi_app_n/features/contact/data/contact_message.dart';
// import 'package:rawasi_app_n/features/contact/widgets/message_card.dart';
// import 'package:rawasi_app_n/features/contact/widgets/send_message_form.dart';
// import 'package:rawasi_app_n/shared/custom_text.dart';

// class ContactView extends StatefulWidget {
//   const ContactView({super.key});

//   @override
//   State<ContactView> createState() => _ContactViewState();
// }

// class _ContactViewState extends State<ContactView>
//     with SingleTickerProviderStateMixin {
//   late Future<List<ContactMessage>> _messagesFuture;
//   final TextEditingController _controller = TextEditingController();
//   late AnimationController _titleController;
//   late Animation<double> _titleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _messagesFuture = fetchMessages();

//     _titleController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _titleAnimation = CurvedAnimation(
//       parent: _titleController,
//       curve: Curves.easeOut,
//     );
//     _titleController.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _titleController.dispose();
//     super.dispose();
//   }

//   Future<List<ContactMessage>> fetchMessages() async {
//     try {
//       final response = await ApiServices().get('/my-contact-support');
//       if (response is Map && response['success'] == true) {
//         final List<dynamic> data = response['data'];
//         return data.map((e) => ContactMessage.fromJson(e)).toList();
//       }
//       return [];
//     } catch (e) {
//       return [];
//     }
//   }

//   Future<void> _sendMessage() async {
//     final message = _controller.text.trim();
//     if (message.isEmpty) return;

//     try {
//       final response = await ApiServices().postFormData(
//         '/contact-support',
//         FormData.fromMap({'message': message}),
//       );
//       if (response is Map && response['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(response['message']),
//             backgroundColor: AppColors.brandPrimary,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//         _controller.clear();
//         setState(() {
//           _messagesFuture = fetchMessages();
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('حدث خطأ أثناء الإرسال'),
//           backgroundColor: AppColors.error500,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.gray50,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: const CustomText(
//           text: 'تواصل معنا',
//           color: AppColors.gray900,
//           size: 18,
//           weight: FontWeight.bold,
//         ),
//         centerTitle: true,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // العنوان الرئيسي
//               FadeTransition(
//                 opacity: _titleAnimation,
//                 child: SlideTransition(
//                   position: Tween<Offset>(
//                     begin: const Offset(0, -0.2),
//                     end: Offset.zero,
//                   ).animate(_titleAnimation),
//                   child: CustomText(
//                     text: 'تواصل مع الرواسي الآن',
//                     color: AppColors.brandPrimary,
//                     size: 24,
//                     weight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const Gap(20),

//               // ✅ رقم خدمة العملاء — ثابت، غير قابل للنقر، نظيف
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 14,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.gray100,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CustomText(
//                       text: 'رقم خدمة العملاء',
//                       color: AppColors.gray600,
//                       size: 13,
//                       weight: FontWeight.w600,
//                     ),
//                     const Gap(4),
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.call, size: 16, color: AppColors.gray500),
//                         const Gap(8),
//                         CustomText(
//                           text: '01027252071',
//                           color: AppColors.gray900,
//                           size: 16,
//                           weight: FontWeight.w600,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const Gap(24),

//               // نموذج إرسال الرسالة
//               SendMessageForm(controller: _controller, onSend: _sendMessage),
//               const Gap(24),

//               // عنوان "الأسئلة السابقة"
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: CustomText(
//                   text: 'الأسئلة السابقة',
//                   color: AppColors.gray600,
//                   size: 14,
//                   weight: FontWeight.w600,
//                 ),
//               ),
//               const Gap(8),

//               // قائمة الرسائل
//               Expanded(
//                 child: FutureBuilder<List<ContactMessage>>(
//                   future: _messagesFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                       return Center(
//                         child: CustomText(
//                           text: 'لا توجد رسائل سابقة',
//                           color: AppColors.gray500,
//                           size: 14,
//                         ),
//                       );
//                     }
//                     return ListView.builder(
//                       itemCount: snapshot.data!.length,
//                       itemBuilder: (context, index) {
//                         return MessageCard(message: snapshot.data![index]);
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/features/contact/views/contact_view.dart
// lib/features/contact/views/contact_view.dart
// lib/features/contact/views/contact_view.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← مهم لـ Clipboard
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/contact/data/contact_message.dart';
import 'package:rawasi_app_n/features/contact/widgets/message_card.dart';
import 'package:rawasi_app_n/features/contact/widgets/send_message_form.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView>
    with SingleTickerProviderStateMixin {
  late Future<List<ContactMessage>> _messagesFuture;
  final TextEditingController _controller = TextEditingController();
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    _messagesFuture = fetchMessages();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    );
    _titleController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<List<ContactMessage>> fetchMessages() async {
    try {
      final response = await ApiServices().get('/my-contact-support');
      if (response is Map && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((e) => ContactMessage.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    try {
      final response = await ApiServices().postFormData(
        '/contact-support',
        FormData.fromMap({'message': message}),
      );
      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: AppColors.brandPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _controller.clear();
        setState(() {
          _messagesFuture = fetchMessages();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ أثناء الإرسال'),
          backgroundColor: AppColors.error500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhoneNumberDialog() {
    const phoneNumber = '01027252071';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // العنوان
              Text(
                'رقم خدمة العملاء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),

              // ✅ الرقم - قابل للنقر للنسخ
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: phoneNumber));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم نسخ رقم خدمة العملاء'),
                      backgroundColor: AppColors.success700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gray200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        color: AppColors.brandPrimary,
                        size: 18,
                      ),
                      const Gap(8),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),

              // زر الإغلاق فقط
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'إغلاق',
                    style: TextStyle(
                      color: AppColors.gray700,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const CustomText(
          text: 'تواصل معنا',
          color: AppColors.gray900,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _titleAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(_titleAnimation),
                  child: CustomText(
                    text: 'تواصل مع الرواسي الآن',
                    color: AppColors.brandPrimary,
                    size: 24,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
              const Gap(24),
              SendMessageForm(controller: _controller, onSend: _sendMessage),
              const Gap(24),
              Align(
                alignment: Alignment.centerRight,
                child: CustomText(
                  text: 'الأسئلة السابقة',
                  color: AppColors.gray600,
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Expanded(
                child: FutureBuilder<List<ContactMessage>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: CustomText(
                          text: 'لا توجد رسائل سابقة',
                          color: AppColors.gray500,
                          size: 14,
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return MessageCard(message: snapshot.data![index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showPhoneNumberDialog,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.phone, size: 26),
        tooltip: 'عرض رقم خدمة العملاء',
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
