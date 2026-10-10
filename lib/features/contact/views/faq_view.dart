// lib/features/contact/views/faq_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: CustomText(
          text: 'الأسئلة الشائعة',
          color: AppColors.gray900,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          itemCount: faqItems.length,
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) {
            final item = faqItems[index];
            return _FaqItem(
              question: item['question']!,
              answer: item['answer']!,
            );
          },
        ),
      ),
    );
  }
}

/// Q1's answer: the cumulative-study strategy (updated 2026-10-10).
///
/// A constant of its own because it is long and structured (numbered steps,
/// a closing line) - inline in the list it buried the other 20 entries.
const String _goldenStrategyAnswer =
    'لكي تستثمر نظام "رواسي" بأفضل طريقة ممكنة وتضمن "مذاكرة تراكمية حقيقية" تجعلك تسيطر على المنهج تماماً، اتبع هذه الاستراتيجية الذهبية بخطوات واضحة:\n\n'
    '1- تلقَّ الشرح أولاً: احصل على الشرح الأساسي من مصادرك الخارجية (سواء منصتك التعليمية، يوتيوب، أو السنتر).\n\n'
    '2- التجهيز الفوري للحل: توجه فوراً إلى التطبيق بعد كل درس لتبدأ حل الأسئلة والتدريبات وتنظيم دروسك داخل كل مادة حتى تمتلئ مكتبة المادة بالكامل.\n\n'
    '3- تصفية الأسئلة الصعبة: ادخل على مكتبة المادة وابدأ في حل وتدقيق الأسئلة؛ وكل سؤال تتقنه وتثبت إجابته قم بإزالته، وواصل حتى تفرغ مكتبة المادة تماماً من كل الأسئلة الصعبة التي تم إنجازها.\n\n'
    '4- تكرار الدورة (التدوير): بعد أن تفرغ مكتبة المادة تماماً، عد لدراسة دروس المادة من جديد في صفحة المواد الدراسية، وأنشئ مكتبة جديدة وأضف دروساً جديدة حتى تمتلئ مجدداً، وهكذا تكرر الدورة لكل مادة على حدة.\n\n'
    '5- الفرم النهائي: في النهاية، وبعد الانتهاء من المنهج بالكامل، ستجد أن ما تبقّى معك في المكتبة هو أصعب وأعقد الأسئلة التي شكلت عائقاً حقيقياً لك. قم بمراجعتها وطحنها حتى تختفي تماماً هي الأخرى.\n\n'
    'النتيجة؟\n'
    'أنت بكدا مش بتذاكر بالطريقة التقليدية، بل تطبق نظام "التراكمي الحقيقي" الذي يضمن لك تقفيل المواد الشرعية والقرآن الكريم بكل ثقة وأريحية تامة.';

/// The full FAQ shown in حسابي → الأسئلة الشائعة (21 items, 2026-10-04).
/// Replaces the old list entirely — that one described retired features
/// (videos, a 90-day plan, offline downloads).
@visibleForTesting
final List<Map<String, String>> faqItems = [
  {
    'question':
        'ما هي الاستراتيجية الذهبية لاستخدام التطبيق (طريقة رواسي لضمان تقفيل المواد الشرعية)؟',
    'answer': _goldenStrategyAnswer,
  },
  {
    'question': 'هل تطبيق رواسي بيغطي كل مواد الثانوية الأزهرية؟',
    'answer':
        'لا، رواسي بيغطي المواد الشرعية فقط بما فيها القرآن الكريم (لأولى وتانية والتالتة ثانوي أزهري)، وهي تمثل ثلث المجموع وتعتبر الكنوز الحقيقية للمجموع.',
  },
  {
    'question': 'هل رواسي بيخدم القسم العلمي والأدبي مع بعض؟',
    'answer':
        'نعم، التطبيق متاح للقسمين (العلمي والأدبي)، وفي الفقه يغطي المذهبين الحنفي والشافعي فقط. والجميل أن الطالب لن يظهر له إلا قسمه ومذهبه فقط لتسهيل التجربة ومنع أي تشتت.',
  },
  {
    'question': 'هل محتوى رواسي مطابق فعلاً للمنهج الرسمي؟',
    'answer':
        'نعم، محتوى التطبيق مصمم بدقة ليحاكي المنهج الرسمي ونظام "البوكلت" الأزهري، مع التركيز على الكلمات المفتاحية، نص الكتاب، والتفاصيل التي تأتي بين السطور لضمان الدرجة النهائية.',
  },
  {
    'question': 'هل التطبيق سهل الاستخدام ولا معقد؟',
    'answer':
        'التطبيق سهل جداً ومصمم خصيصاً لتخفيف التوتر عن الطالب؛ فقسم المواد الدراسية يرتب لك الدروس خطوة بخطوة (فتح متسلسل) لينهي حيرة "أبدأ منين؟".',
  },
  {
    'question': 'طب هل ينفع أذاكر في أي وقت يناسبني؟',
    'answer':
        'نعم، التطبيق يتيح لك تنظيم وقتك بنفسك، مما ينهي أزمة "اليوم المخروم" بين السناتر ويسمح لنا بالعمل العميق في أي وقت يناسبك.',
  },
  {
    'question': 'هل رواسي بيعتمد بس على الفيديوهات؟',
    'answer':
        'لا، رواسي لا يعتمد على الشرح النظري الطويل أو الفيديوهات المشتتة، بل ينطلق من قاعدة أساسية: "ذاكر الدرس عند أي مدرس، وتعالى حل عندنا"؛ فهو سيستم تدريبي متكامل يعتمد على الحل الإلزامي، الفلاش كاردز، و"المكتبة" التي تعد بنك أسئلتك الخاص.',
  },
  {
    'question': 'هل فيه خطة مذاكرة واضحة داخل التطبيق؟',
    'answer':
        'نعم، يوفر التطبيق سجلاً يومياً بمهام محددة للمواد الأساسية، بالإضافة إلى نظام "الفتح المتسلسل" الذي يفرض خطة مرتبة تمنع التراكم وتضمن هضم المنهج قطعة قطعة.',
  },
  {
    'question':
        'هل رواسي مناسب للطالب الذي ملتزم مع مدرس خصوصي بالفعل؟ (وهل هو بديل أم مكمل؟)',
    'answer':
        'رواسي مكمل ذكي وقوي جداً وليس ملغياً للمدرس؛ فهو لا يتعارض مع الشرح الخارجي، بل هو "محطة التدريب الإلزامي" التي تتأكد فيها من تثبيت المعلومة ومعرفة تريكات الامتحانات التي قد لا يتيحها وقت الحصة التقليدية.',
  },
  {
    'question': 'كيف يتابع التطبيق معدل تقدمي وإنجازي اليومي والأسبوعي؟',
    'answer':
        'يضم التطبيق قسماً شاملاً لـ "الإحصائيات" يعرض لك بدقة نسبة إتمامك للمنهج، ومدة مذاكرتك الإجمالية بالدقائق، وعدد الأيام المتتالية للمذاكرة، ومعدل الدروس المكتملة أسبوعياً مع توقع تاريخ إنهاء المنهج.',
  },
  {
    'question': 'ما هي ميزة "الأيام المتتالية" (Streak) وكيف تحفزني؟',
    'answer':
        'هي عداد يحسب عدد الأيام المتتالية التي تفتح فيها التطبيق وتدرس فيها يومياً، ويدعمك برسائل تحفيزية مستمرة (مثل: "يومان متتاليان - واصل، أنت في الطريق") لضمان الاستمرارية ومنع التسويف.',
  },
  {
    'question': 'هل أقدر احتفظ بالأسئلة التي صعب عليّ حلها في رواسي؟',
    'answer':
        'نعم، من خلال ميزة "المكتبة والمكتبة المخصصة"؛ فالمكتبة هي بنك أسئلتك الخاص، وأي سؤال يقع منك أو تحس إنه صعب، تحطه بضغطة زر فيها لتصنع بنك أسئلة خاص بك وحدك، وتفلتره بطريقة الفلاش كاردز.',
  },
  {
    'question': 'هل أستطيع استخراج الأسئلة المحفوظة في المكتبة في ملف خارجي؟',
    'answer':
        'نعم، يوفر التطبيق زر "استخراج PDF" داخل قسم المكتبة لكل مادة، مما يتيح لك تحويل بنك الأسئلة الخاص بك إلى ملف PDF وطباعته لمراجعته ورقياً في أي وقت.',
  },
  {
    'question': 'ما هي ميزة "ما المقصود" أو التوضيح الفوري أثناء حل الأسئلة؟',
    'answer':
        'أثناء الحل، يتيح لك التطبيق زر "ما المقصود" للاستفسار أو فهم المصطلحات، مع إمكانية تقييم إجابتك (سهل / جيد) لضبط خوارزميات التكرار المتباعد، وإمكانية إرسال ملاحظة أو استفسار عن السؤال للدعم الفني مباشرة.',
  },
  {
    'question': 'طب لو عندي مشكلة أثناء الحل أو مش فاهم نقطة معينة؟',
    'answer':
        'التطبيق يدعمك بمتابعة تقنية وبشرية؛ حيث تتدخل خدمة العملاء لمتابعة الطالب "بالاسم" في حال توقفه لتقديم الدعم النفسي والتوجيه الصحيح.',
  },
  {
    'question': 'هل التطبيق مناسب للطلاب الضعفاء؟',
    'answer':
        'نعم تماماً، التطبيق مصمم خصيصاً لينقذ الطالب من تراكمات "عقدة الذاكرة" و"تبخر المادة"؛ فمن خلال التكرار المتباعد ونظام التدريج بالحل، يبني معك القاعدة الصلبة حتى لو مستواك ضعيف لتصل للدرجة النهائية.',
  },
  {
    'question': 'ما هي ميزة "لوحة المتصدرين" (Leaderboard) في التطبيق؟',
    'answer':
        'هي لوحة منافسة تحفيزية تعرض ترتيبك بين زملائك الطلاب (مثل الأوائل في الصف الثالث الثانوي) بناءً على النقاط التي تجمعها من إتمام الدروس والحل المستمر، مما يرفع حماسك للمذاكرة والتفوق.',
  },
  {
    'question': 'إيه اللي يخليني أثق إن رواسي فعلاً هيفيدني؟',
    'answer':
        'لأنه مبني على تجربة حقيقية أثبتت نجاحها على أرض الواقع وحققت الدرجات النهائية، ولأنه يحل مشاكل حقيقية مثل "النسيان، فجوة البوكلت، وسحلة المواصلات".',
  },
  {
    'question': 'إيه الهدف النهائي من رواسي؟',
    'answer':
        'الهدف النهائي هو تحويل فهمك إلى درجات نهائية مضمونة في المواد الشرعية (وضمان ثلث المجموع وأنت حاطط رجل على رجل)، والقضاء تماماً على التوتر والتراكم وتسويف المذاكرة.',
  },
  {
    'question':
        'هل التكلفة كتير؟ (تكلفة الترم لأولى وتانية، والتكلفة الشهرية لتالتة؟)',
    'answer':
        'الاستثمار في "ضمان ثلث المجموع" وتوفير ساعات السناتر والمواصلات الثمينة يعتبر قيمة أعلى بكثير من التكلفة الرمزية (سواء كانت تكلفة الترم لأولى وتانية، أو التكلفة الشهرية لتالتة) مقارنة بالدروس التقليدية، مع العلم أن أول 15 يوماً مجاناً بالكامل لتجربة السيستم بنفسك!',
  },
  {
    'question':
        'إيه اللي يميز رواسي عن أي تطبيق تعليمي تاني وإزاي يساعدني أصل للدرجة النهائية؟',
    'answer':
        'ما يميز رواسي هو تخصصه الكامل لخدمة طالب الأزهر الشريف، ومعالجته المباشرة لـ "عقدة نص الكتاب"، وتطبيق "التكرار المتباعد" عبر الفلاش كاردز، ونظام "القفل والفتح المتسلسل" الذي يمنع الهروب والتراكم، فضلاً عن هندسة الإنجاز اليومي والتدريب المستمر على نظام البوكلت وأسئلة السنين لضمان تقفيل المواد الشرعية.',
  },
];

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _toggle,
        splashColor: AppColors.brandPrimary.withOpacity(0.1),
        highlightColor: AppColors.brandPrimary.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isExpanded
                ? AppColors.brandPrimary.withOpacity(0.04)
                : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded
                  ? AppColors.brandPrimary.withOpacity(0.3)
                  : AppColors.gray200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray200.withOpacity(_isExpanded ? 0.4 : 0.2),
                blurRadius: _isExpanded ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isExpanded
                            ? AppColors.brandPrimary
                            : AppColors.gray900,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded
                          ? AppColors.brandPrimary
                          : AppColors.gray500,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.gray700,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
