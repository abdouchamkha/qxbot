/// "Background setup": checks what keeps the bot alive with the screen off and opens the right system screens.
library;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

/// Brand family of the phone, its display name, instructions and the OEM screens to try ("package/class").
/// The screens are well-known component names; when none exists the app info page opens instead.
({String name, String help, List<String> screens}) brandSetup(L l, String manufacturer) {
  final m = manufacturer.toLowerCase();
  if (RegExp('xiaomi|redmi|poco').hasMatch(m)) {
    return (name: 'Xiaomi', help: l.bgXiaomi, screens: [
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      'com.miui.powerkeeper/com.miui.powerkeeper.ui.HiddenAppsConfigActivity',
    ]);
  }
  if (RegExp('huawei|honor').hasMatch(m)) {
    return (name: m.contains('honor') ? 'Honor' : 'Huawei', help: l.bgHuawei, screens: [
      'com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
      'com.huawei.systemmanager/com.huawei.systemmanager.optimize.process.ProtectActivity',
      'com.huawei.systemmanager/com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity',
      'com.hihonor.systemmanager/com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
    ]);
  }
  if (RegExp('oppo|realme|oneplus').hasMatch(m)) {
    return (name: m[0].toUpperCase() + m.substring(1), help: l.bgOppo, screens: [
      'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
      'com.coloros.safecenter/com.coloros.safecenter.startupapp.StartupAppListActivity',
      'com.oppo.safe/com.oppo.safe.permission.startup.StartupAppListActivity',
      'com.oneplus.security/com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
    ]);
  }
  if (RegExp('vivo|iqoo').hasMatch(m)) {
    return (name: 'Vivo', help: l.bgVivo, screens: [
      'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
      'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
      'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.BgStartUpManager',
    ]);
  }
  if (m.contains('samsung')) {
    return (name: 'Samsung', help: l.bgSamsung, screens: [
      'com.samsung.android.lool/com.samsung.android.sm.battery.ui.BatteryActivity',
      'com.samsung.android.sm/com.samsung.android.sm.battery.ui.BatteryActivity',
    ]);
  }
  return (name: '', help: l.bgOther, screens: const []);
}

class BackgroundSetupBody extends StatelessWidget {
  final AppState app;
  const BackgroundSetupBody(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context), b = brandSetup(l, app.brand), st = app.bg;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.bgIntro, style: const TextStyle(fontSize: 16, height: 1.45, color: textMid)),
        gap16,
        _Step(Icons.notifications_active_outlined, l.bgNotif, l.bgNotifSub, app.bg?.notifications, l.allow,
            app.requestNotifications),
        _Step(Icons.battery_charging_full, l.bgBattery, l.bgBatterySub, st?.battery, l.allow, app.requestBattery),
        _Step(Icons.phone_android, b.name.isEmpty ? l.bgBrandGeneric : l.bgBrand(b.name), b.help, null, l.openSettings,
            () => app.openSystemScreen(b.screens)),
        gap8,
        Panel(color: card2, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline, color: amber),
          gap12,
          Expanded(child: Text('${l.bgTips}\n\n${l.bgPending}', style: const TextStyle(fontSize: 14, height: 1.45, color: textMid))),
        ])),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title, sub, action;
  final bool? ok; // null = can't be checked
  final VoidCallback onTap;
  const _Step(this.icon, this.title, this.sub, this.ok, this.action, this.onTap);

  @override
  Widget build(BuildContext context) => Panel(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ok == true ? Icons.check_circle : icon, color: ok == true ? green : ok == false ? amber : textMid, size: 28),
          gap12,
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textHi)),
              gap4,
              Text(sub, style: const TextStyle(fontSize: 14, height: 1.4, color: textMid)),
            ]),
          ),
          gap8,
          ok == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(L.of(context).allowed, style: const TextStyle(color: green, fontWeight: FontWeight.w700)))
              : FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size(64, 48)), onPressed: onTap, child: Text(action)),
        ]),
      );
}

class BackgroundSetupPage extends StatelessWidget {
  final AppState app;
  const BackgroundSetupPage(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bgTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          BackgroundSetupBody(app),
          gap8,
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
        ]),
      ),
    );
  }
}
