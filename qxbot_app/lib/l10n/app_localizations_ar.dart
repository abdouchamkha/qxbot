// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'QXBot';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabSignals => 'الإشارات';

  @override
  String get tabLive => 'مباشر';

  @override
  String get tabStats => 'الإحصائيات';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get demo => 'تجريبي';

  @override
  String get real => 'حقيقي';

  @override
  String get call => 'شراء';

  @override
  String get put => 'بيع';

  @override
  String get win => 'ربح';

  @override
  String get loss => 'خسارة';

  @override
  String get draw => 'تعادل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loginTitle => 'تسجيل الدخول إلى Quotex';

  @override
  String get loginHelp =>
      'سجّل الدخول ببريدك الإلكتروني وكلمة المرور في Quotex (وأدخل الرمز المرسل إلى بريدك إن طُلب منك). يكمل التطبيق تلقائيًا بعد الدخول.';

  @override
  String get reload => 'إعادة التحميل';

  @override
  String get pasteToken => 'لصق رمز الجلسة';

  @override
  String get sessionToken => 'رمز الجلسة';

  @override
  String get use => 'استخدام';

  @override
  String get connection => 'الاتصال';

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'جارٍ الاتصال...';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get connectFailedStatus => 'انتهت الجلسة أو لا يوجد اتصال';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String clockCorrected(String offset) {
    return 'فرق الساعة مع Quotex: $offset ث (مُصحَّح)';
  }

  @override
  String get clockNotVerified =>
      'فرق الساعة مع Quotex: غير مُتحقَّق منه (تُستخدم ساعة الهاتف)';

  @override
  String get balance => 'الرصيد';

  @override
  String todaySummary(String net, String wins, String losses, String draws) {
    return 'اليوم $net · $wins ربح · $losses خسارة · $draws تعادل';
  }

  @override
  String get demoAccountSwitch => 'الحساب التجريبي (أموال للتدريب)';

  @override
  String get realTitle => 'التحويل إلى الحساب الحقيقي؟';

  @override
  String get realBody =>
      'ستُنفَّذ الصفقات برصيدك الحقيقي في Quotex. والخسائر ستكون حقيقية.';

  @override
  String get useReal => 'استخدام الحساب الحقيقي';

  @override
  String get bot => 'الروبوت';

  @override
  String runningWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يعمل · $count إشارة في الانتظار',
      few: 'يعمل · $count إشارات في الانتظار',
      two: 'يعمل · إشارتان في الانتظار',
      one: 'يعمل · إشارة واحدة في الانتظار',
      zero: 'يعمل · لا توجد إشارات في الانتظار',
    );
    return '$_temp0';
  }

  @override
  String get stopped => 'متوقف';

  @override
  String get stop => 'إيقاف';

  @override
  String get pasteSignals => 'لصق الإشارات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get signalsHint =>
      'الصق قائمة إشارات تيليجرام هنا\nمثال: M1 EURUSD-OTC 14:30 CALL';

  @override
  String get pasteFromClipboard => 'لصق';

  @override
  String listTimezone(String tz) {
    return 'توقيت القائمة: $tz (من الإعدادات؛ وإذا كُتب في القائمة توقيت مثل \"UTC+6\" فهو المعتمد)';
  }

  @override
  String get notConnectedNames => 'غير متصل: لم يتم التحقق من أسماء الأزواج';

  @override
  String signalsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count إشارة',
      few: 'تم العثور على $count إشارات',
      two: 'تم العثور على إشارتين',
      one: 'تم العثور على إشارة واحدة',
      zero: 'لم يتم العثور على إشارات',
    );
    return '$_temp0';
  }

  @override
  String minutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دقيقة',
      few: '$n دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String seconds(int n) {
    return '$n ثانية';
  }

  @override
  String get pairNotFound => 'الزوج غير موجود في Quotex: سيتم تجاهل هذا السطر';

  @override
  String get connectFirst => 'اتصل أولاً';

  @override
  String startTrading(int count) {
    return 'ابدأ التداول ($count)';
  }

  @override
  String scheduled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت جدولة $count إشارة',
      few: 'تمت جدولة $count إشارات',
      two: 'تمت جدولة إشارتين',
      one: 'تمت جدولة إشارة واحدة',
      zero: 'لم تتم جدولة أي إشارة',
    );
    return '$_temp0';
  }

  @override
  String get stopBot => 'إيقاف الروبوت';

  @override
  String waiting(int count) {
    return 'في الانتظار ($count)';
  }

  @override
  String get log => 'السجل';

  @override
  String get logEmpty => 'لا شيء بعد';

  @override
  String get thisSession => 'هذه الجلسة';

  @override
  String get today => 'اليوم';

  @override
  String allTime(String account) {
    return 'منذ البداية ($account)';
  }

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get winRate => 'نسبة النجاح';

  @override
  String get trades => 'الصفقات';

  @override
  String get wld => 'ربح / خسارة / تعادل';

  @override
  String get signalsWon => 'إشارات رابحة';

  @override
  String get wonAfterGale => 'رابحة بعد المضاعفة';

  @override
  String get maxDrawdown => 'أقصى تراجع';

  @override
  String get worstStreak => 'أسوأ سلسلة خسائر';

  @override
  String lossesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n خسارة',
      few: '$n خسائر',
      two: 'خسارتان',
      one: 'خسارة واحدة',
      zero: 'لا خسائر',
    );
    return '$_temp0';
  }

  @override
  String get recentTrades => 'آخر الصفقات';

  @override
  String get noTrades => 'لا توجد صفقات بعد';

  @override
  String get entryPending => 'معلقة';

  @override
  String get entryDirect => 'مباشرة';

  @override
  String galeTag(String level) {
    return 'مضاعفة $level';
  }

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get stopToChange => 'أوقف الروبوت لتغيير الإعدادات';

  @override
  String get amountLabel => 'مبلغ الصفقة (\$)';

  @override
  String get amountHelp => 'المبلغ لكل إشارة';

  @override
  String get tzLabel => 'توقيت قائمة الإشارات (بساعات UTC)';

  @override
  String get tzHelp =>
      'مثال: ‎-3 لتوقيت UTC-3، و 1 لتوقيت الجزائر، و 5.5 لتوقيت UTC+5:30';

  @override
  String get galesLabel => 'عدد مستويات المضاعفة';

  @override
  String get offHelp => '0 = معطّل';

  @override
  String get multLabel => 'معامل المضاعفة';

  @override
  String get multHelp => 'المبلغ التالي = المبلغ × هذا المعامل';

  @override
  String get minPayoutLabel => 'أدنى نسبة ربح (%)';

  @override
  String get minPayoutHelp => 'تجاهل الإشارة إذا كانت نسبة الربح أقل';

  @override
  String get stopLossLabel => 'حد الخسارة اليومي (\$)';

  @override
  String get takeProfitLabel => 'هدف الربح اليومي (\$)';

  @override
  String get pendingTitle => 'صفقات معلقة لأزواج OTC';

  @override
  String get pendingSub =>
      'تفتح Quotex الصفقة بنفسها في الدقيقة المحددة تمامًا';

  @override
  String get overlapTitle => 'السماح بتداخل الإشارات';

  @override
  String get overlapSub =>
      'عند التعطيل: إشارة واحدة في الدقيقة، وإشارة القائمة لها الأولوية على المضاعفة';

  @override
  String get autoTiming => 'توقيت الدخول التلقائي';

  @override
  String get autoTimingSub =>
      'إرسال الصفقات المباشرة قبل بداية الدقيقة بنصف زمن الاستجابة';

  @override
  String get preEntryLabel => 'الدخول المسبق (ملي ثانية)';

  @override
  String get preEntryHelp =>
      'الإرسال قبل بداية الدقيقة بهذا العدد من الملي ثانية';

  @override
  String get notifTrading => 'QXBot يتداول الآن';

  @override
  String notifToday(String net, String wins, String losses) {
    return 'QXBot · اليوم $net ($wins ربح، $losses خسارة)';
  }

  @override
  String get channelName => 'تداول QXBot';

  @override
  String get channelDesc => 'حالة الروبوت ونتائج الصفقات';

  @override
  String evConnected(String account) {
    return 'تم الاتصال بـ Quotex (الحساب $account)';
  }

  @override
  String evConnectFailed(String error) {
    return 'فشل الاتصال: $error';
  }

  @override
  String get evStopped => 'تم الإيقاف';

  @override
  String get evAllDone => 'انتهت جميع الإشارات';

  @override
  String evSkipped(String time, String pair, String dir, String reason) {
    return '$time $pair $dir: تم التجاهل، $reason';
  }

  @override
  String get rOverlap => 'توجد إشارة أخرى في هذه الدقيقة (التداخل معطّل)';

  @override
  String rStopLoss(String net) {
    return 'تم بلوغ حد الخسارة اليومي (اليوم $net)';
  }

  @override
  String rTakeProfit(String net) {
    return 'تم بلوغ هدف الربح اليومي (اليوم $net)';
  }

  @override
  String rBalance(String balance, String amount) {
    return 'الرصيد $balance لا يكفي لمبلغ $amount';
  }

  @override
  String get rNotConnected => 'غير متصل';

  @override
  String get rPairNotFound => 'الزوج غير موجود في Quotex';

  @override
  String get rPairClosed => 'هذا الزوج مغلق حاليًا في Quotex';

  @override
  String rPayout(String payout, String min) {
    return 'نسبة الربح $payout% أقل من $min%';
  }

  @override
  String get rStopped => 'تم الإيقاف';

  @override
  String get evConnectionLost => 'انقطع الاتصال، جارٍ إعادة الدخول...';

  @override
  String evReconnectFailed(String error) {
    return 'فشلت إعادة الاتصال: $error';
  }

  @override
  String evOrderNotConfirmed(String pair) {
    return '$pair: لم تُؤكَّد الصفقة (الزوج مغلق أو المبلغ غير صالح؟)';
  }

  @override
  String evOrderRejected(String pair, String dir, String error) {
    return '$pair $dir: رفضت Quotex الصفقة: $error';
  }

  @override
  String evOrderOpened(String pair, String dir, String amount, String delay,
      String at, String sent, String ping, String price) {
    return '$pair $dir $amount: فُتحت الصفقة بفارق $delay ملي ثانية عن $at (أُرسلت $sent ملي ثانية، زمن الاستجابة $ping ملي ثانية) سعر الدخول $price';
  }

  @override
  String evPendingSet(String pair, String dir, String amount, String at) {
    return '$pair $dir $amount: تم وضع صفقة معلقة على $at (تفتحها Quotex)';
  }

  @override
  String evPendingNoTicket(String pair) {
    return '$pair: رد الصفقة المعلقة بدون رقم تذكرة: تم التجاهل (تفاديًا للدخول مرتين)';
  }

  @override
  String evPendingCancelled(String pair, String reason) {
    return '$pair: أُلغيت الصفقة المعلقة: $reason';
  }

  @override
  String evPendingOpened(String pair, String dir, String amount, String delay,
      String at, String price) {
    return '$pair $dir $amount: فتحت Quotex الصفقة المعلقة بفارق $delay ملي ثانية عن $at، سعر الدخول $price';
  }

  @override
  String evPendingNoAnswer(String pair) {
    return '$pair: لم تُؤكَّد الصفقة المعلقة: تم التجاهل (تفاديًا للدخول مرتين)';
  }

  @override
  String evPendingFailed(String pair, String error) {
    return '$pair: فشلت الصفقة المعلقة ($error): الدخول المباشر الآن';
  }

  @override
  String evGaleReady(String pair, String level) {
    return '$pair: الصفقة خاسرة قبل 5 ثوانٍ من الإغلاق، المضاعفة $level جاهزة';
  }

  @override
  String evGaleCancelled(String pair, String at) {
    return 'أُلغيت المضاعفة على $pair: توجد إشارة في القائمة على $at (التداخل معطّل)';
  }

  @override
  String evGaleStart(String level, String pair, String amount) {
    return 'المضاعفة $level على $pair: $amount';
  }

  @override
  String evResultNotReceived(String pair) {
    return '$pair: لم تصل النتيجة (راجع سجل الصفقات في Quotex)';
  }

  @override
  String evResult(
      String pair, String dir, String gale, String result, String profit) {
    return '$pair $dir$gale: $result $profit';
  }

  @override
  String evError(String pair, String error) {
    return '$pair: خطأ: $error';
  }

  @override
  String evClockWarning(String offset) {
    return 'ساعة الهاتف تختلف عن ساعة Quotex بـ $offset ثانية: يتم تصحيح التوقيت تلقائيًا';
  }

  @override
  String get tabResults => 'النتائج';

  @override
  String get details => 'التفاصيل';

  @override
  String get detailsTitle => 'التفاصيل (السجل التقني)';

  @override
  String get nextTrade => 'الصفقة التالية';

  @override
  String atTime(String time) {
    return 'الساعة $time';
  }

  @override
  String inCountdown(String time) {
    return 'بعد $time';
  }

  @override
  String get nowEntering => 'الدخول الآن';

  @override
  String get noNextTrade => 'لا توجد صفقة في الانتظار';

  @override
  String get botStoppedHint =>
      'انسخ قائمة الإشارات من تيليجرام، ثم اضغط الزر بالأسفل.';

  @override
  String get todayProfit => 'ربح اليوم';

  @override
  String winsLosses(String wins, String losses) {
    return '$wins رابحة · $losses خاسرة';
  }

  @override
  String get pasteBig => 'لصق القائمة من الحافظة';

  @override
  String get typeList => 'كتابة القائمة أو تعديلها';

  @override
  String get clipboardEmpty =>
      'الحافظة فارغة. انسخ قائمة الإشارات من تيليجرام أولًا.';

  @override
  String get noSignalsInText =>
      'لم يتم العثور على إشارات في النص المنسوخ. انسخ القائمة كاملة (مثال: M1 EURUSD 14:30 CALL).';

  @override
  String previewSummary(String amount, String account) {
    return '$amount لكل صفقة · الحساب $account';
  }

  @override
  String martingaleOn(String mult, String levels) {
    return 'مضاعفة ×$mult، حتى $levels مرات';
  }

  @override
  String get martingaleOffShort => 'المضاعفة معطّلة';

  @override
  String get edit => 'تعديل';

  @override
  String get realStartTitle => 'التداول بأموال حقيقية؟';

  @override
  String realStartBody(String trades, String amount) {
    return '$trades صفقات بمبلغ $amount على حسابك الحقيقي (وأكثر عند المضاعفة). الخسائر حقيقية.';
  }

  @override
  String get startReal => 'ابدأ بأموال حقيقية';

  @override
  String get stopTitle => 'إيقاف الروبوت؟';

  @override
  String get stopBody =>
      'ستُلغى الصفقات المنتظرة. أما الصفقات المفتوحة في Quotex فتكتمل بشكل عادي.';

  @override
  String get keepRunning => 'متابعة التشغيل';

  @override
  String get upcoming => 'القادمة';

  @override
  String get inTrade => 'في صفقة';

  @override
  String get latestResults => 'آخر النتائج';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get noResultsYet => 'لا توجد نتائج بعد. تظهر هنا بعد كل صفقة.';

  @override
  String get firstEntry => 'الدخول الأول';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get bgWarnTitle => 'التشغيل في الخلفية غير مضبوط';

  @override
  String get bgWarnBody => 'قد يتوقف التداول عند إطفاء الشاشة.';

  @override
  String get fix => 'إصلاح';

  @override
  String get loginExpired =>
      'انتهت جلسة الدخول إلى Quotex. يرجى تسجيل الدخول مجددًا.';

  @override
  String get noInternet =>
      'لا يوجد اتصال بالإنترنت. تحقق من الواي فاي أو بيانات الهاتف.';

  @override
  String get connectProblem =>
      'تعذّر الوصول إلى Quotex حاليًا. جارٍ المحاولة مجددًا...';

  @override
  String get logInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get account => 'الحساب';

  @override
  String get logoutTitle => 'تسجيل الخروج من Quotex؟';

  @override
  String get essentials => 'الأساسيات';

  @override
  String get martingale => 'المضاعفة';

  @override
  String get martingaleSub =>
      'بعد الخسارة، تُفتح صفقة على الشمعة التالية بمبلغ أكبر';

  @override
  String get levels => 'عدد المرات';

  @override
  String get tzHint =>
      'المنطقة الزمنية التي تكتب بها القناة أوقاتها (ابحث عن \"UTC-3\" أعلى القائمة). إذا كُتبت في القائمة فهي المعتمدة.';

  @override
  String get dailyLimits => 'الحدود اليومية';

  @override
  String get advanced => 'خيارات متقدمة';

  @override
  String get advancedSub =>
      'الصفقات المعلقة، توقيت الدخول، التداخل، نسبة الربح';

  @override
  String get backgroundSetup => 'إعداد التشغيل في الخلفية';

  @override
  String get backgroundSetupSub => 'استمرار التداول والشاشة مطفأة';

  @override
  String get other => 'أخرى';

  @override
  String get bgTitle => 'إبقاء QXBot يعمل';

  @override
  String get bgIntro =>
      'يوقف أندرويد التطبيقات في الخلفية لتوفير البطارية. نفّذ هذه الخطوات مرة واحدة ليواصل QXBot التداول والشاشة مطفأة.';

  @override
  String get bgNotif => 'الإشعارات';

  @override
  String get bgNotifSub => 'تُظهر أن الروبوت يعمل، ونتيجة كل صفقة';

  @override
  String get bgBattery => 'البطارية: بدون قيود';

  @override
  String get bgBatterySub =>
      'اضغط سماح، ثم اختر \"سماح\" أو \"عدم التحسين\" أو \"غير مقيد\"';

  @override
  String bgBrand(String brand) {
    return 'إعدادات الهاتف ($brand)';
  }

  @override
  String get bgBrandGeneric => 'إعدادات الهاتف';

  @override
  String get allow => 'سماح';

  @override
  String get allowed => 'مسموح';

  @override
  String get openSettings => 'فتح';

  @override
  String get bgXiaomi =>
      'التشغيل التلقائي: فعّل QXBot. ثم معلومات التطبيق > توفير البطارية: \"بلا قيود\". وفي التطبيقات الأخيرة اسحب QXBot للأسفل لقفله.';

  @override
  String get bgHuawei =>
      'تشغيل التطبيقات: أوقف \"الإدارة التلقائية\" لـ QXBot، ثم فعّل التشغيل التلقائي والتشغيل الثانوي والتشغيل في الخلفية.';

  @override
  String get bgOppo =>
      'التشغيل التلقائي: فعّل QXBot. البطارية > إدارة بطارية التطبيقات > QXBot: اسمح بالنشاط في الخلفية.';

  @override
  String get bgVivo =>
      'التشغيل في الخلفية و\"استهلاك طاقة عالٍ في الخلفية\": اسمح لـ QXBot.';

  @override
  String get bgSamsung =>
      'البطارية > حدود الاستخدام في الخلفية > التطبيقات التي لا تدخل في وضع السكون أبدًا: أضف QXBot (واحذفه من التطبيقات النائمة).';

  @override
  String get bgOther =>
      'معلومات التطبيق > البطارية: \"غير مقيد\". وإذا كان في هاتفك إعداد \"التشغيل التلقائي\" أو \"النشاط في الخلفية\" فاسمح لـ QXBot.';

  @override
  String get bgTips =>
      'نصائح: اترك الهاتف على الشاحن أثناء القوائم الطويلة، ولا تغلق QXBot من التطبيقات الأخيرة.';

  @override
  String get bgPending =>
      'معلومة مفيدة: الصفقات المعلقة (أزواج OTC، تُوضع قبل دقيقة) تكون مسجّلة في Quotex وتُفتح حتى لو كان الهاتف نائمًا. أما المضاعفة والصفقات المباشرة فتحتاج التطبيق مستيقظًا.';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get later => 'لاحقًا';

  @override
  String get done => 'تم';

  @override
  String get welcome => 'مرحبًا بك في QXBot';

  @override
  String obStep(String step, String total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get obAccountTitle => 'أي حساب؟';

  @override
  String get obAccountBody =>
      'ابدأ بالحساب التجريبي لتجربة الروبوت بأموال التدريب. يمكنك التبديل في أي وقت من الإعدادات.';

  @override
  String get demoCardTitle => 'تجريبي (أموال للتدريب)';

  @override
  String get demoCardSub => 'مُستحسن للبداية. بدون مخاطرة.';

  @override
  String get realCardTitle => 'أموال حقيقية';

  @override
  String get realCardSub => 'تُستخدم أموالك الحقيقية.';

  @override
  String get obAmountTitle => 'المبلغ لكل صفقة';

  @override
  String obAmountBody(String amount) {
    return 'المبلغ الذي تستخدمه كل صفقة. ومع تفعيل المضاعفة، تليها بعد الخسارة صفقة بمبلغ $amount.';
  }

  @override
  String get obDoneTitle => 'كل شيء جاهز!';

  @override
  String get obDoneBody =>
      'انسخ قائمة الإشارات من تيليجرام، وافتح QXBot، ثم اضغط \"لصق القائمة من الحافظة\".';

  @override
  String get goHome => 'ابدأ استخدام QXBot';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get invalidAmount => 'أدخل مبلغًا لا يقل عن 1';

  @override
  String evWokeUp(String seconds) {
    return 'كان الهاتف نائمًا لمدة $seconds ثانية: جارٍ التحقق من الاتصال والقائمة';
  }

  @override
  String evServiceFailed(String error) {
    return 'تعذّر تشغيل وضع الخلفية ($error). أبقِ التطبيق مفتوحًا.';
  }

  @override
  String rLate(String seconds) {
    return 'بدأت دقيقتها قبل $seconds ثانية (كان الهاتف نائمًا)؛ الدخول المتأخر أسوأ من عدم الدخول';
  }
}
