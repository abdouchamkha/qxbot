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
}
