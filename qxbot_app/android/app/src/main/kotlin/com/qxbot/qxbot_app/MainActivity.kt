package com.qxbot.qxbot_app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * The trading engine runs in this Flutter engine's Dart isolate. By default FlutterActivity destroys
     * its engine in onDestroy, and Back on the first screen calls finish(): trading stopped while the
     * foreground service notification stayed. An engine provided here is not destroyed with the activity
     * (shouldDestroyEngineWithHost = false): it keeps running while the foreground service keeps the process,
     * and a new activity (app reopened) attaches to the same running engine.
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine =
        FlutterEngineCache.getInstance().get(ENGINE)
            ?: FlutterEngine(context.applicationContext).also { FlutterEngineCache.getInstance().put(ENGINE, it) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qxbot/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "brand" -> result.success(Build.MANUFACTURER.lowercase())
                // args: list of "package/class" component names; opens the first that exists, else app info
                "open" -> result.success(openFirst(call.arguments as List<*>))
                else -> result.notImplemented()
            }
        }
    }

    private fun openFirst(components: List<*>): Boolean {
        for (c in components) {
            val name = ComponentName.unflattenFromString(c as String) ?: continue
            val i = Intent().setComponent(name).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra("package_name", packageName).putExtra("package_label", "QXBot")
            try { // no resolveActivity(): Android 11+ package visibility would hide OEM apps
                startActivity(i)
                return true
            } catch (_: Exception) { } // not on this phone, not exported or not allowed: try the next one
        }
        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return false
    }

    companion object { const val ENGINE = "main" }
}
