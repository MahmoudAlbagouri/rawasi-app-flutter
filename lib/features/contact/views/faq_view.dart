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
          itemCount: _faqData.length,
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) {
            final item = _faqData[index];
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

final List<Map<String, String>> _faqData = [
  {
    'question': 'هل تطبيق رواسي بيغطي كل مواد الثانوية الأزهرية؟',
    'answer':
        'لا، رواسي بيركز فقط على المواد الشرعية. إحنا شايفين إن الطالب الأزهري مشكلته الأساسية مش في المواد الشرعية نفسها، لكن في إنه مش قادر يوفق بين المواد الشرعية وباقي المواد. علشان كده وفرنا حل كامل للمواد الشرعية يخلي الطالب يركز وقته على باقي المواد براحة.',
  },
  {
    'question': 'إيه اللي يميز رواسي عن أي تطبيق تعليمي تاني؟',
    'answer':
        'الميزة إن رواسي أول تطبيق معمول مخصوص لطلاب الثانوية الأزهرية الشرعي. مفيش تطبيق تاني بيجمع فيديو + أسئلة + متابعة + تحميل فيديوهات أوفلاين على التطبيق. كمان التطبيق بيساعدك تنظم وقتك، والدروس متقسمة في خطة واضحة: ما تقدرش تفتح الدرس اللي بعده غير لما تخلص اللي قبله ✅. ده بيخليك ما تسيبش فراغات في المنهج ودا كلوا غير الدعم الفني.',
  },
  {
    'question': 'إزاي رواسي يساعدني أوصل للدرجة النهائية؟',
    'answer':
        'رواسي مش بس بيشرح الدروس، لكن كمان بيقسملك الدورة الأولى على 90 يوم، بحيث كل يوم تعرف تعمل إيه. الطالب مش هيتخبط بين المواد، كل حاجة مترتبة.',
  },
  {
    'question': 'طب لو أنا ضعيف جدًا في المواد الشرعية، التطبيق هينفعني؟',
    'answer':
        'أكيد، لأن رواسي مش بيعتبر إن الشرعي صعب، لكن بيعتبر إن المشكلة في التنظيم. فإحنا بنبدأ معاك خطوة بخطوة، من أول الدرس الأول لحد آخر المنهج، بنظام متدرج وأسئلة بترسخ المعلومة. مع التكرار والمراجعة المنظمة هتلاقي نفسك متقن حتى لو كنت ضعيف.',
  },
  {
    'question': 'هل رواسي بديل حقيقي للدروس الخصوصية؟',
    'answer':
        'أيوه ✅. الفرق الكبير بين رواسي والدروس الخصوصية إنك في التطبيق هتذاكر بنفسك بشكل عملي. إزاي؟\n\nكل سؤال بتحله تقدر تخليه يتعاد تاني في نفس اليوم او يوم تاني او ميتعدش تاني.\n\nعندك أدوات قوية تساعدك تراجع على نقاط ضعفك باستمرار.\n\nمش هتحتاج تروح دروس، كل حاجة متاحة على موبايلك.\n\nوده كله بسعر 300 جنيه في الشهر، وده أقل من تكلفة الدروس الخصوصية أو حتى الكتب الخارجية.',
  },
  {
    'question': 'هل رواسي بيخدم القسم العلمي والأدبي مع بعض؟',
    'answer':
        'أيوه، لكن بذكاء. الطالب العلمي مش هيظهر له غير محتوى الشرعي المخصص للعلمي، والطالب الأدبي نفس الكلام. يعني مش هتحتار أو تشوف حاجات مش ليك. كل طالب بيلاقي منهجه فقط، وده بيسهل عليه التركيز ويوفر وقت كبير.',
  },
  {
    'question': 'هل رواسي بديل للمدرس الخصوصي ولا مكمل ليه؟',
    'answer':
        'رواسي في الأساس بديل قوي جدًا للمدرس الخصوصي، لأن المحتوى متكامل ومقدَّم من مدرسين متخصصين في الأزهر. لكن في نفس الوقت، لو الطالب ملتزم مع مدرس خارجي، يقدر يستخدم رواسي كمكمل ممتاز، علشان يذاكر، يراجع، يحل أسئلة، ويقيس نفسه. يعني رواسي مرن، ينفع كبديل كامل أو كمكمل داعم.',
  },
  {
    'question': 'هل محتوى رواسي مطابق فعلًا للمنهج الرسمي؟',
    'answer':
        'أيوه ✅. كل حاجة في رواسي مبنية على كتاب المدرسة الرسمي، ومنقّحة. يعني الطالب مش هيذاكر أي حاجة برا المنهج، ومش هيتشتت بمعلومات ملهاش لازمة. هدفنا إنك تكون مستعد 100% للامتحان الرسمي.',
  },
  {
    'question': 'إيه اللي يخليني أثق إن رواسي فعلاً هيفيدني؟',
    'answer':
        'لأن رواسي معمول مخصوص لمشكلتك كطالب أزهري:\n\nالدروس متقسمة بخطة واضحة، ما ينفعش تتخطى درس غير لما تخلص اللي قبله.\n\nالتطبيق بيركز على المواد الشرعية فقط، اللي بتاخد وقت كبير منك وبتخليك مش عارف توازن بينها وباقي المواد.\n\nفيه متابعة مستمرة + نظام أسئلة بيراجعك على طول.\n\nيعني مش مجرد فيديوهات، لكن نظام كامل يخليك تذاكر وتراجع وتثبت المعلومة.',
  },
  {
    'question': 'هل فيه خطة مذاكرة واضحة داخل التطبيق؟',
    'answer':
        'أيوه. رواسي مش مجرد شرح وخلاص، لكنه بيديك خطة يومية لمدة حوالي 90 يوم. كل يوم عارف بالضبط إيه اللي عليك، وده بيخليك ما تضيعش وقت في التفكير "أبدأ منين؟". ودي حاجة بتفرق جدًا مع الطالب الأزهري اللي وقته ضيق.',
  },
  {
    'question': 'هل التطبيق فيه امتحانات بعد كل درس؟',
    'answer':
        'بالطبع ✅. بعد كل جزء فيه مجموعة أسئلة تساعدك تثبت المعلومة. بحيث تكون دخلت الامتحان الحقيقي وإنت متعود وحافظ النظام.',
  },
  {
    'question': 'طب لو عندي مشكلة أثناء المذاكرة أو مش فاهم نقطة معينة؟',
    'answer':
        'مش هتكون لوحدك. فيه خدمة عملاء بترد عليك وبتساعدك لو واجهت أي مشكلة. يعني أي سؤال أو استفسار هتلاقي حد يجاوبك، وكأن معاك مدرس دايمًا في جيبك.',
  },
  {
    'question': 'هل التطبيق مناسب للطلاب الضعاف؟',
    'answer':
        'أيوه ✅. رواسي بيعتبر إن المشكلة الأساسية مش في صعوبة الشرعي، لكن في إن الطالب مش منظم. التطبيق بيمشيك خطوة بخطوة، بأسئلة من السهل للصعب، ومع نظام تكرار ذكي. حتى لو بدأت ضعيف، هتلاقي نفسك مع الوقت بقيت متقن.',
  },
  {
    'question': 'هل ينفع أذاكر أوفلاين من غير إنترنت؟',
    'answer':
        'أيوه. تقدر تحمّل الفيديوهات وتذاكر من غير إنترنت لكن على التطبيق. ودي نقطة مهمة جدًا للطلاب اللي النت عندهم ضعيف أو مش متوفر طول الوقت.',
  },
  {
    'question': 'هل التطبيق سهل الاستخدام ولا معقد؟',
    'answer':
        'التطبيق بسيط جدًا. معمول مخصوص للطلاب، بحيث أي حد يقدر يتعامل معاه بسهولة حتى لو ما عندوش خبرة كبيرة بالتكنولوجيا. كل حاجة واضحة: دروس – أسئلة – تقدمك اليومي.\nغير أنه يوجد فيديو في واجهة التطبيق يشرح التطبيق بالتفاصيل.',
  },
  {
    'question': 'طب هل ينفع أذاكر في أي وقت يناسبني؟',
    'answer':
        'طبعًا ✅. التطبيق متاح 24 ساعة. يعني لو بتحب تذاكر الصبح أو حتى بالليل، تفتح وتكمل براحتك. مفيش مواعيد ثابتة زي الدروس الخصوصية لكن يجب الإنتهاء من تاسكك اليوم قبل دخول اليوم التالي.',
  },
  {
    'question': 'هل رواسي بيعتمد بس على الفيديوهات؟',
    'answer':
        'لأ، ودي أهم نقطة. رواسي مش مجرد فيديوهات شرح. لكن:\n\n- فيديو حل أسئلة.\n- أسئلة مباشرة بعد الدروس.\n- أسئلة مباشرة تراكمية على جميع ما سبق.\n- إعادة للأسئلة اللي لخبطت فيها حتى بعد أيام.\n- خطة واضحة ما ينفعش تتخطى درس غير لما تخلص اللي قبله.\n\nيعني نظام كامل متكامل مش مجرد مشاهدة.',
  },
  {
    'question': 'هل تكلفة 300 جنيه في الشهر كتير؟',
    'answer':
        'بالعكس. لو قارنت هتلاقي إن:\n\nالدروس الخصوصية والكتب الخارجية بتكلفك آلاف الجنيهات ومفيهاش مميزات رواسي.\n\nالكتب الخارجية برضه سعرها مش قليل.\n\nلكن رواسي بيجمعلك شرح + خطة + امتحانات + متابعة، وكل ده بـ 300 جنيه شهريًا فقط.',
  },
  {
    'question': 'هل رواسي مناسب للطالب اللي ملتزم مع مدرس خصوصي بالفعل؟',
    'answer':
        'أيوه. رواسي بديل كامل للمدرس الخصوصي. لكن لو الطالب حابب يكمل مع مدرس خارجي، رواسي هيكون مكمل قوي جدًا. لأنه بيخلي الطالب يذاكر ويعيد على نفسه منظم، وبيساعده يحل أسئلة وامتحانات بشكل يومي.',
  },
  {
    'question': 'إيه الهدف النهائي من رواسي؟',
    'answer':
        'الهدف ببساطة: إنك توصل للدرجة النهائية في المواد الشرعية. رواسي بيخليك:\n\n- تذاكر بخطة واضحة من غير ما تضيع وقت.\n- تفهم وتثبت المعلومة بأسئلة منظمة.\n- تخرج من السنة مطمئن إن الشرعي مضمون ✅، وتدي باقي وقتك لباقي المواد.\n\nلازم تعرف إن المواد الشرعية عليها تلت المجموع النهائي.',
  },
  {
    'question': 'هل أقدر أحتفظ بالأسئلة اللي بصعب عليّ حلها في رواسي؟',
    'answer':
        'نعم، يقدر الطالب يحدد أي سؤال إنه صعب، والسؤال ده يتعاد عليه أكتر من مرة تلقائيًا، وكمان يقدر يضيفه لمكتبته الخاصة علشان يرجع له في أي وقت ويراجعه لحد ما المعلومة تثبت.',
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
