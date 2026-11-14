Brainly Life — Theme & UI Styling Guide

الهدف: توحيد شكل التطبيق في Light Mode وDark Mode، ومنع اختلاف الألوان والخطوط والمسافات من شاشة للتانية.

القاعدة الأساسية: استخدم الـTheme tokens الجاهزة. لا تكتب قيم تصميم ثابتة (Hardcoded values) داخل الشاشات أو الـWidgets.

1. ابدأ من هنا
الاستيراد
استخدم سطر الاستيراد ده في أي ملف يحتاج ألوان أو نصوص أو مسافات أو زوايا أو ظلال:
import 'package:brainly_life/core/theme/theme.dart';
اختار الـToken المناسب
لو محتاج... استخدم...
لون context.palette.surface أو اللون المناسب من context.palette
Text Style context.text.bodyMedium أو الـText Style المناسب
مسافة AppSpacing.s4 أو المسافة المناسبة
Corner Radius AppRadius.card أو النوع المناسب
Shadow AppShadows.card(context)
رقم كبير مثل عدد أيام الـStreak AppTextStyles.metricCounter

مهم: استخدم context داخل Widget عندك فيها BuildContext، مثل دالة build.
2. قواعد ممنوع كسرها
ممنوع كتابة القيم التالية مباشرة داخل كود الشاشات والـWidgets:
Colors.white
Color(0xFF6C5CE7)
TextStyle(fontSize: 16)
EdgeInsets.all(16)
BorderRadius.circular(20)
بدلًا منها استخدم الـTheme tokens:
context.palette.surface
context.palette.primary
context.text.bodyMedium
AppSpacing.s4
AppRadius.card
ليه بنلتزم بالقواعد دي؟

- تغيير الـTheme مرة واحدة ينعكس على كل الشاشات.
- Light Mode وDark Mode يشتغلوا من خلال context.palette من غير شروط متكررة.
- شكل التطبيق يفضل موحّد، والكود يبقى أسهل في التعديل والصيانة.
لو محتاج لون أو حجم أو Style مش موجود، ما تخترعش قيمة من عندك. اسأل المسؤول عن الـTheme لإضافة Token مناسب.

1. الألوان — context.palette
استخدم context.palette للوصول إلى ألوان التطبيق. الـPalette بتوفر اللون المناسب حسب الـTheme الحالي.
Token الاستخدام
background خلفية الشاشة الرئيسية
surface خلفية الـCard والـDialog
surfaceMuted خلفية الـInputs أو المساحات الهادئة
textPrimary النص الأساسي والعناوين
textSecondary النصوص الثانوية، الوقت، والوصف
primary اللون الأساسي، الروابط، والعناصر المختارة
border حدود الـCards والفواصل
success نص أو أيقونة حالة النجاح
warning نص أو أيقونة التحذير
error نص أو أيقونة الخطأ
info نص أو أيقونة المعلومات
successSoft خلفية هادئة لحالة النجاح أو Chip
warningSoft خلفية هادئة للتحذير
errorSoft خلفية هادئة للخطأ
infoSoft خلفية هادئة للمعلومات
teal عناصر التركيز والعادات
tealStrong استخدام أقوى للـTeal عند الحاجة

مثال: Error Chip
final p = context.palette;

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.s2,
    vertical: AppSpacing.s1,
  ),
  decoration: BoxDecoration(
    color: p.errorSoft,
    borderRadius: BorderRadius.circular(AppRadius.pill),
  ),
  child: Text(
    'Overdue',
    style: context.text.labelMedium?.copyWith(color: p.error),
  ),
)
استخدمنا AppSpacing.s2 و`AppSpacing.s1` بدل أرقام ثابتة للمسافات؛ حتى يفضل الكود ملتزمًا بنفس نظام التصميم.

1. النصوص — context.text
اختار Text Style حسب وظيفة النص، مش حسب الحجم اللي يبدو مناسبًا في اللحظة.
Text Style الاستخدام
headlineLarge عنوان الشاشة الرئيسي
headlineMedium عنوان Section
headlineSmall عنوان Card
bodyLarge نص مهم أو بارز
bodyMedium النص العادي
bodySmall وصف أو تفاصيل ثانوية
labelMedium Chips وBadges
labelSmall الوقت والملاحظات الصغيرة
AppTextStyles.metricCounter الأرقام الكبيرة، مثل Streak وعدد الساعات

مثال: نص ثانوي
Text(
  '3 tasks left',
  style: context.text.bodyMedium?.copyWith(
    color: context.palette.textSecondary,
  ),
)
النصوص بتستخدم ألوان الـTheme تلقائيًا. غيّر اللون فقط لما تكون الوظيفة محتاجة لونًا مختلفًا، مثل النص الثانوي أو حالة الخطأ.
مثال: رقم إحصائي
Text(
  '12',
  style: AppTextStyles.metricCounter,
)
5. المسافات — AppSpacing
استخدم المسافات الجاهزة بدل كتابة أرقام مباشرة داخل EdgeInsets أو SizedBox أو أي Layout.
Token القيمة
AppSpacing.s1 4
AppSpacing.s2 8
AppSpacing.s3 12
AppSpacing.s4 16
AppSpacing.s5 20
AppSpacing.s6 24
AppSpacing.s8 32
AppSpacing.screenMargin 20
AppSpacing.cardGap 16
AppSpacing.cardPadding 20

أمثلة
// مسافة رأسية بين عنصرين
const SizedBox(height: AppSpacing.s2)

// Padding داخل Card
const EdgeInsets.all(AppSpacing.cardPadding)

// هوامش الشاشة
const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin)
استخدم الـToken الأقرب للغرض. مثلًا: screenMargin لهوامش الشاشة، و`cardPadding` للمساحة الداخلية للـCard.
6. الزوايا والأحجام — AppRadius و`AppSizes`
Corner Radius
Token الاستخدام
AppRadius.card زوايا الـCards
AppRadius.input زوايا حقول الإدخال
AppRadius.button زوايا الأزرار
AppRadius.pill Chips وBadges الدائرية

أحجام العناصر
Token القيمة الاستخدام
AppSizes.primaryButtonHeight 52 ارتفاع الزر الأساسي
AppSizes.minTouchTarget 48 أقل مساحة تفاعل للمس

مثال:
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.card),
  ),
)
7. الظلال — AppShadows
استخدم الـShadow الجاهز بدل إنشاء BoxShadow مختلف في كل Widget.
boxShadow: AppShadows.card(context),
مثال استخدامه داخل BoxDecoration موجود في مثال الـCard الكامل بالأسفل.
8. ألوان المواد — AppColors
لكل مادة لون مخصص. استخدم اللون مع اسم المادة كنص؛ لا تعتمد على اللون وحده لتمييز المادة.

المواد المتاحة:

- biology
- mathematics
- physics
- personal
- rewards
طريقة الاستخدام
// اللون الأساسي للمادة
AppColors.biology.accent

// خلفية مناسبة للمادة حسب Light أو Dark Mode
AppColors.biology.surfaceFor(
  Theme.of(context).brightness,
)
مثال داخل Widget:
final subjectColor = AppColors.biology.accent;
final subjectSurface = AppColors.biology.surfaceFor(
  Theme.of(context).brightness,
);

Container(
  color: subjectSurface,
  child: Text(
    'Biology',
    style: context.text.labelMedium?.copyWith(color: subjectColor),
  ),
)
عند عرض مادة دراسية، اكتب اسمها دائمًا، مثل Biology أو Mathematics، بجانب اللون.
9. مثال كامل — Card
استخدم المثال ده كمرجع عند بناء Card جديدة:
import 'package:flutter/material.dart';
import 'package:brainly_life/core/theme/theme.dart';

class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: p.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '3 tasks left',
            style: context.text.bodyMedium?.copyWith(
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
لاحظ: الـ`Container` هنا مش const؛ لأنه بيستخدم ألوان وShadow معتمدين على context.
10. أخطاء شائعة — قبل ما تعمل Commit
❌ تجنّب ✅ استخدم
Colors.white context.palette.surface
Color(0xFF6C5CE7) context.palette.primary
TextStyle(fontSize: 14) context.text.bodyMedium أو الـStyle المناسب
EdgeInsets.all(16) EdgeInsets.all(AppSpacing.s4)
BorderRadius.circular(20) BorderRadius.circular(AppRadius.card)
كتابة ألوان مختلفة يدويًا للفاتح والدارك context.palette
إنشاء Shadow مختلف داخل كل Card AppShadows.card(context)
تمييز المادة باللون فقط اسم المادة + لونها

هل أحتاج أكتب شرطًا للـDark Mode؟
في الاستخدام العادي للألوان، لا. استخدم:
final p = context.palette;

Container(color: p.surface)
الـPalette تختار اللون المناسب حسب الـTheme الحالي. لا تكتب if (isDark) ... else ... لمجرد تغيير لون الشاشة أو الـCard.

الاستثناء الموجود في هذا الدليل هو ألوان المواد، لأنها تستخدم surfaceFor(Theme.of(context).brightness) بالطريقة الموضحة في القسم السابق.
11. Checklist قبل تسليم أي شاشة
راجع النقاط دي قبل ما تعمل Commit:

- [ ] أضفت import الخاص بالـTheme.
- [ ] استخدمت context.palette للألوان.
- [ ] استخدمت context.text للنصوص.
- [ ] استخدمت AppSpacing للمسافات.
- [ ] استخدمت AppRadius للزوايا.
- [ ] استخدمت AppShadows للظلال عند الحاجة.
- [ ] لم أكتب Colors.white أو Color(0xFF...) داخل الشاشة أو الـWidget.
- [ ] لم أكتب fontSize أو مسافات أو زوايا ثابتة بدل الـTokens.
- [ ] راجعت الشاشة في Light Mode وDark Mode.
- [ ] ألوان المواد مصحوبة باسم المادة كنص.

1. لو Token ناقص
لو احتجت لونًا أو حجمًا أو Text Style مش موجود في الـTheme:
1. ما تضيفش قيمة ثابتة داخل الشاشة كحل مؤقت.
1. ابعت اسم العنصر واستخدامه والمسافة/اللون المطلوب وظيفيًا.
1. اطلب إضافة Token مركزي في ملفات الـTheme.
1. بعد إضافته، استخدم الـToken الجديد في كل الأماكن المطلوبة.
الهدف النهائي: أي تعديل في الهوية البصرية يحصل من مكان مركزي واحد، وكل شاشات Brainly Life تفضل متناسقة في Light Mode وDark Mode.
