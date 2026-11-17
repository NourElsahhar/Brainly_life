# core/

الأدوات المشتركة اللي كل الفريق بيستخدمها. **مسؤول عنها: M1.**
محتاج حاجة جديدة هنا؟ كلّم M1، وماتكتبش نسختك من عندك.
(`core/ai` بتاعة M5.)

| الفولدر | فيه إيه | الشرح |
| --- | --- | --- |
| `theme/` | الألوان والنصوص والمسافات | [theme/README.md](theme/README.md) |
| `widgets/` | الـ widgets المشتركة | تحت |
| `errors/` | `Failure` و`Result` و`FirebaseErrorMapper` | تحت |
| `utils/` | التواريخ والـ validation والـ logging | تحت |

## الـ Widgets

```dart
import 'package:brainly_life/core/widgets/widgets.dart';
```

### AppButton

```dart
AppButton(label: 'Save', onPressed: _save)
AppButton(label: 'Save', isLoading: state is Submitting, onPressed: _save)
AppButton(label: 'Cancel', type: AppButtonType.secondary, onPressed: _cancel)
AppButton(label: 'Delete', type: AppButtonType.destructive, onPressed: _delete)
AppButton(label: 'Add', icon: Icons.add, expanded: false, onPressed: _add)
```

الأنواع: `primary` (الأساسي، مرة واحدة في الشاشة) و`secondary` و`text` و`destructive`.
`onPressed: null` = الزرار معطّل. `isLoading: true` = spinner وبيتجاهل الضغط.

### AppTextField

```dart
AppTextField(
  label: 'Email',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.mail_outline,
  errorText: state.emailError,        // تحت الحقل، مش snackbar
  onChanged: cubit.emailChanged,
)
AppTextField(label: 'Password', obscureText: true)     // فيه زرار إظهار
AppTextField(label: 'Notes', maxLines: 4, maxLength: 1000)
```

### AppCard

```dart
AppCard(child: Text('Hello'))
AppCard(compact: true, child: ...)             // padding أصغر
AppCard(onTap: () => context.push('/tasks'), child: ...)
```

### LoadingView و ErrorView و EmptyView

```dart
const LoadingView()
const LoadingView(message: 'Generating your plan...')

ErrorView(failure: state.failure, onRetry: cubit.load)

EmptyView(
  icon: Icons.menu_book_outlined,
  title: 'Add your first subject',
  message: 'Subjects help us build your study plan.',
  actionLabel: 'Add subject',          // الزرار اختياري
  onAction: _addSubject,
)
```

كل شاشة لازم تتعامل مع: loading و empty و error و loaded.

### ConfirmDialog و AppSnackBar

```dart
final ok = await ConfirmDialog.show(
  context,
  title: 'Delete task?',
  message: 'This cannot be undone.',
  confirmLabel: 'Delete',
  isDestructive: true,
);
if (ok) cubit.deleteTask(id);

AppSnackBar.success(context, 'Task saved');
AppSnackBar.error(context, failure.userMessage);
AppSnackBar.info(context, 'Task deleted', actionLabel: 'Undo', onAction: cubit.undo);
```

استدعي `AppSnackBar` من `BlocListener` مش من `build()`. أخطاء الفورم تظهر تحت الحقل مش هنا.

### PriorityChip

```dart
PriorityChip(level: PriorityLevel.high)                         // عرض بس
PriorityChip(
  level: level,
  selected: level == state.priority,
  onTap: () => cubit.priorityChanged(level),                    // اختيار في فورم
)
```

`PriorityLevel` للـ UI بس. حوّله لـ enum الموديل بتاعك.

### DateTimePickerField

```dart
DateTimePickerField(
  label: 'Due date',
  mode: DateTimePickerMode.dateTime,     // date | time | dateTime
  value: state.dueAt,
  errorText: state.dueAtError,
  firstDate: DateTime.now(),             // اختياري
  clearable: true,                       // اختياري، onChanged بياخد null
  onChanged: cubit.dueAtChanged,
)
```

القيمة بتوقيت الجهاز. حوّلها `toUtc()` وقت التخزين و`toLocal()` وقت العرض.

### ColorPickerRow

```dart
ColorPickerRow(
  label: 'Color',
  selectedColorValue: state.colorValue,  // int?
  onChanged: cubit.colorChanged,
)
Color(subject.colorValue)                // التحويل للون
```

## الأخطاء: Failure و Result

```dart
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
```

الـ Repository مايرميش exception للـ Cubit، بيرجّع `Result`:

```dart
Future<Result<List<Task>>> getTasks() async {
  try {
    final tasks = await dataSource.getTasks();
    return Result.success(tasks);
  } catch (e) {
    return Result.failure(FirebaseErrorMapper.map(e));
  }
}
```

الـ Cubit:

```dart
final result = await repository.getTasks();
result.fold(
  onSuccess: (tasks) => emit(TaskListLoaded(tasks)),
  onFailure: (failure) => emit(TaskListError(failure)),
);
```

الشاشة تعرض `failure.userMessage`، ومتعرضش نص الـ exception أبدًا.
الأنواع: `NetworkFailure` و`AuthFailure` و`PermissionFailure` و`NotFoundFailure` و`ValidationFailure` و`AiFailure` و`UnknownFailure`.
الكود الأصلي من Firebase موجود في `failure.code` (مثلًا `requires-recent-login`).

## الأدوات: utils

```dart
import 'package:brainly_life/core/utils/utils.dart';
```

### التواريخ

```dart
final tz = settings.timezone;                                // 'Africa/Cairo'
DateKeyUtils.todayKey(timezone: tz);                         // '2026-11-16'
DateKeyUtils.toDateKey(task.dueAt, timezone: tz);
DateKeyUtils.addDays('2026-11-30', 1);                       // '2026-12-01'
WeekUtils.weekDateKeys(today, weekStartDay: day);            // 7 أيام
WeekUtils.weekKey(today, weekStartDay: day);                 // '2026-W47'

final r = DateKeyUtils.dayBounds(key, timezone: tz);         // أو WeekUtils.weekBounds
.where('dueAt', isGreaterThanOrEqualTo: r.start)
.where('dueAt', isLessThan: r.end)                           // النهاية مش داخلة
```

لحظة بالظبط = Timestamp UTC. يوم كامل = `dateKey`.
ممنوع `DateTime.now()` في الـ logic. استخدم `clock.now()`، وفي الاختبارات `withClock(Clock.fixed(...), () {...})`.

### Validators

```dart
final error = Validators.email(email);                        // null = تمام
Validators.password(password);                                // 8 حروف على الأقل
Validators.confirmPassword(confirm, password);
Validators.lengthBetween(name, min: 1, max: 60, fieldName: 'Name');
Validators.firstError([Validators.nonEmpty(t), Validators.maxLength(t, 100)]);
```

### Debouncer و AppLogger

```dart
final _debouncer = Debouncer();
_debouncer.run(() => _search(text));          // بعد 400ms من آخر حرف
_debouncer.dispose();                          // في close() الخاص بالـ Cubit

AppLogger.error('Could not save', tag: 'Tasks', error: e, stackTrace: s);
```

ممنوع `print`. وممنوع تسجّل بيانات شخصية (إيميل، اسم، uid، نص مهام أو رسائل أو prompts).
