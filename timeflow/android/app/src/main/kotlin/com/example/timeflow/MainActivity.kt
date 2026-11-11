package com.example.timeflow

import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "timeflow/session_clock",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getSnapshot") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bootCount = runCatching {
                Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT)
            }.getOrNull()
            result.success(
                mapOf(
                    "elapsedRealtimeMillis" to SystemClock.elapsedRealtime(),
                    "bootCount" to bootCount,
                ),
            )
        }
    }
}
