package com.maoneart.maoneauto

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.maoneart.maoneauto/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Pastikan component dan rebind aktif sejak app diinisialisasi
        enableNotificationService()
        rebindNotificationService()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableNotificationComponent" -> {
                    enableNotificationService()
                    rebindNotificationService()
                    result.success(true)
                }
                "isNotificationServiceEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "isListenerConnected" -> {
                    result.success(MaoneAutoNotificationService.isServiceConnected)
                }
                "openNotificationSettings" -> {
                    enableNotificationService()
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open settings: ${e.message}", null)
                    }
                }
                "openAppDetailsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open app details: ${e.message}", null)
                    }
                }
                "rebindService" -> {
                    forceReconnectService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        enableNotificationService()
        rebindNotificationService()
    }

    private fun enableNotificationService() {
        try {
            val componentName = ComponentName(this, MaoneAutoNotificationService::class.java)
            val currentState = packageManager.getComponentEnabledSetting(componentName)
            if (currentState != PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                packageManager.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error enabling component: ${e.message}")
        }
    }

    private fun rebindNotificationService() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                if (isNotificationServiceEnabled()) {
                    val componentName = ComponentName(this, MaoneAutoNotificationService::class.java)
                    NotificationListenerService.requestRebind(componentName)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error requesting rebind: ${e.message}")
        }
    }

    private fun forceReconnectService() {
        try {
            val componentName = ComponentName(this, MaoneAutoNotificationService::class.java)
            val pm = packageManager
            pm.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            pm.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                NotificationListenerService.requestRebind(componentName)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error forcing reconnect: ${e.message}")
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        try {
            val packages = androidx.core.app.NotificationManagerCompat.getEnabledListenerPackages(this)
            if (packages.contains(packageName)) {
                return true
            }
        } catch (_: Exception) {}

        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }
}
