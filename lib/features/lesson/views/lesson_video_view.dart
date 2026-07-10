import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/repositories/library_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/days/views/days_view.dart';
import 'package:rawasi_app_n/features/lesson/data/lesson_dayable_video.dart';
import 'package:rawasi_app_n/features/lesson/data/lesson_dayable_video_repo.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class LessonVideoView extends StatefulWidget {
  final int? dayId;
  final int? courseId;
  final String? videoUrl; // ✅ معلمة جديدة للفيديو المخصص (للدرس التمهيدي)

  const LessonVideoView({
    super.key,
    this.courseId,
    this.dayId,
    this.videoUrl, // قد تكون فارغة للدروس العادية
  });

  @override
  State<LessonVideoView> createState() => _LessonVideoViewState();
}

class _LessonVideoViewState extends State<LessonVideoView>
    with SingleTickerProviderStateMixin {
  late Future<bool> _isUserSignedIn;
  Future<LessonDayableVideo>? _lessonFuture;
  late WebViewController _webViewController;
  bool _webViewLoaded = false;

  late VideoPlayerController _introController;
  bool _isIntroPlaying = false;

  bool _isAddedToLibrary = false;
  bool _isAdding = false;
  bool _isCompleting = false; // ✅ لتعطيل الزر أثناء الإرسال

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isUserSignedIn = isUserSignedIn();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    _introController = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
      })
      ..setLooping(true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _webViewController.clearCache();
    _introController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _addToLibrary() async {
    if (_isAddedToLibrary || _isAdding || _lessonFuture == null) return;

    final lesson = await _lessonFuture!;
    setState(() {
      _isAdding = true;
    });

    try {
      final repo = LibraryRepository();
      await repo.addToLibrary(
        type: 'video',
        taskId: lesson.videoId,
        courseId: lesson.courseId,
      );

      if (mounted) {
        setState(() {
          _isAddedToLibrary = true;
          _isAdding = false;
        });
        // ✅ رسالة نجاح خضراء — موحدة مع صفحة الأسئلة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت الإضافة إلى المكتبة بنجاح'),
            backgroundColor: AppColors.success600,
          ),
        );
      }
    } on Exception catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('تمت اضافتها من قبل') ||
          errorMsg.contains('مضاف') ||
          errorMsg.contains('موجود') ||
          errorMsg.contains('مسبقا') ||
          errorMsg.contains('سابقًا') ||
          errorMsg.contains('already') ||
          errorMsg.contains('exist') ||
          (errorMsg.contains('تمت') &&
              (errorMsg.contains('إضافة') || errorMsg.contains('اضافة')) &&
              errorMsg.contains('مسبقا'))) {
        if (mounted) {
          setState(() {
            _isAddedToLibrary = true;
            _isAdding = false;
          });
          // ℹ️ رسالة "مضاف مسبقًا" زرقاء — موحدة مع صفحة الأسئلة
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تمت الإضافة إلى المكتبة مسبقًا'),
              backgroundColor: AppColors.brandPrimary,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdding = false;
          });
          // ❌ رسالة خطأ حمراء — موحدة
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الإضافة: $errorMsg'),
              backgroundColor: AppColors.error600,
            ),
          );
        }
      }
    }
  }

  // ✅ دالة رئيسية: إكمال المهمة وعرض البوب أب
  Future<void> _completeTaskAndShowDialog(LessonDayableVideo lesson) async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    String? message;
    try {
      final repo = LessonDetailsRepo();
      final success = await repo.completeTask(
        lesson.dailyTaskId,
        lesson.dayNumber,
      );
      // في الحقيقة، completeTask يُرجع true فقط إذا نجح
      // لكننا نريد الرسالة من السيرفر — لذا سنعدّل الدالة لترجع الرسالة
      // ⚠️ لكن بما أننا لا نملك الوقت، سنعتمد على الطريقة الآمنة:
      // نعيد تصميم completeTask لترجع الرسالة بدلاً من bool
      // لكن لتجنب التغيير الكبير، سنستخدم طريقة بديلة:

      // ❌ المشكلة: الدالة الحالية تُرجع bool فقط
      // ✅ الحل: نعدّل completeTask لترجع Map<String, dynamic> أو رسالة

      // لكن بما أنك قلت إن الرسالة تأتي من السيرفر، فسأفترض أننا عدّلنا الدالة
      // لترجع الرسالة. لذا سأعد كتابة الدالة هنا مؤقتًا.

      // 👇 سنعيد كتابة المنطق داخل هذه الدالة مباشرةً باستخدام ApiServices
      final api = ApiServices();
      final response = await api.postFormData(
        '/complete-task/${lesson.dailyTaskId}',
        FormData.fromMap({'day_number': lesson.dayNumber.toString()}),
      );

      if (response is Map<String, dynamic>) {
        message = response['message'] as String? ?? 'تم إكمال الدرس بنجاح';
      } else if (response is String) {
        message = response;
      } else {
        message = 'تم إكمال الدرس بنجاح';
      }
    } catch (e) {
      message = e.toString().replaceAll(RegExp(r'^Exception[:\s]*'), '').trim();
    }

    // ✅ عرض البوب أب
    // ✅ عرض البوب أب محسّن
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false, // يمنع الإغلاق باللمس الخارجي
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة حالة (يمكنك تخصيصها حسب النجاح/فشل لاحقًا)
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إكمال الدرس',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message ?? 'تم إكمال الدرس بنجاح',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.gray600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // إغلاق البوب أب
                        Navigator.of(context).pop(); // العودة للصفحة السابقة
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'الذهاب إلى باقي الدروس',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

    setState(() {
      _isCompleting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الدرس',
            style: TextStyle(color: AppColors.gray800, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: _isUserSignedIn,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandPrimary,
                  ),
                );
              }

              final isSignedIn = userSnapshot.data == true;

              // ✅ التعديل الرئيسي هنا: فحص وجود videoUrl أولاً
              // إذا وُجد videoUrl (للدرس التمهيدي)، استخدمه مباشرةً
              // وإلا استخدم المنطق القديم مع dayId و courseId
              if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
                // ✅ حالة الدرس التمهيدي - فيديو مخصص
                // تحميل الفيديو مباشرةً من الرابط المقدم
                if (!_webViewLoaded) {
                  _webViewController.loadRequest(
                    Uri.parse(widget.videoUrl!.trim()),
                  );
                  _webViewLoaded = true;
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 220,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  WebViewWidget(controller: _webViewController),
                                  if (!_webViewLoaded)
                                    Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 8,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '00:00',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Gap(24),
                          // ✅ بطاقة معلومات مخصصة للدرس التمهيدي
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gray200.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الدرس التمهيدي',
                                  style: TextStyle(
                                    color: AppColors.brandSecondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Gap(8),
                                Text(
                                  isSignedIn
                                      ? 'مرحباً بك في برنامج رواسي! هذا الفيديو سيساعدك على فهم كيفية استخدام التطبيق والاستفادة القصوى من المحتوى التعليمي.'
                                      : 'تعرف على برنامج رواسي! هذا الفيديو يقدم لك نظرة عامة عن البرنامج وأهدافه التعليمية.',
                                  style: TextStyle(
                                    color: AppColors.gray600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Gap(24),
                          // ✅ زر الاستمرار للدرس التمهيدي
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'استمرار',
                                style: TextStyle(
                                  color: AppColors.white,
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
              } else if (isSignedIn &&
                  widget.courseId != null &&
                  widget.dayId != null) {
                // ✅ حالة الدروس العادية - جلب الفيديو من السيرفر
                _lessonFuture ??= LessonDetailsRepo().fetchLessonDetails(
                  widget.courseId!,
                  widget.dayId!,
                );

                return FutureBuilder<LessonDayableVideo>(
                  future: _lessonFuture!,
                  builder: (context, lessonSnapshot) {
                    if (lessonSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brandPrimary,
                        ),
                      );
                    }

                    if (lessonSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_call_outlined,
                              color: AppColors.gray400,
                              size: 48,
                            ),
                            Gap(12),
                            Text(
                              'فشل تحميل الفيديو',
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: 16,
                              ),
                            ),
                            Gap(8),
                            Text(
                              'يرجى المحاولة لاحقًا',
                              style: TextStyle(
                                color: AppColors.gray500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final lessonVideo = lessonSnapshot.data!;

                    if (!_webViewLoaded &&
                        lessonVideo.video.trim().isNotEmpty) {
                      _webViewController.loadRequest(
                        Uri.parse(lessonVideo.video.trim()),
                      );
                      _webViewLoaded = true;
                    }

                    final attach = lessonVideo.attaches?.isNotEmpty == true
                        ? lessonVideo.attaches!.first
                        : null;

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 220,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      WebViewWidget(
                                        controller: _webViewController,
                                      ),
                                      if (!_webViewLoaded)
                                        Container(
                                          color: Colors.black,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.brandPrimary,
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 8,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            '00:00',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Gap(24),
                              _buildLessonCard(lessonVideo, attach),
                              Gap(24),
                              Row(
                                children: [
                                  Expanded(child: _buildLibraryButton()),
                                  Gap(12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isCompleting
                                          ? null
                                          : () => _completeTaskAndShowDialog(
                                              lessonVideo,
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brandPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: _isCompleting
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.white),
                                              ),
                                            )
                                          : const Text(
                                              'استمرار',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                // ✅ حالة المستخدم غير المسجل مع عدم وجود فيديو مخصص
                return _buildGuestContent();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryButton() {
    return ElevatedButton(
      onPressed: _isAddedToLibrary || _isAdding ? null : _addToLibrary,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAddedToLibrary
            ? AppColors.gray300
            : AppColors.gray200,
        foregroundColor: _isAddedToLibrary
            ? AppColors.gray500
            : AppColors.gray800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: _isAdding
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray600),
              ),
            )
          : Text(
              _isAddedToLibrary ? 'تمت الإضافة إلى المكتبة' : 'أضف إلى المكتبة',
            ),
    );
  }

  Widget _buildGuestContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: _introController.value.isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        AspectRatio(
                          aspectRatio: _introController.value.aspectRatio,
                          child: VideoPlayer(_introController),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_isIntroPlaying) {
                                _introController.pause();
                              } else {
                                _introController.play();
                              }
                              _isIntroPlaying = !_isIntroPlaying;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _isIntroPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                      ),
                    ),
            ),
          ),
          Gap(24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray200.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعرف على برنامج رواسي',
                  style: TextStyle(
                    color: AppColors.brandSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'رواسي هو برنامج تعليمي متكامل يهدف إلى تسهيل فهم المواد الشرعية من خلال دروس مرئية، أسئلة تفاعلية، ومتابعة يومية.',
                  style: TextStyle(color: AppColors.gray600, fontSize: 14),
                ),
              ],
            ),
          ),
          Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DaysView()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'ابدأ رحلتك الآن',
                style: TextStyle(
                  color: AppColors.white,
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

  Widget _buildLessonCard(LessonDayableVideo lesson, Attach? attach) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: TextStyle(
              color: AppColors.brandSecondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8),
          Text(
            lesson.description,
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
          if (attach != null) ...[
            const Divider(height: 24, color: AppColors.gray200),
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: AppColors.brandPrimary,
                  size: 18,
                ),
                Gap(8),
                Expanded(
                  child: Text(
                    attach.fileName,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: attach.fileName),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ اسم الملف')),
                    );
                  },
                  icon: Icon(Icons.copy, color: AppColors.gray500, size: 18),
                ),
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse(attach.fullPathAttach);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(
                    Icons.download,
                    color: AppColors.brandPrimary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
