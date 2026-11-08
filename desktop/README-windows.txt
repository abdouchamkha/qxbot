QXBot - Quotex signal-list auto trader (Windows 10/11)
=====================================================

1. Unzip QXBot-windows.zip anywhere (e.g. Desktop): right-click > Extract All.
   Do not run it from inside the zip.
2. Open the QXBot folder and double-click QXBot.exe.
   If Windows says "Windows protected your PC": click "More info" > "Run anyway" (first time only).
3. The QXBot window opens. Sign in with your Quotex email and password, choose Demo or Real, click Connect.
   A browser window (Edge, Chrome or Brave) opens and logs in by itself, then closes.
   If Quotex emails you a PIN, a box appears in QXBot: type the PIN there.
4. Signals: paste the list from Telegram. The preview shows each signal (pair, time, CALL/PUT),
   lines it did not understand and signals whose time has passed. Click "Start trading".
5. Home shows the balance, today's profit, the next trade with a countdown, and a big
   "Stop all trades" button. Results shows each trade as WIN / WIN G1 / LOSS; "Details log"
   shows everything the bot does.
6. Settings: amount, list timezone (UTC offset: 1 Algeria, 3 Saudi, -3 Brasilia), martingale,
   daily stop-loss / take-profit. "Create desktop shortcut" puts QXBot on your desktop.
7. Keep QXBot open while trading. Closing it with trades scheduled asks first and cancels them.

Notes
- Test on Demo first.
- Keep the Windows clock synced (Settings > Time & language > Sync now). Home shows "Clock: In sync".
- Old text mode: QXBot-terminal.bat.
- config.json and the login_profile folder hold your login. Never share them.
- If something goes wrong, send qxbot.log (same folder); it has no password.

----------------------------------------------------------------------
QXBot - تداول تلقائي لقوائم الإشارات على Quotex (ويندوز 10/11)

1. فك ضغط QXBot-windows.zip في أي مكان (مثلاً سطح المكتب): زر الفأرة الأيمن > استخراج الكل.
   لا تشغّله من داخل ملف zip.
2. افتح مجلد QXBot واضغط مرتين على QXBot.exe.
   إذا ظهر "Windows protected your PC": اضغط "More info" ثم "Run anyway" (أول مرة فقط).
3. تفتح نافذة QXBot. سجّل الدخول ببريد وكلمة سر Quotex، اختر تجريبي أو حقيقي، ثم اضغط اتصال.
   تفتح نافذة متصفح (Edge أو Chrome أو Brave) وتسجّل الدخول وحدها ثم تُغلق.
   إذا أرسل Quotex رمز PIN إلى بريدك، يظهر مربع في QXBot: اكتب الرمز فيه.
4. الإشارات: الصق القائمة من تيليجرام. المعاينة تعرض كل إشارة (الزوج، الوقت، صعود/هبوط)،
   والأسطر غير المفهومة، والإشارات التي فات وقتها. اضغط "ابدأ التداول".
5. الرئيسية تعرض الرصيد، ربح اليوم، الصفقة القادمة مع عدّاد تنازلي، وزر كبير "إيقاف كل الصفقات".
   النتائج تعرض كل صفقة: ربح / ربح G1 / خسارة، و"السجل التفصيلي" يعرض كل ما يفعله البوت.
6. الإعدادات: المبلغ، توقيت القائمة (فرق UTC: 1 الجزائر، 3 السعودية، -3 البرازيل)، المضاعفة،
   حد الخسارة وهدف الربح اليومي. زر "إنشاء اختصار على سطح المكتب" يضع QXBot على سطح المكتب.
7. اترك QXBot مفتوحاً أثناء التداول. إغلاقه مع صفقات مجدولة يسألك أولاً ثم يلغيها.

ملاحظات
- جرّب على الحساب التجريبي أولاً.
- اضبط ساعة ويندوز (الإعدادات > الوقت واللغة > مزامنة الآن). الرئيسية تعرض "الساعة: متزامنة".
- الوضع النصي القديم: QXBot-terminal.bat.
- لا تشارك ملف config.json ولا مجلد login_profile مع أحد.
- عند أي مشكلة أرسل ملف qxbot.log من نفس المجلد؛ لا يحتوي كلمة السر.
