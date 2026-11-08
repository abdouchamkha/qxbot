"use strict";
// QXBot desktop UI. State comes from the local bot over server-sent events; actions are POST /api/<name>.

const TOKEN = new URLSearchParams(location.search).get("t") || "";

const I18N = {
  en: {
    home: "Home", signals: "Signals", results: "Results", stats: "Stats", settings: "Settings",
    login_title: "Sign in to Quotex", login_sub: "A browser window opens and logs in for you. Keep it until it closes by itself.",
    profile: "Profile", new_profile: "New profile…", profile_name: "Profile name",
    email: "Email", password: "Password", password_saved: "Saved — leave empty to use it",
    demo: "Demo", real: "Real", real_warn: "Real money. Test on Demo first.",
    remember: "Remember password on this PC", connect: "Connect",
    connecting: "Connecting to Quotex…", connecting_hint: "A browser window opens and logs in. If Cloudflare shows a check there, solve it.",
    pin_title: "Enter the Quotex PIN", pin_sub: "Quotex sent a code to your email. Type it here.", send: "Send",
    online: "Connected", offline: "Offline",
    balance: "Balance", today_profit: "Today's profit", clock: "Clock", clock_ok: "In sync", clock_bad: "Out of sync",
    clock_unknown: "Not checked", connection: "Connection",
    next_trade: "Next trade", no_next: "No trade scheduled", no_next_sub: "Paste a signal list to start trading.",
    new_list: "New signal list", stop_all: "Stop all trades", scheduled: "Schedule", latest: "Latest results",
    none_yet: "No results yet today.", nothing_scheduled: "Nothing scheduled.", see_all: "See all",
    paste_title: "Paste your signal list", paste_ph: "Paste the list from Telegram here…\n\nM1 EURUSD-OTC 14:30 CALL\nM1 GBPJPY 14:35 PUT",
    preview: "Preview", upcoming: "Upcoming", passed: "Already passed", unknown: "Not understood (pair not on Quotex?)",
    tz: "Timezone", tz_list: "written in the list", tz_profile: "from Settings", start: "Start trading",
    backtest: "Backtest", bt_only: "Backtest only (no trades)", backtest_tz: "Try other timezones (optional)", backtest_sub: "Checks every signal at its last time in the past 24 h on Quotex candles, with your martingale.",
    dup: "same minute, skipped", empty_preview: "Signals show here as you paste.",
    not_checked: "Pair names are checked against Quotex once you are connected.", clear: "Clear",
    trades_tab: "Trades", log_tab: "Details log", copy: "Copy", copied: "Copied",
    bot_stats: "Bot stats", quotex_history: "Quotex history", session: "Session", today: "Today", all: "All time",
    trades: "Trades", win_rate: "Win rate", net: "Net", roi: "ROI", drawdown: "Max drawdown", streak: "Worst streak",
    signals_won: "Signals won", by_step: "Wins by step", pairs: "Pairs", pair: "Pair", load: "Load today's history",
    history_sub: "Every trade Quotex has for today, including ones placed by hand.", time: "Time", result: "Result", amount_c: "Amount", profit: "Profit",
    essentials: "Essentials", advanced: "Advanced",
    amount: "Amount per trade ($)", utc_offset: "Signal list timezone (UTC offset)", utc_hint: "-3 Brasília · 0 London · 1 Algeria · 3 Saudi",
    gales: "Martingale levels (0 = off)", gale_multiplier: "Martingale multiplier", stop_loss: "Daily stop-loss ($, 0 = off)",
    take_profit: "Daily take-profit ($, 0 = off)", min_payout: "Minimum payout (%)", pending: "OTC entries as Quotex pending orders",
    pre_entry_ms: "Direct entry head start (ms, or auto)", overlap: "Allow several trades in the same minute",
    safe_pips: "Safe entry pips (0 = off)", proxy: "Proxy (empty = your own connection)", host: "Quotex host",
    headless: "Hide the login browser", save: "Save settings", saved: "Settings saved",
    language: "Language", shortcut: "Create desktop shortcut", shortcut_done: "Shortcut created on your desktop",
    logout: "Log out", account_note: "Email and Demo/Real are chosen when you sign in. Changes apply to the next trades.",
    app_section: "App",
    quit_title: "Trades are still scheduled", quit_body: "{n} trades are waiting. Closing QXBot cancels them; trades already open finish on Quotex.",
    quit_stop: "Stop trades and close", quit_keep: "Keep running",
    call: "CALL", put: "PUT", waiting: "Waiting", done: "Done", cancelled: "Cancelled",
    WIN: "WIN", LOSS: "LOSS", DRAW: "DRAW",
    started: "{n} trades scheduled", stopped: "{n} trades cancelled", in: "in", tomorrow: "tomorrow",
    confirm_stop: "Stop all scheduled trades? Trades already open finish normally.",
    wins_losses: "{w} won · {l} lost · {d} draw", running_bt: "Backtesting… this can take a minute.", demo_b: "DEMO", real_b: "REAL",
  },
  ar: {
    home: "الرئيسية", signals: "الإشارات", results: "النتائج", stats: "الإحصائيات", settings: "الإعدادات",
    login_title: "تسجيل الدخول إلى Quotex", login_sub: "تفتح نافذة متصفح وتسجّل الدخول تلقائياً. اتركها حتى تُغلق وحدها.",
    profile: "الملف", new_profile: "ملف جديد…", profile_name: "اسم الملف",
    email: "البريد الإلكتروني", password: "كلمة السر", password_saved: "محفوظة — اتركها فارغة لاستخدامها",
    demo: "تجريبي", real: "حقيقي", real_warn: "أموال حقيقية. جرّب على الحساب التجريبي أولاً.",
    remember: "تذكّر كلمة السر على هذا الجهاز", connect: "اتصال",
    connecting: "جارٍ الاتصال بـ Quotex…", connecting_hint: "تفتح نافذة متصفح وتسجّل الدخول. إذا ظهر فحص Cloudflare فأكمله هناك.",
    pin_title: "أدخل رمز Quotex", pin_sub: "أرسل Quotex رمزاً إلى بريدك. اكتبه هنا.", send: "إرسال",
    online: "متصل", offline: "غير متصل",
    balance: "الرصيد", today_profit: "ربح اليوم", clock: "الساعة", clock_ok: "متزامنة", clock_bad: "غير متزامنة",
    clock_unknown: "لم تُفحص", connection: "الاتصال",
    next_trade: "الصفقة القادمة", no_next: "لا توجد صفقة مجدولة", no_next_sub: "الصق قائمة إشارات لبدء التداول.",
    new_list: "قائمة إشارات جديدة", stop_all: "إيقاف كل الصفقات", scheduled: "الجدول", latest: "آخر النتائج",
    none_yet: "لا نتائج اليوم بعد.", nothing_scheduled: "لا شيء مجدول.", see_all: "عرض الكل",
    paste_title: "الصق قائمة الإشارات", paste_ph: "الصق القائمة من تيليجرام هنا…\n\nM1 EURUSD-OTC 14:30 CALL\nM1 GBPJPY 14:35 PUT",
    preview: "معاينة", upcoming: "القادمة", passed: "فات وقتها", unknown: "غير مفهومة (الزوج غير موجود في Quotex؟)",
    tz: "التوقيت", tz_list: "مكتوب في القائمة", tz_profile: "من الإعدادات", start: "ابدأ التداول",
    backtest: "اختبار خلفي", bt_only: "اختبار فقط (بدون تداول)", backtest_tz: "جرّب توقيتات أخرى (اختياري)", backtest_sub: "يفحص كل إشارة في آخر وقت لها خلال 24 ساعة على شموع Quotex، مع المضاعفة.",
    dup: "نفس الدقيقة، تُتجاهل", empty_preview: "تظهر الإشارات هنا أثناء اللصق.",
    not_checked: "تُفحص أسماء الأزواج على Quotex بعد الاتصال.", clear: "مسح",
    trades_tab: "الصفقات", log_tab: "السجل التفصيلي", copy: "نسخ", copied: "تم النسخ",
    bot_stats: "إحصائيات البوت", quotex_history: "سجل Quotex", session: "الجلسة", today: "اليوم", all: "الكل",
    trades: "الصفقات", win_rate: "نسبة الربح", net: "الصافي", roi: "العائد", drawdown: "أقصى تراجع", streak: "أسوأ سلسلة",
    signals_won: "إشارات رابحة", by_step: "الربح حسب المرحلة", pairs: "الأزواج", pair: "الزوج", load: "تحميل سجل اليوم",
    history_sub: "كل صفقات اليوم في Quotex، بما فيها اليدوية.", time: "الوقت", result: "النتيجة", amount_c: "المبلغ", profit: "الربح",
    essentials: "الأساسية", advanced: "متقدمة",
    amount: "مبلغ الصفقة ($)", utc_offset: "توقيت قائمة الإشارات (فرق UTC)", utc_hint: "-3 البرازيل · 0 لندن · 1 الجزائر · 3 السعودية",
    gales: "مستويات المضاعفة (0 = بدون)", gale_multiplier: "معامل المضاعفة", stop_loss: "حد الخسارة اليومي ($، 0 = بدون)",
    take_profit: "هدف الربح اليومي ($، 0 = بدون)", min_payout: "أقل نسبة عائد (%)", pending: "صفقات OTC كأوامر معلّقة في Quotex",
    pre_entry_ms: "إرسال مبكر للدخول المباشر (ms أو auto)", overlap: "السماح بعدة صفقات في نفس الدقيقة",
    safe_pips: "نقاط الدخول الآمن (0 = بدون)", proxy: "بروكسي (فارغ = اتصالك العادي)", host: "عنوان Quotex",
    headless: "إخفاء متصفح الدخول", save: "حفظ الإعدادات", saved: "تم حفظ الإعدادات",
    language: "اللغة", shortcut: "إنشاء اختصار على سطح المكتب", shortcut_done: "تم إنشاء الاختصار على سطح المكتب",
    logout: "تسجيل الخروج", account_note: "البريد ونوع الحساب يُختاران عند الدخول. التغييرات تُطبّق على الصفقات القادمة.",
    app_section: "التطبيق",
    quit_title: "ما زالت هناك صفقات مجدولة", quit_body: "{n} صفقات في الانتظار. إغلاق QXBot يلغيها؛ الصفقات المفتوحة تكتمل في Quotex.",
    quit_stop: "إيقاف الصفقات والإغلاق", quit_keep: "استمرار التشغيل",
    call: "صعود", put: "هبوط", waiting: "في الانتظار", done: "تمت", cancelled: "أُلغيت",
    WIN: "ربح", LOSS: "خسارة", DRAW: "تعادل",
    started: "تمت جدولة {n} صفقات", stopped: "أُلغيت {n} صفقات", in: "بعد", tomorrow: "غداً",
    confirm_stop: "إيقاف كل الصفقات المجدولة؟ الصفقات المفتوحة تكتمل عادي.",
    wins_losses: "{w} ربح · {l} خسارة · {d} تعادل", running_bt: "جارٍ الاختبار… قد يستغرق دقيقة.", demo_b: "تجريبي", real_b: "حقيقي",
  },
};

const ICON = {
  home: '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  signals: '<path d="M4 6h16M4 12h10M4 18h7"/><path d="m16 15 3 3 3-3"/>',
  results: '<rect x="3" y="4" width="18" height="16" rx="3"/><path d="m7 14 3-3 3 3 4-5"/>',
  stats: '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
  up: '<path d="M12 19V5M5 12l7-7 7 7"/>',
  down: '<path d="M12 5v14M19 12l-7 7-7-7"/>',
  play: '<path d="M7 4v16l13-8z"/>',
  stop: '<rect x="6" y="6" width="12" height="12" rx="2"/>',
  logo: '<path d="M3 17l5-5 4 4 8-9"/><path d="M14 7h6v6"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  inbox: '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.5 5h13L22 12v6a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-6z"/>',
  flask: '<path d="M9 3h6M10 3v6L4 19a1 1 0 0 0 .9 1.5h14.2A1 1 0 0 0 20 19l-6-10V3"/>',
};
const icon = (n) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[n]}</svg>`;

let S = null;            // last state from the bot
let clockOffset = 0;     // bot clock - this page's clock, seconds
let LOG = [];
let view = (location.hash || "#home").slice(1);
let mode = "";           // "login" | "app"
let lang = "en";
let resTab = "trades", statTab = "bot";
let draft = "";          // signal list being pasted
let lastPreview = null, previewTimer = 0;
let loginProfiles = null, loginProfile = null, loginAccount = "PRACTICE";

const t = (k, vars = {}) => (I18N[lang][k] ?? I18N.en[k] ?? k).replace(/\{(\w+)\}/g, (_, v) => vars[v]);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const $ = (sel, root = document) => root.querySelector(sel);
const now = () => Date.now() / 1000 + clockOffset;
const money = (v, sign = false) => v == null ? "—" : `<span class="num">${sign && v > 0 ? "+" : ""}${Number(v).toFixed(2)}</span>`;
const pct = (v) => `<span class="num">${Math.round(v)}%</span>`;

function pair(asset) {
  const otc = /_otc$/i.test(asset);
  let base = asset.replace(/_otc$/i, "");
  if (/^[A-Z]{6}$/.test(base)) base = base.slice(0, 3) + "/" + base.slice(3);
  return `<span class="ltr">${esc(base)}</span>${otc ? '<span class="otc">OTC</span>' : ""}`;
}
const dir = (d) => `<span class="dir ${d}">${icon(d === "call" ? "up" : "down")}${t(d)}</span>`;
function countdown(sec) {
  sec = Math.max(0, Math.floor(sec));
  const h = Math.floor(sec / 3600), m = Math.floor(sec / 60) % 60, s = sec % 60;
  return h ? `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}` : `${m}:${String(s).padStart(2, "0")}`;
}
function resultBadge(r) {
  const [word, g] = r.split(" ");
  const cls = word === "WIN" ? (g ? "b-warn" : "b-up") : word === "LOSS" ? "b-down" : "b-mute";
  return `<span class="badge ${cls}">${t(word)}${g ? ` <span class="ltr">${g}</span>` : ""}</span>`;
}

async function api(name, body = {}) {
  const r = await fetch("/api/" + name, { method: "POST", headers: { "X-Token": TOKEN, "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(j.error || `HTTP ${r.status}`);
  return j;
}
let toastTimer = 0;
function toast(msg, err = false) {
  const el = $("#toast");
  el.textContent = msg;
  el.className = "toast" + (err ? " err" : "");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (el.textContent = ""), err ? 6000 : 3000);
}
async function act(btn, fn) {
  if (btn) btn.disabled = true;
  try { return await fn(); } catch (e) { toast(e.message, true); } finally { if (btn) btn.disabled = false; }
}

// ------------------------------------------------------------------ live connection
function connectEvents() {
  const es = new EventSource("/api/events?t=" + encodeURIComponent(TOKEN));
  es.addEventListener("state", (e) => {
    const first = !S;
    S = JSON.parse(e.data);
    clockOffset = S.now - Date.now() / 1000;
    if (S.lang !== lang || first) setLang(S.lang, false);
    render();
  });
  es.addEventListener("log", (e) => {
    const lines = JSON.parse(e.data);
    LOG.push(...lines);
    if (LOG.length > 3000) LOG = LOG.slice(-3000);
    appendLog(lines);
  });
}

function setLang(l, save = true) {
  lang = l === "ar" ? "ar" : "en";
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
  mode = "";
  if (save) api("lang", { lang }).catch(() => {});
  render();
}
const langSwitch = () => `<div class="lang-btn" role="group" aria-label="${t("language")}">
  <button data-lang="en" aria-pressed="${lang === "en"}">EN</button><button data-lang="ar" aria-pressed="${lang === "ar"}">ع</button></div>`;

// ------------------------------------------------------------------ render
function render() {
  if (!S) return;
  const want = S.status === "online" ? "app" : "login";
  if (want !== mode) {
    mode = want;
    if (mode === "login") renderLogin(); else renderShell();
  }
  if (mode === "login") updateLogin(); else updateApp();
  renderModal();
}

// ---------- login
async function renderLogin() {
  $("#app").innerHTML = `<div class="login"><form class="login-card" id="login-form" autocomplete="on">
    <div class="login-top"><div class="brand" style="padding:0"><div class="logo">${icon("logo")}</div>QXBot</div>${langSwitch()}</div>
    <div><h1>${t("login_title")}</h1><p class="muted" style="margin:6px 0 0">${t("login_sub")}</p></div>
    <div id="login-busy" class="hidden">
      <div style="display:flex;gap:12px;align-items:center;font-weight:700"><div class="spin"></div>${t("connecting")}</div>
      <p class="muted" style="margin:8px 0 12px">${t("connecting_hint")}</p><div class="mini-log" id="mini-log"></div>
    </div>
    <div id="login-fields" class="form">
      <div id="login-err" class="alert alert-err hidden"></div>
      <label class="field" id="profile-field"><span>${t("profile")}</span><select class="input" id="l-profile"></select></label>
      <label class="field hidden" id="newname-field"><span>${t("profile_name")}</span><input class="input" id="l-newname" maxlength="40"></label>
      <label class="field"><span>${t("email")}</span><input class="input ltr" id="l-email" type="email" autocomplete="username" required></label>
      <label class="field"><span>${t("password")}</span><input class="input ltr" id="l-pass" type="password" autocomplete="current-password"></label>
      <div class="seg" role="group" aria-label="Account">
        <button type="button" data-v="PRACTICE">${t("demo")}</button><button type="button" data-v="REAL">${t("real")}</button></div>
      <div id="real-warn" class="alert alert-warn hidden">${t("real_warn")}</div>
      <label class="check"><input type="checkbox" id="l-remember" checked> ${t("remember")}</label>
      <button class="btn btn-primary btn-big" type="submit" id="l-go">${t("connect")}</button>
    </div></form></div>`;
  const form = $("#login-form");
  form.addEventListener("submit", (e) => { e.preventDefault(); doConnect(); });
  form.querySelectorAll(".seg button").forEach((b) => b.addEventListener("click", () => setAccount(b.dataset.v)));
  $("#l-profile").addEventListener("change", (e) => loadLoginProfile(e.target.value));
  try {
    loginProfiles = await api("profiles");
    const names = loginProfiles.names.length ? loginProfiles.names : ["default"];
    $("#l-profile").innerHTML = names.map((n) => `<option ${n === loginProfiles.last ? "selected" : ""}>${esc(n)}</option>`).join("")
      + `<option value="__new">${t("new_profile")}</option>`;
    await loadLoginProfile(names.includes(loginProfiles.last) ? loginProfiles.last : names[0]);
  } catch (e) { toast(e.message, true); }
  updateLogin();
}
function setAccount(v) {
  loginAccount = v;
  document.querySelectorAll(".seg button").forEach((b) => b.setAttribute("aria-pressed", b.dataset.v === v));
  $("#real-warn").classList.toggle("hidden", v !== "REAL");
}
async function loadLoginProfile(name) {
  const isNew = name === "__new";
  $("#newname-field").classList.toggle("hidden", !isNew);
  loginProfile = isNew ? { email: "", account: "PRACTICE", has_password: false } : await api("profile", { name });
  $("#l-email").value = loginProfile.email || "";
  $("#l-pass").value = "";
  $("#l-pass").placeholder = loginProfile.has_password ? t("password_saved") : "";
  $("#l-pass").required = !loginProfile.has_password;
  setAccount(loginProfile.account || "PRACTICE");
}
function doConnect() {
  const sel = $("#l-profile").value;
  const name = sel === "__new" ? $("#l-newname").value.trim() || "default" : sel;
  act($("#l-go"), () => api("connect", { name, email: $("#l-email").value.trim(), password: $("#l-pass").value,
    account: loginAccount, remember: $("#l-remember").checked }));
}
function updateLogin() {
  const busy = S.status === "connecting";
  $("#login-busy")?.classList.toggle("hidden", !busy);
  $("#login-fields")?.classList.toggle("hidden", busy);
  const err = $("#login-err");
  if (err) { err.textContent = S.status === "error" ? S.error : ""; err.classList.toggle("hidden", S.status !== "error"); }
  const ml = $("#mini-log");
  if (ml) { ml.textContent = LOG.slice(-8).join("\n"); ml.scrollTop = ml.scrollHeight; }
}

// ---------- app shell
const NAV = ["home", "signals", "results", "stats", "settings"];
function renderShell() {
  $("#app").innerHTML = `<div class="shell">
    <nav class="side" aria-label="Main">
      <div class="brand"><div class="logo">${icon("logo")}</div>QXBot</div>
      ${NAV.map((n) => `<button class="nav-btn" data-nav="${n}">${icon(n)}<span>${t(n)}</span>${n === "home" ? '<span class="dot hidden" id="nav-wait"></span>' : ""}</button>`).join("")}
      <div class="side-foot">
        <div class="acct"><div style="display:flex;justify-content:space-between;align-items:center;gap:8px"><span id="acct-badge"></span>
          <span class="badge b-up" id="conn-badge"><span class="pulse"></span>${t("online")}</span></div>
          <div class="bal" id="side-bal" style="margin-top:6px"></div><div class="email ltr" id="side-email"></div></div>
        <div style="display:flex;justify-content:space-between;align-items:center">${langSwitch()}
          <button class="btn btn-ghost btn-sm" id="logout" title="${t("logout")}">${icon("logout")}${t("logout")}</button></div>
      </div>
    </nav>
    <main class="main" id="main"></main></div>`;
  $("#logout").addEventListener("click", () => act($("#logout"), () => api("disconnect")));
  renderView();
}
function go(v) {
  view = NAV.includes(v) ? v : "home";
  history.replaceState(null, "", location.search + "#" + view);
  renderView();
}
function renderView() {
  document.querySelectorAll(".nav-btn").forEach((b) => b.dataset.nav === view ? b.setAttribute("aria-current", "page") : b.removeAttribute("aria-current"));
  const m = $("#main");
  if (!m) return;
  m.innerHTML = `<div class="page">${{ home: homeHTML, signals: signalsHTML, results: resultsHTML, stats: statsHTML, settings: settingsHTML }[view]()}</div>`;
  m.scrollTop = 0;
  ({ signals: initSignals, results: initResults, stats: initStats, settings: initSettings }[view] || (() => {}))();
  updateApp();
}

function updateApp() {
  if (!$("#side-bal")) return;
  const real = S.account === "REAL";
  $("#acct-badge").innerHTML = `<span class="badge ${real ? "b-down" : "b-info"}">${t(real ? "real_b" : "demo_b")}</span>`;
  $("#side-bal").innerHTML = S.balance == null ? "—" : `<span class="num">$${Number(S.balance).toFixed(2)}</span>`;
  $("#side-email").textContent = S.email || "";
  const w = $("#nav-wait");
  w.textContent = S.waiting; w.classList.toggle("hidden", !S.waiting);
  if (view === "home") updateHome();
  if (view === "results" && resTab === "trades") $("#cards").innerHTML = cardsHTML(S.results);
  if (view === "signals") $("#start-btn") && ($("#start-btn").disabled = !(lastPreview && lastPreview.signals.some((s) => !s.dup)));
}

// ---------- home
function homeHTML() {
  return `<div class="page-head"><h1>${t("home")}</h1></div>
  <div class="grid g4">
    <div class="tile"><div class="k">${t("balance")}</div><div class="v" id="h-bal"></div><div class="s" id="h-acct"></div></div>
    <div class="tile"><div class="k">${t("today_profit")}</div><div class="v" id="h-today"></div><div class="s" id="h-today-s"></div></div>
    <div class="tile"><div class="k">${icon("clock").replace("<svg", '<svg width="16" height="16"')}${t("clock")}</div><div class="v" id="h-clock" style="font-size:20px"></div><div class="s ltr" dir="ltr" id="h-clock-s"></div></div>
    <div class="tile"><div class="k">${t("connection")}</div><div class="v" style="font-size:20px"><span class="badge b-up" style="font-size:15px"><span class="pulse"></span>${t("online")}</span></div><div class="s ltr" id="h-email"></div></div>
  </div>
  <div class="card hero" id="hero"></div>
  <div class="grid g2">
    <div class="card"><div class="card-head"><h2>${t("scheduled")}</h2></div><div class="list" id="h-sched"></div></div>
    <div class="card"><div class="card-head"><h2>${t("latest")}</h2><button class="btn btn-ghost btn-sm" data-nav="results">${t("see_all")}</button></div><div class="list" id="h-latest"></div></div>
  </div>`;
}
const localHM = (at) => { const d = new Date(at * 1000); return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`; };
function nextTrade() {
  return S.schedule.filter((x) => x.state === "waiting" && x.at > now() - 60).sort((a, b) => a.at - b.at)[0];
}
function updateHome() {
  const real = S.account === "REAL";
  $("#h-bal").innerHTML = S.balance == null ? "—" : `<span class="num">$${Number(S.balance).toFixed(2)}</span>`;
  $("#h-acct").innerHTML = `<span class="badge ${real ? "b-down" : "b-info"}">${t(real ? "real_b" : "demo_b")}</span>`;
  $("#h-today").innerHTML = `<span class="${S.today > 0 ? "up" : S.today < 0 ? "down" : ""}">${money(S.today, true)}</span>`;
  const w = S.results.filter((r) => r.result.startsWith("WIN")).length, l = S.results.filter((r) => r.result === "LOSS").length;
  $("#h-today-s").textContent = t("wins_losses", { w, l, d: S.results.length - w - l });
  const ok = S.clock_ok;
  $("#h-clock").innerHTML = ok == null ? `<span class="muted">${t("clock_unknown")}</span>` : ok ? `<span class="up">${t("clock_ok")}</span>` : `<span class="warn">${t("clock_bad")}</span>`;
  $("#h-clock-s").textContent = S.clock || "";
  $("#h-clock-s").title = S.clock || "";
  $("#h-email").textContent = S.email || "";
  const n = nextTrade();
  $("#hero").innerHTML = n ? `<div><h3>${t("next_trade")}</h3>
      <div class="pair" style="margin-top:8px">${pair(n.asset)} ${dir(n.direction)} <span class="badge b-mute ltr">M${n.duration / 60}</span></div>
      <div class="count"><span class="num" data-count="${n.at}">${countdown(n.at - now())}</span></div>
      <div class="muted"><span class="num">${localHM(n.at)}</span></div></div>
      <button class="btn btn-stop btn-big" id="stop-btn">${icon("stop")}${t("stop_all")}</button>`
    : `<div><h3>${t("next_trade")}</h3><div class="pair" style="margin-top:8px">${t("no_next")}</div><div class="muted">${t("no_next_sub")}</div></div>
      <button class="btn btn-go btn-big" data-nav="signals">${icon("play")}${t("new_list")}</button>`;
  $("#stop-btn")?.addEventListener("click", stopAll);
  const sched = S.schedule.filter((x) => x.state === "waiting").sort((a, b) => a.at - b.at)
    .concat(S.schedule.filter((x) => x.state !== "waiting").slice(-5).reverse());
  $("#h-sched").innerHTML = sched.length ? sched.slice(0, 8).map((x) => `<div class="row ${x === n ? "next" : ""} ${x.state !== "waiting" ? "dim" : ""}">
      <span class="t num">${localHM(x.at)}</span><span class="a">${pair(x.asset)}</span>${dir(x.direction)}
      <span class="badge ${x.state === "waiting" ? "b-info" : "b-mute"}">${x.state === "waiting" && x.at > now() ? `<span class="num" data-count="${x.at}"></span>` : t(x.state)}</span></div>`).join("")
    : `<div class="empty">${icon("inbox")}${t("nothing_scheduled")}</div>`;
  $("#h-latest").innerHTML = S.results.length ? S.results.slice(0, 5).map((r) => `<div class="row">
      <span class="t num">${esc(r.time.slice(11, 16))}</span><span class="a">${pair(r.asset)}</span>${resultBadge(r.result)}
      <span class="num ${r.profit > 0 ? "up" : r.profit < 0 ? "down" : ""}" style="font-weight:700">${r.profit > 0 ? "+" : ""}${r.profit.toFixed(2)}</span></div>`).join("")
    : `<div class="empty">${icon("results")}${t("none_yet")}</div>`;
  tick();
}
function stopAll() {
  if (!confirm(t("confirm_stop"))) return;
  act($("#stop-btn"), async () => toast(t("stopped", { n: (await api("stop")).cancelled })));
}
function tick() {
  document.querySelectorAll("[data-count]").forEach((el) => (el.textContent = countdown(+el.dataset.count - now())));
}
setInterval(() => { if (S) tick(); }, 250);

// ---------- signals
function signalsHTML() {
  return `<div class="page-head"><h1>${t("signals")}</h1></div>
  <div class="split">
    <div class="card"><div class="card-head"><h2>${t("paste_title")}</h2><button class="btn btn-ghost btn-sm" id="clear-btn">${t("clear")}</button></div>
      <textarea class="input" id="paste" dir="auto" spellcheck="false" placeholder="${esc(t("paste_ph"))}">${esc(draft)}</textarea>
      <div style="display:flex;gap:12px;margin-top:16px;flex-wrap:wrap">
        <button class="btn btn-go btn-big" id="start-btn" style="flex:1" disabled>${icon("play")}${t("start")}</button>
        <button class="btn btn-big" id="bt-btn">${icon("flask")}${t("bt_only")}</button>
      </div>
      <details class="adv" style="margin-top:18px"><summary>${icon("flask").replace("<svg", '<svg width="18" height="18"')}${t("backtest")}</summary>
        <p class="muted" style="margin:10px 0">${t("backtest_sub")}</p>
        <div style="display:flex;gap:12px;align-items:end;flex-wrap:wrap">
          <label class="field" style="flex:1;min-width:160px"><span>${t("backtest_tz")}</span><input class="input ltr" id="bt-tz" placeholder="-3 +1 5.5"></label></div>
      </details>
    </div>
    <div class="grid">
      <div class="card"><div class="card-head"><h2>${t("preview")}</h2><span id="pv-tz"></span></div><div id="preview"></div></div>
      <div id="bt-out"></div>
    </div>
  </div>`;
}
function initSignals() {
  const ta = $("#paste");
  ta.addEventListener("input", () => { draft = ta.value; clearTimeout(previewTimer); previewTimer = setTimeout(runPreview, 250); });
  $("#clear-btn").addEventListener("click", () => { draft = ta.value = ""; runPreview(); ta.focus(); });
  $("#start-btn").addEventListener("click", () => act($("#start-btn"), async () => {
    const r = await api("start", { text: draft });
    toast(t("started", { n: r.scheduled }));
    if (r.scheduled) { draft = ""; go("home"); }
  }));
  $("#bt-btn").addEventListener("click", runBacktest);
  runPreview();
  ta.focus();
}
async function runPreview() {
  const el = $("#preview");
  if (!el) return;
  if (!draft.trim()) {
    lastPreview = null;
    el.innerHTML = `<div class="empty">${icon("signals")}${t("empty_preview")}</div>`;
    $("#pv-tz").innerHTML = "";
    updateApp();
    return;
  }
  try { lastPreview = await api("preview", { text: draft }); } catch (e) { el.innerHTML = `<div class="alert alert-err">${esc(e.message)}</div>`; return; }
  const p = lastPreview, today = new Date(now() * 1000).toDateString();
  $("#pv-tz").innerHTML = `<span class="badge b-mute" title="${p.tz_from_list ? t("tz_list") : t("tz_profile")}">${t("tz")} <span class="ltr">${esc(p.tz)}</span></span>`;
  const sig = (s, past) => `<div class="row ${s.dup || past ? "dim" : ""}"><span class="t num">${esc(s.time)}</span>
      <span class="a">${pair(s.asset)} ${s.dup ? `<small class="warn">· ${t("dup")}</small>` : ""}${!past && new Date(s.at * 1000).toDateString() !== today ? `<small class="muted"> · ${t("tomorrow")}</small>` : ""}</span>
      ${dir(s.direction)}<span class="badge b-mute">${past ? t("passed") : `<span class="num" data-count="${s.at}"></span>`}</span></div>`;
  el.innerHTML = `<div class="chips" style="margin-bottom:14px">
      <span class="badge b-up">${t("upcoming")} <span class="num">${p.signals.length}</span></span>
      ${p.passed.length ? `<span class="badge b-mute">${t("passed")} <span class="num">${p.passed.length}</span></span>` : ""}
      ${p.unknown.length ? `<span class="badge b-warn">${t("unknown").split(" (")[0]} <span class="num">${p.unknown.length}</span></span>` : ""}</div>
    <div class="list">${p.signals.map((s) => sig(s, false)).join("")}</div>
    ${p.unknown.length ? `<h3 style="margin:18px 0 8px">${t("unknown")}</h3><div class="list">${p.unknown.map((u) => `<div class="unk">${esc(u)}</div>`).join("")}</div>` : ""}
    ${p.passed.length ? `<h3 style="margin:18px 0 8px">${t("passed")}</h3><div class="list">${p.passed.map((s) => sig(s, true)).join("")}</div>` : ""}
    ${p.checked ? "" : `<p class="faint" style="margin:14px 0 0;font-size:13px">${t("not_checked")}</p>`}`;
  tick();
  updateApp();
}
async function runBacktest() {
  const out = $("#bt-out");
  out.innerHTML = `<div class="card" style="display:flex;gap:12px;align-items:center"><div class="spin"></div>${t("running_bt")}</div>`;
  await act($("#bt-btn"), async () => {
    const r = await api("backtest", { text: draft, offsets: $("#bt-tz").value });
    if (!$("#bt-out")) return;
    $("#bt-out").innerHTML = r.runs.map((run) => `<div class="card"><div class="card-head"><h2>${t("backtest")} <span class="badge b-mute ltr">${esc(run.tz)}</span></h2>
        <span class="muted">${t("wins_losses", { w: run.wins, l: run.losses, d: run.draws })}${run.wins + run.losses ? ` · ${pct(100 * run.wins / (run.wins + run.losses))}` : ""}</span></div>
        <div class="list">${run.rows.map((s) => `<div class="row"><span class="t num">${esc(s.time)}</span><span class="a">${pair(s.asset)}</span>${dir(s.direction)}
        ${s.result === "no data" ? '<span class="badge b-mute">—</span>' : resultBadge(s.result)}</div>`).join("")}</div></div>`).join("");
  });
  if ($("#bt-out")?.querySelector(".spin")) $("#bt-out").innerHTML = "";
}

// ---------- results
function resultsHTML() {
  return `<div class="page-head"><h1>${t("results")}</h1>
    <div class="tabs" role="tablist"><button role="tab" data-tab="trades" aria-selected="${resTab === "trades"}">${t("trades_tab")}</button>
    <button role="tab" data-tab="log" aria-selected="${resTab === "log"}">${t("log_tab")}</button></div></div>
    ${resTab === "trades" ? `<div class="cards" id="cards"></div>`
      : `<div style="display:flex;justify-content:flex-end"><button class="btn btn-sm" id="copy-log">${t("copy")}</button></div><div class="log" id="log" role="log"></div>`}`;
}
function cardsHTML(cards) {
  if (!cards.length) return `<div class="card empty" style="grid-column:1/-1">${icon("results")}${t("none_yet")}</div>`;
  return cards.map((c) => {
    const cls = c.result.startsWith("WIN") ? (c.result.includes("G") ? "gale" : "win") : c.result.startsWith("LOSS") ? "loss" : "";
    return `<div class="rcard ${cls}"><div class="top"><span style="font-weight:700">${pair(c.asset)}</span>${resultBadge(c.result)}</div>
      <div class="p num ${c.profit > 0 ? "up" : c.profit < 0 ? "down" : ""}">${c.profit > 0 ? "+" : ""}${c.profit.toFixed(2)}</div>
      <div class="top muted" style="font-size:13px"><span>${dir(c.direction)} <span class="num">${esc(c.time.slice(11, 16))}</span></span><span class="num">$${c.amount.toFixed(2)}</span></div></div>`;
  }).join("");
}
function initResults() {
  document.querySelectorAll("[data-tab]").forEach((b) => b.addEventListener("click", () => { resTab = b.dataset.tab; renderView(); }));
  const log = $("#log");
  if (log) {
    log.innerHTML = LOG.map(logLine).join("");
    log.scrollTop = log.scrollHeight;
    $("#copy-log").addEventListener("click", () => navigator.clipboard.writeText(LOG.join("\n")).then(() => toast(t("copied"))));
  }
}
function logLine(l) {
  const cls = /: WIN|\bWIN\b/.test(l) ? "l-win" : /: LOSS|REJECTED|ERROR|failed|WARNING/i.test(l) ? "l-loss" : /skipped|cancelled|lost/i.test(l) ? "l-warn" : "";
  return `<div class="${cls}"><span class="l-time">${esc(l.slice(0, 8))}</span>${esc(l.slice(8))}</div>`;
}
function appendLog(lines) {
  const log = $("#log");
  if (log) {
    const atEnd = log.scrollHeight - log.scrollTop - log.clientHeight < 40;
    log.insertAdjacentHTML("beforeend", lines.map(logLine).join(""));
    if (atEnd) log.scrollTop = log.scrollHeight;
  }
  if (mode === "login" && S) updateLogin();
}

// ---------- stats
function statsHTML() {
  return `<div class="page-head"><h1>${t("stats")}</h1>
    <div class="tabs" role="tablist"><button role="tab" data-tab="bot" aria-selected="${statTab === "bot"}">${t("bot_stats")}</button>
    <button role="tab" data-tab="quotex" aria-selected="${statTab === "quotex"}">${t("quotex_history")}</button></div></div><div id="stats-body" class="grid"></div>`;
}
function summaryTiles(m) {
  const tile = (k, v, s = "") => `<div class="tile"><div class="k">${t(k)}</div><div class="v">${v}</div>${s ? `<div class="s">${s}</div>` : ""}</div>`;
  return `<div class="grid g4">
    ${tile("trades", `<span class="num">${m.trades}</span>`, t("wins_losses", { w: m.wins, l: m.losses, d: m.draws }))}
    ${tile("win_rate", pct(m.win_rate), `${t("signals_won")}: <span class="num">${m.signals_won}/${m.signals_won + m.signals_lost}</span>`)}
    ${tile("net", `<span class="${m.net > 0 ? "up" : m.net < 0 ? "down" : ""}">${money(m.net, true)}</span>`, `${t("roi")} <span class="num">${m.roi > 0 ? "+" : ""}${Math.round(m.roi)}%</span>`)}
    ${tile("drawdown", money(m.max_drawdown), `${t("streak")}: <span class="num">${m.loss_streak}</span>`)}</div>`;
}
async function initStats() {
  document.querySelectorAll("[data-tab]").forEach((b) => b.addEventListener("click", () => { statTab = b.dataset.tab; renderView(); }));
  const body = $("#stats-body");
  if (statTab === "quotex") {
    body.innerHTML = `<div class="card"><div class="card-head"><div><h2>${t("quotex_history")}</h2><p class="muted" style="margin:4px 0 0">${t("history_sub")}</p></div>
      <button class="btn btn-primary" id="hist-btn">${t("load")}</button></div><div id="hist"></div></div>`;
    $("#hist-btn").addEventListener("click", () => act($("#hist-btn"), async () => {
      const r = await api("history");
      $("#hist").innerHTML = summaryTiles(r.summary) + (r.rows.length ? `<div style="overflow-x:auto;margin-top:16px"><table class="table"><thead><tr><th>${t("time")}</th><th>${t("pair")}</th><th>${t("amount_c")}</th><th>${t("result")}</th><th>${t("profit")}</th></tr></thead><tbody>
        ${r.rows.map((x) => `<tr><td class="num">${esc(x.time.slice(11, 19))}</td><td>${pair(x.asset)}</td><td class="num">${Number(x.amount).toFixed(2)}</td><td>${resultBadge(x.result.toUpperCase())}</td>
        <td class="num ${x.profit > 0 ? "up" : x.profit < 0 ? "down" : ""}">${x.profit > 0 ? "+" : ""}${Number(x.profit).toFixed(2)}</td></tr>`).join("")}</tbody></table></div>` : "");
    }));
    return;
  }
  const r = await api("stats").catch((e) => toast(e.message, true));
  if (!r || !$("#stats-body")) return;
  const sec = (k, m) => `<div class="grid" style="gap:10px"><h3>${t(k)}</h3>${summaryTiles(m)}</div>`;
  body.innerHTML = sec("session", r.session) + sec("today", r.today) + sec("all", r.all) + `<div class="grid g2">
    <div class="card"><h2 style="margin-bottom:12px">${t("by_step")}</h2><table class="table"><tbody>${r.levels.map((x) => `<tr><td class="ltr">G${esc(x.level)}</td><td class="num">${x.wins}/${x.trades}</td></tr>`).join("") || `<tr><td class="muted">—</td></tr>`}</tbody></table></div>
    <div class="card"><h2 style="margin-bottom:12px">${t("pairs")}</h2><div style="max-height:360px;overflow:auto"><table class="table"><thead><tr><th>${t("pair")}</th><th>${t("trades")}</th><th>${t("win_rate")}</th><th>${t("net")}</th></tr></thead><tbody>
    ${r.pairs.map((m) => `<tr><td>${pair(m.asset)}</td><td class="num">${m.trades}</td><td>${pct(m.win_rate)}</td><td class="${m.net > 0 ? "up" : m.net < 0 ? "down" : ""}">${money(m.net, true)}</td></tr>`).join("")}</tbody></table></div></div></div>`;
}

// ---------- settings
const ESSENTIAL = [["amount", "number"], ["utc_offset", "number"], ["gales", "number"], ["gale_multiplier", "number"],
  ["stop_loss", "number"], ["take_profit", "number"], ["min_payout", "number"]];
const ADVANCED = [["pending", "check"], ["overlap", "check"], ["headless", "check"], ["pre_entry_ms", "text"], ["safe_pips", "number"],
  ["proxy", "text"], ["host", "text"]];
function settingsHTML() {
  const f = ([k, type]) => type === "check"
    ? `<label class="check"><input type="checkbox" name="${k}"> ${t(k)}</label>`
    : `<label class="field"><span>${t(k)}</span><input class="input" name="${k}" type="text" ${type === "number" ? 'inputmode="decimal"' : ""} dir="ltr" spellcheck="false">
       ${k === "utc_offset" ? `<small>${t("utc_hint")}</small>` : ""}</label>`;
  return `<div class="page-head"><h1>${t("settings")}</h1><span class="badge b-mute">${t("profile")}: <span class="ltr">${esc(S.profile)}</span></span></div>
  <form class="card form" id="set-form"><h2>${t("essentials")}</h2><p class="muted" style="margin:-8px 0 0">${t("account_note")}</p>
    <div class="form-grid">${ESSENTIAL.map(f).join("")}</div>
    <details class="adv"><summary>${t("advanced")}</summary><div class="form-grid">${ADVANCED.map(f).join("")}</div></details>
    <div><button class="btn btn-primary" type="submit" id="set-save">${t("save")}</button></div></form>
  <div class="card form"><h2>${t("app_section")}</h2>
    <div style="display:flex;gap:16px;align-items:center;flex-wrap:wrap"><span class="muted">${t("language")}</span>${langSwitch()}
    <button class="btn" id="shortcut-btn" style="margin-inline-start:auto">${t("shortcut")}</button></div></div>`;
}
async function initSettings() {
  const form = $("#set-form");
  const p = await api("profile", { name: S.profile }).catch((e) => toast(e.message, true));
  if (!p || !$("#set-form")) return;
  for (const el of form.elements) {
    if (!el.name) continue;
    if (el.type === "checkbox") el.checked = p[el.name] === "y"; else el.value = p[el.name];
  }
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const body = { name: S.profile };
    for (const el of form.elements) if (el.name) body[el.name] = el.type === "checkbox" ? (el.checked ? "y" : "n") : el.value;
    act($("#set-save"), async () => { await api("settings", body); toast(t("saved")); });
  });
  $("#shortcut-btn").addEventListener("click", () => act($("#shortcut-btn"), async () => { await api("shortcut"); toast(t("shortcut_done")); }));
}

// ------------------------------------------------------------------ modals
function renderModal() {
  const m = $("#modal");
  const want = S.pin ? "pin" : S.closing ? "quit" : "";
  if (m.dataset.kind === want) return;
  m.dataset.kind = want;
  if (want === "pin") {
    m.innerHTML = `<div class="overlay"><form class="modal" id="pin-form" role="dialog" aria-modal="true" aria-labelledby="pin-t">
      <h2 id="pin-t">${t("pin_title")}</h2><p class="muted" style="margin:0">${t("pin_sub")}</p>
      <input class="input pin-input" id="pin" inputmode="numeric" autocomplete="one-time-code" maxlength="12" required>
      <button class="btn btn-primary btn-big" id="pin-go">${t("send")}</button></form></div>`;
    $("#pin").focus();
    $("#pin-form").addEventListener("submit", (e) => { e.preventDefault(); act($("#pin-go"), () => api("pin", { pin: $("#pin").value })); });
  } else if (want === "quit") {
    m.innerHTML = `<div class="overlay"><div class="modal" role="dialog" aria-modal="true" aria-labelledby="q-t">
      <h2 id="q-t">${t("quit_title")}</h2><p class="muted" style="margin:0">${t("quit_body", { n: S.waiting })}</p>
      <button class="btn btn-stop btn-big" id="q-stop">${t("quit_stop")}</button><button class="btn" id="q-keep">${t("quit_keep")}</button></div></div>`;
    $("#q-stop").addEventListener("click", () => act($("#q-stop"), () => api("quit", { stop: true })));
    $("#q-keep").addEventListener("click", () => act($("#q-keep"), () => api("cancel_quit")));
    $("#q-keep").focus();
  } else m.innerHTML = "";
}

// ------------------------------------------------------------------ global events
document.addEventListener("click", (e) => {
  const nav = e.target.closest("[data-nav]");
  if (nav) { e.preventDefault(); go(nav.dataset.nav); }
  const lb = e.target.closest("[data-lang]");
  if (lb) setLang(lb.dataset.lang);
});
window.addEventListener("beforeunload", (e) => { if (S && S.waiting && !window.pywebview) { e.preventDefault(); e.returnValue = ""; } });
connectEvents();
