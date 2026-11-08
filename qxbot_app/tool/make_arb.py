"""Writes lib/l10n/app_en.arb and app_ar.arb from one table (keeps keys in sync).
Run: python3 tool/make_arb.py   Plain {x} placeholders are Strings (the UI pre-formats numbers
with LTR isolates); placeholders named in INTS are ints (used by plurals)."""
import json, re, pathlib

INTS = {"count", "n"}
T = {
 "appTitle": ("QXBot", "QXBot"),
 "tabHome": ("Home", "الرئيسية"),
 "tabSignals": ("Signals", "الإشارات"),
 "tabLive": ("Live", "مباشر"),
 "tabStats": ("Stats", "الإحصائيات"),
 "tabSettings": ("Settings", "الإعدادات"),
 "demo": ("DEMO", "تجريبي"),
 "real": ("REAL", "حقيقي"),
 "call": ("CALL", "شراء"),
 "put": ("PUT", "بيع"),
 "win": ("WIN", "ربح"),
 "loss": ("LOSS", "خسارة"),
 "draw": ("DRAW", "تعادل"),
 "cancel": ("Cancel", "إلغاء"),
 # login
 "loginTitle": ("Log in to Quotex", "تسجيل الدخول إلى Quotex"),
 "loginHelp": ("Log in with your Quotex email and password (and the email code if asked). The app continues by itself once you are in.",
               "سجّل الدخول ببريدك الإلكتروني وكلمة المرور في Quotex (وأدخل الرمز المرسل إلى بريدك إن طُلب منك). يكمل التطبيق تلقائيًا بعد الدخول."),
 "reload": ("Reload", "إعادة التحميل"),
 "pasteToken": ("Paste token", "لصق رمز الجلسة"),
 "sessionToken": ("Session token", "رمز الجلسة"),
 "use": ("Use", "استخدام"),
 # home
 "connection": ("Connection", "الاتصال"),
 "connected": ("Connected", "متصل"),
 "connecting": ("Connecting...", "جارٍ الاتصال..."),
 "disconnected": ("Disconnected", "غير متصل"),
 "connectFailedStatus": ("Login expired or no connection", "انتهت الجلسة أو لا يوجد اتصال"),
 "reconnect": ("Reconnect", "إعادة الاتصال"),
 "clockCorrected": ("Clock vs Quotex: {offset} s (corrected)", "فرق الساعة مع Quotex: {offset} ث (مُصحَّح)"),
 "clockNotVerified": ("Clock vs Quotex: not verified (phone clock in use)", "فرق الساعة مع Quotex: غير مُتحقَّق منه (تُستخدم ساعة الهاتف)"),
 "balance": ("Balance", "الرصيد"),
 "todaySummary": ("Today {net} · {wins}W {losses}L {draws}D", "اليوم {net} · {wins} ربح · {losses} خسارة · {draws} تعادل"),
 "demoAccountSwitch": ("Demo account (practice money)", "الحساب التجريبي (أموال للتدريب)"),
 "realTitle": ("Switch to REAL money?", "التحويل إلى الحساب الحقيقي؟"),
 "realBody": ("Trades will use your real Quotex balance. Losses are real.", "ستُنفَّذ الصفقات برصيدك الحقيقي في Quotex. والخسائر ستكون حقيقية."),
 "useReal": ("Use real account", "استخدام الحساب الحقيقي"),
 "bot": ("Bot", "الروبوت"),
 "runningWaiting": ("{count, plural, =0{Running · no signals waiting} =1{Running · 1 signal waiting} other{Running · {count} signals waiting}}",
                    "{count, plural, =0{يعمل · لا توجد إشارات في الانتظار} =1{يعمل · إشارة واحدة في الانتظار} =2{يعمل · إشارتان في الانتظار} few{يعمل · {count} إشارات في الانتظار} other{يعمل · {count} إشارة في الانتظار}}"),
 "stopped": ("Stopped", "متوقف"),
 "stop": ("Stop", "إيقاف"),
 "pasteSignals": ("Paste signals", "لصق الإشارات"),
 "logout": ("Log out", "تسجيل الخروج"),
 # signals
 "signalsHint": ("Paste the Telegram signal list here\ne.g. M1 EURUSD-OTC 14:30 CALL", "الصق قائمة إشارات تيليجرام هنا\nمثال: M1 EURUSD-OTC 14:30 CALL"),
 "pasteFromClipboard": ("Paste", "لصق"),
 "listTimezone": ("List timezone: {tz} (from Settings; a \"UTC+6\" written in the list wins)",
                  "توقيت القائمة: {tz} (من الإعدادات؛ وإذا كُتب في القائمة توقيت مثل \"UTC+6\" فهو المعتمد)"),
 "notConnectedNames": ("Not connected: pair names not checked", "غير متصل: لم يتم التحقق من أسماء الأزواج"),
 "signalsFound": ("{count, plural, =0{No signals found} =1{1 signal found} other{{count} signals found}}",
                  "{count, plural, =0{لم يتم العثور على إشارات} =1{تم العثور على إشارة واحدة} =2{تم العثور على إشارتين} few{تم العثور على {count} إشارات} other{تم العثور على {count} إشارة}}"),
 "minutes": ("{n, plural, =1{1 min} other{{n} min}}", "{n, plural, =1{دقيقة واحدة} =2{دقيقتان} few{{n} دقائق} other{{n} دقيقة}}"),
 "seconds": ("{n} s", "{n} ثانية"),
 "pairNotFound": ("Pair not found on Quotex: this line is skipped", "الزوج غير موجود في Quotex: سيتم تجاهل هذا السطر"),
 "connectFirst": ("Connect first", "اتصل أولاً"),
 "startTrading": ("Start trading ({count})", "ابدأ التداول ({count})"),
 "scheduled": ("{count, plural, =0{No signals scheduled} =1{1 signal scheduled} other{{count} signals scheduled}}",
               "{count, plural, =0{لم تتم جدولة أي إشارة} =1{تمت جدولة إشارة واحدة} =2{تمت جدولة إشارتين} few{تمت جدولة {count} إشارات} other{تمت جدولة {count} إشارة}}"),
 # live
 "stopBot": ("Stop bot", "إيقاف الروبوت"),
 "waiting": ("Waiting ({count})", "في الانتظار ({count})"),
 "log": ("Log", "السجل"),
 "logEmpty": ("Nothing yet", "لا شيء بعد"),
 # stats
 "thisSession": ("This session", "هذه الجلسة"),
 "today": ("Today", "اليوم"),
 "allTime": ("All time ({account})", "منذ البداية ({account})"),
 "netProfit": ("Net profit", "صافي الربح"),
 "winRate": ("Win rate", "نسبة النجاح"),
 "trades": ("Trades", "الصفقات"),
 "wld": ("W / L / D", "ربح / خسارة / تعادل"),
 "signalsWon": ("Signals won", "إشارات رابحة"),
 "wonAfterGale": ("Won after martingale", "رابحة بعد المضاعفة"),
 "maxDrawdown": ("Max drawdown", "أقصى تراجع"),
 "worstStreak": ("Worst streak", "أسوأ سلسلة خسائر"),
 "lossesCount": ("{n, plural, =0{no losses} =1{1 loss} other{{n} losses}}",
                 "{n, plural, =0{لا خسائر} =1{خسارة واحدة} =2{خسارتان} few{{n} خسائر} other{{n} خسارة}}"),
 "recentTrades": ("Recent trades", "آخر الصفقات"),
 "noTrades": ("No trades yet", "لا توجد صفقات بعد"),
 "entryPending": ("pending", "معلقة"),
 "entryDirect": ("direct", "مباشرة"),
 "galeTag": ("G{level}", "مضاعفة {level}"),
 # settings
 "language": ("Language", "اللغة"),
 "languageSystem": ("Phone language", "لغة الهاتف"),
 "stopToChange": ("Stop the bot to change settings", "أوقف الروبوت لتغيير الإعدادات"),
 "amountLabel": ("Trade amount ($)", "مبلغ الصفقة ($)"),
 "amountHelp": ("Stake for each signal", "المبلغ لكل إشارة"),
 "tzLabel": ("Signal list timezone (UTC hours)", "توقيت قائمة الإشارات (بساعات UTC)"),
 "tzHelp": ("e.g. -3 for UTC-3, 1 for Algeria, 5.5 for UTC+5:30", "مثال: ‎-3 لتوقيت UTC-3، و 1 لتوقيت الجزائر، و 5.5 لتوقيت UTC+5:30"),
 "galesLabel": ("Martingale levels", "عدد مستويات المضاعفة"),
 "offHelp": ("0 = off", "0 = معطّل"),
 "multLabel": ("Martingale multiplier", "معامل المضاعفة"),
 "multHelp": ("Next stake = stake × this", "المبلغ التالي = المبلغ × هذا المعامل"),
 "minPayoutLabel": ("Minimum payout (%)", "أدنى نسبة ربح (%)"),
 "minPayoutHelp": ("Skip a signal when the payout is lower", "تجاهل الإشارة إذا كانت نسبة الربح أقل"),
 "stopLossLabel": ("Daily stop-loss ($)", "حد الخسارة اليومي ($)"),
 "takeProfitLabel": ("Daily take-profit ($)", "هدف الربح اليومي ($)"),
 "pendingTitle": ("Pending orders for OTC", "صفقات معلقة لأزواج OTC"),
 "pendingSub": ("Quotex opens the trade itself at the exact minute", "تفتح Quotex الصفقة بنفسها في الدقيقة المحددة تمامًا"),
 "overlapTitle": ("Allow overlapping signals", "السماح بتداخل الإشارات"),
 "overlapSub": ("Off: one signal per minute, a list signal beats a martingale", "عند التعطيل: إشارة واحدة في الدقيقة، وإشارة القائمة لها الأولوية على المضاعفة"),
 "autoTiming": ("Automatic entry timing", "توقيت الدخول التلقائي"),
 "autoTimingSub": ("Send direct orders half a ping before the minute", "إرسال الصفقات المباشرة قبل بداية الدقيقة بنصف زمن الاستجابة"),
 "preEntryLabel": ("Pre-entry (ms)", "الدخول المسبق (ملي ثانية)"),
 "preEntryHelp": ("Send this many ms before the minute", "الإرسال قبل بداية الدقيقة بهذا العدد من الملي ثانية"),
 # notifications
 "notifTrading": ("QXBot is trading", "QXBot يتداول الآن"),
 "notifToday": ("QXBot · today {net} ({wins}W {losses}L)", "QXBot · اليوم {net} ({wins} ربح، {losses} خسارة)"),
 "channelName": ("QXBot trading", "تداول QXBot"),
 "channelDesc": ("Bot running and trade results", "حالة الروبوت ونتائج الصفقات"),
 # log events (engine keys -> ev + Key)
 "evConnected": ("Connected to Quotex ({account} account)", "تم الاتصال بـ Quotex (الحساب {account})"),
 "evConnectFailed": ("Connect failed: {error}", "فشل الاتصال: {error}"),
 "evStopped": ("Stopped", "تم الإيقاف"),
 "evAllDone": ("All signals done", "انتهت جميع الإشارات"),
 "evSkipped": ("{time} {pair} {dir} skipped: {reason}", "{time} {pair} {dir}: تم التجاهل، {reason}"),
 "rOverlap": ("another signal has this minute (overlap off)", "توجد إشارة أخرى في هذه الدقيقة (التداخل معطّل)"),
 "rStopLoss": ("daily stop-loss reached (today {net})", "تم بلوغ حد الخسارة اليومي (اليوم {net})"),
 "rTakeProfit": ("daily take-profit reached (today {net})", "تم بلوغ هدف الربح اليومي (اليوم {net})"),
 "rBalance": ("balance {balance} can't cover {amount}", "الرصيد {balance} لا يكفي لمبلغ {amount}"),
 "rNotConnected": ("not connected", "غير متصل"),
 "rPairNotFound": ("pair not found on Quotex", "الزوج غير موجود في Quotex"),
 "rPairClosed": ("Quotex has this pair closed right now", "هذا الزوج مغلق حاليًا في Quotex"),
 "rPayout": ("payout {payout}% < {min}%", "نسبة الربح {payout}% أقل من {min}%"),
 "rStopped": ("stopped", "تم الإيقاف"),
 "evConnectionLost": ("Connection lost, logging in again...", "انقطع الاتصال، جارٍ إعادة الدخول..."),
 "evReconnectFailed": ("Reconnect failed: {error}", "فشلت إعادة الاتصال: {error}"),
 "evOrderNotConfirmed": ("{pair} order not confirmed (pair closed or amount invalid?)", "{pair}: لم تُؤكَّد الصفقة (الزوج مغلق أو المبلغ غير صالح؟)"),
 "evOrderRejected": ("{pair} {dir} rejected by Quotex: {error}", "{pair} {dir}: رفضت Quotex الصفقة: {error}"),
 "evOrderOpened": ("{pair} {dir} {amount} opened {delay} ms vs {at} (sent {sent} ms, ping {ping} ms) open {price}",
                   "{pair} {dir} {amount}: فُتحت الصفقة بفارق {delay} ملي ثانية عن {at} (أُرسلت {sent} ملي ثانية، زمن الاستجابة {ping} ملي ثانية) سعر الدخول {price}"),
 "evPendingSet": ("{pair} {dir} {amount} pending order set for {at} (Quotex opens it)", "{pair} {dir} {amount}: تم وضع صفقة معلقة على {at} (تفتحها Quotex)"),
 "evPendingNoTicket": ("{pair} pending reply without a ticket: skipped (no risk of a double entry)", "{pair}: رد الصفقة المعلقة بدون رقم تذكرة: تم التجاهل (تفاديًا للدخول مرتين)"),
 "evPendingCancelled": ("{pair} pending order cancelled: {reason}", "{pair}: أُلغيت الصفقة المعلقة: {reason}"),
 "evPendingOpened": ("{pair} {dir} {amount} opened {delay} ms vs {at} by Quotex (pending) open {price}",
                     "{pair} {dir} {amount}: فتحت Quotex الصفقة المعلقة بفارق {delay} ملي ثانية عن {at}، سعر الدخول {price}"),
 "evPendingNoAnswer": ("{pair} pending order not confirmed: skipped (no risk of a double entry)", "{pair}: لم تُؤكَّد الصفقة المعلقة: تم التجاهل (تفاديًا للدخول مرتين)"),
 "evPendingFailed": ("{pair} pending order failed ({error}): entering directly", "{pair}: فشلت الصفقة المعلقة ({error}): الدخول المباشر الآن"),
 "evGaleReady": ("{pair} losing with 5 s left, martingale {level} ready", "{pair}: الصفقة خاسرة قبل 5 ثوانٍ من الإغلاق، المضاعفة {level} جاهزة"),
 "evGaleCancelled": ("Martingale on {pair} cancelled: a list signal has {at} (overlap off)", "أُلغيت المضاعفة على {pair}: توجد إشارة في القائمة على {at} (التداخل معطّل)"),
 "evGaleStart": ("Martingale {level} on {pair}: {amount}", "المضاعفة {level} على {pair}: {amount}"),
 "evResultNotReceived": ("{pair} result not received (check Quotex history)", "{pair}: لم تصل النتيجة (راجع سجل الصفقات في Quotex)"),
 "evResult": ("{pair} {dir}{gale}: {result} {profit}", "{pair} {dir}{gale}: {result} {profit}"),
 "evError": ("{pair} error: {error}", "{pair}: خطأ: {error}"),
 "evClockWarning": ("Phone clock is {offset} s off Quotex: timing is corrected automatically", "ساعة الهاتف تختلف عن ساعة Quotex بـ {offset} ثانية: يتم تصحيح التوقيت تلقائيًا"),
}

def arb(lang, i):
    out = {"@@locale": lang}
    for k, v in T.items():
        text = v[i]
        out[k] = text
        if i == 0:
            names = []
            for n in re.findall(r"\{(\w+)[,}]", text):
                if n not in names:
                    names.append(n)
            if names:
                out["@" + k] = {"placeholders": {n: {"type": "int" if n in INTS else "String"} for n in names}}
    return out

d = pathlib.Path(__file__).resolve().parent.parent / "lib" / "l10n"
for lang, i in (("en", 0), ("ar", 1)):
    (d / f"app_{lang}.arb").write_text(json.dumps(arb(lang, i), ensure_ascii=False, indent=2) + "\n")
print(len(T), "keys")
