package com.maoneart.maoneauto

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

object ServiceLogManager {
    val logs = java.util.concurrent.CopyOnWriteArrayList<String>()

    fun log(msg: String) {
        val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(java.util.Date())
        val entry = "[$time] $msg"
        logs.add(entry)
        while (logs.size > 50) {
            logs.removeAt(0)
        }
        Log.i("MaoneAutoService", msg)
    }

    fun getLogs(): List<String> = logs.toList()
    fun clearLogs() = logs.clear()
}

class MaoneAutoNotificationService : NotificationListenerService() {

    companion object {
        var isServiceConnected: Boolean = false
        var instance: MaoneAutoNotificationService? = null

        fun simulateTestReply(sender: String, messageText: String, prefs: android.content.SharedPreferences): String {
            try {
                val service = instance ?: MaoneAutoNotificationService()
                ServiceLogManager.log("🧪 [TEST SIMULASI] Pesan masuk dari '$sender': '$messageText'")
                val reply = service.computeReply(sender, messageText, prefs)
                if (reply.isNullOrBlank()) {
                    ServiceLogManager.log("⚠️ [TEST SIMULASI] Tidak ada balasan yang cocok untuk '$messageText'")
                    return "⚠️ Tidak ada balasan yang cocok."
                }
                ServiceLogManager.log("✅ [TEST SIMULASI] Balasan dihasilkan: '$reply'")
                return reply
            } catch (t: Throwable) {
                ServiceLogManager.log("❌ [TEST SIMULASI] Error: ${t.message}")
                return "Error: ${t.message}"
            }
        }
    }

    private val TAG = "MaoneAutoService"
    private val processedKeys = mutableMapOf<String, Long>()
    private val lastReplyPerSender = mutableMapOf<String, Long>()
    private val recentSentReplies = java.util.concurrent.ConcurrentHashMap<String, Long>()

    override fun onCreate() {
        super.onCreate()
        instance = this
        try {
            val policy = android.os.StrictMode.ThreadPolicy.Builder().permitAll().build()
            android.os.StrictMode.setThreadPolicy(policy)
        } catch (_: Exception) {}
        ServiceLogManager.log("🚀 Service onCreate() diinisialisasi")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        ServiceLogManager.log("🛑 Service onDestroy() dihentikan")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isServiceConnected = true
        instance = this
        ServiceLogManager.log("🟢 Listener Notifikasi TERHUBUNG ke Android!")
        Log.i(TAG, "MaoneAutoNotificationService listener connected successfully!")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isServiceConnected = false
        ServiceLogManager.log("🔴 Listener Notifikasi TERPUTUS dari Android!")
        Log.w(TAG, "MaoneAutoNotificationService listener disconnected!")
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                requestRebind(android.content.ComponentName(this, MaoneAutoNotificationService::class.java))
            }
        } catch (_: Exception) {}
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        try {
            val packageName = sbn.packageName ?: return
            val supportedPackages = listOf(
                "com.whatsapp",
                "com.whatsapp.w4b",
                "org.telegram.messenger",
                "com.facebook.orca"
            )

            if (!supportedPackages.contains(packageName)) return

            val notification = sbn.notification ?: return

            // 1. Abaikan notifikasi sistem atau ongoing event (panggilan telepon, backup, uploading)
            if ((notification.flags and Notification.FLAG_ONGOING_EVENT) != 0) return

            // 2. Baca pengaturan dari Flutter SharedPreferences
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("flutter.is_auto_reply_enabled", true)
            if (!isEnabled) {
                ServiceLogManager.log("⏸️ Abaikan: Balasan Otomatis sedang MATI di sakelar aplikasi")
                return
            }

            // 2a. Filter Aplikasi yang Didukung (Supported Apps)
            val supportedAppsJson = prefs.getString("flutter.supported_apps", null)
            if (!supportedAppsJson.isNullOrEmpty()) {
                try {
                    val supportedAppsObj = JSONObject(supportedAppsJson)
                    val isAppAllowed = when (packageName) {
                        "com.whatsapp" -> supportedAppsObj.optBoolean("WhatsApp", true)
                        "com.whatsapp.w4b" -> supportedAppsObj.optBoolean("WhatsApp Business", true)
                        "org.telegram.messenger" -> supportedAppsObj.optBoolean("Telegram", false)
                        "com.facebook.orca" -> supportedAppsObj.optBoolean("Messenger", false)
                        else -> true
                    }
                    if (!isAppAllowed) {
                        ServiceLogManager.log("⏸️ Abaikan: Aplikasi $packageName dinonaktifkan di pengaturan")
                        return
                    }
                } catch (_: Exception) {}
            }

            val extras = notification.extras ?: return

            // Ekstraksi Title & Text secara aman (MessagingStyle + CharSequence + SpannableString)
            var rawTitle = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                ?: extras.getString(Notification.EXTRA_TITLE) ?: ""
            if (rawTitle.isEmpty()) {
                rawTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString() ?: ""
            }

            var rawText = ""
            try {
                val messagingStyle = androidx.core.app.NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification)
                if (messagingStyle != null && messagingStyle.messages.isNotEmpty()) {
                    val lastMsg = messagingStyle.messages.lastOrNull()
                    if (lastMsg != null) {
                        val selfDisplayName = extras.getCharSequence("android.selfDisplayName")?.toString()
                        val person = lastMsg.person
                        val personName = person?.name?.toString()

                        // Jika person == null atau sama dengan selfDisplayName, berarti pesan terakhir dikirim oleh diri sendiri/bot (echo)
                        val isSelf = person == null || (selfDisplayName != null && personName.equals(selfDisplayName, ignoreCase = true))
                        if (isSelf) {
                            ServiceLogManager.log("⏸️ Abaikan: Pesan terakhir di chat dikirim oleh diri sendiri/bot (echo)")
                            return
                        }

                        if (!lastMsg.text.isNullOrBlank()) {
                            rawText = lastMsg.text.toString()
                            if (!personName.isNullOrBlank() && (rawTitle.isEmpty() || rawTitle.equals("WhatsApp", ignoreCase = true) || rawTitle.equals("WA Business", ignoreCase = true))) {
                                rawTitle = personName
                            }
                        }
                    }
                }
            } catch (_: Exception) {}

            if (rawText.isEmpty()) {
                rawText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                    ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            }
            if (rawText.isEmpty()) {
                val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                if (textLines != null && textLines.isNotEmpty()) {
                    rawText = textLines.lastOrNull()?.toString() ?: ""
                }
            }
            if (rawText.isEmpty()) {
                try {
                    val parcelables = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                        extras.getParcelableArray(Notification.EXTRA_MESSAGES, android.os.Parcelable::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                    }
                    if (parcelables != null && parcelables.isNotEmpty()) {
                        val msgs = Notification.MessagingStyle.Message.getMessagesFromBundleArray(parcelables)
                        val last = msgs.lastOrNull()
                        if (last != null && !last.text.isNullOrBlank()) {
                            rawText = last.text.toString()
                        }
                    }
                } catch (_: Exception) {}
            }

            if (rawTitle.isEmpty() || rawText.isEmpty()) return
            if (rawTitle.contains("WhatsApp", ignoreCase = true) && rawText.contains("checking for new messages", ignoreCase = true)) return

            // Bersihkan prefix WA Business / WhatsApp dan format "(1 pesan)" persis WhatsAuto asli
            var cleanSender = rawTitle.replace("WA Business:", "").replace("WhatsApp:", "").trim()
            if (cleanSender.matches(Regex("^.+ \\(\\d+ \\S+\\)$")) && cleanSender.lastIndexOf('(') != -1) {
                cleanSender = cleanSender.substring(0, cleanSender.lastIndexOf('('))
            }
            cleanSender = cleanSender.replace(Regex("[\u200e\u2068\u2069]"), "").trim()
            val cleanMsg = rawText.replace(Regex("[\u200e\u2068\u2069]"), "").trim()

            ServiceLogManager.log("📩 Notif masuk dari $packageName: '$cleanSender' -> '$cleanMsg'")

            // 2c. Deteksi & Filter Pesan Grup WhatsApp (Akurat menggunakan EXTRA_IS_GROUP_CONVERSATION)
            val isGroup = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                extras.getBoolean(Notification.EXTRA_IS_GROUP_CONVERSATION, false)
            } else {
                cleanSender.contains(" @ ")
            }
            val enableGroups = prefs.getBoolean("flutter.enable_groups", false)
            if (isGroup && !enableGroups) {
                ServiceLogManager.log("👥 Abaikan pesan grup '$cleanSender' karena fitur Grup dinonaktifkan")
                return
            }

            // 2d. Filter Kontak (Kecuali Kontak Telepon / Unknown Number Only)
            val replyTo = prefs.getString("flutter.reply_to", "all") ?: "all"
            val isPhoneNumber = cleanSender.replace(Regex("[+0-9\\s\\-()]"), "").isEmpty()
            if (replyTo == "except_phone" && !isPhoneNumber) {
                ServiceLogManager.log("👤 Abaikan '$cleanSender': hanya membalas nomor baru (Kecuali Kontak Telepon)")
                return
            }

            val now = System.currentTimeMillis()

            // 2b. Abaikan jika pesan ini adalah balasan yang baru saja dikirim oleh bot (echo)
            val cleanMsgNorm = cleanMsg.lowercase()
            val sentTime = recentSentReplies[cleanMsgNorm]
            if (sentTime != null && (now - sentTime) < 15000) {
                ServiceLogManager.log("⏸️ Abaikan echo: Pesan '$cleanMsg' adalah balasan bot (${now - sentTime}ms lalu)")
                return
            }

            // Abaikan teks ringkasan notifikasi sistem WhatsApp ("1 pesan baru", "2 pesan baru", dsb)
            val isSummaryText = cleanMsg.matches(Regex("(?i)^\\d+\\s+pesan(\\s+baru)?$")) ||
                                cleanMsg.matches(Regex("(?i)^\\d+\\s+new\\s+messages?$")) ||
                                cleanMsg.equals("1 pesan baru", ignoreCase = true) ||
                                cleanMsg.equals("1 new message", ignoreCase = true)
            if (isSummaryText) {
                ServiceLogManager.log("ℹ️ Abaikan teks ringkasan notifikasi: '$cleanMsg'")
                return
            }

            // 3. Debounce per-pengirim: jangan balas lebih dari 1 kali dalam 3 detik untuk pengirim yang sama
            val lastSenderReply = lastReplyPerSender[cleanSender] ?: 0L
            if (now - lastSenderReply < 3000) {
                ServiceLogManager.log("⏳ Debounce aktif untuk '$cleanSender' (${now - lastSenderReply}ms lalu)")
                return
            }

            // 4. Deduplikasi pesan identik dalam 3 detik
            val messageKey = "$packageName:$cleanSender:$cleanMsg"
            val lastSeen = processedKeys[messageKey] ?: 0L
            if (now - lastSeen < 3000) {
                ServiceLogManager.log("🔁 Duplikat terdeteksi untuk '$cleanSender': '$cleanMsg' (${now - lastSeen}ms lalu)")
                return
            }

            // 5. Cari Quick Reply Action dengan RemoteInput (actions standar + fallback WearableExtender)
            val quickReplyAction = findQuickReplyAction(notification)
            if (quickReplyAction == null) {
                if (cleanSender.equals("WhatsApp", ignoreCase = true) || cleanSender.equals("WA Business", ignoreCase = true)) {
                    ServiceLogManager.log("ℹ️ Notifikasi ringkasan sistem '$cleanSender' diabaikan")
                    return
                }
                ServiceLogManager.log("⚠️ Notifikasi dari '$cleanSender' tidak memiliki Action Balas Cepat (RemoteInput)")
                return
            }

            // 6. Hitung teks balasan dengan Tree Menu & Rule Kata Kunci
            val replyText = computeReply(cleanSender, cleanMsg, prefs)
            if (replyText.isNullOrBlank()) {
                ServiceLogManager.log("ℹ️ Tidak ada aturan balasan untuk '$cleanMsg' dari '$cleanSender'")
                return
            }

            // 7. Tambahkan Header & Footer jika diaktifkan (persis WhatsAuto asli)
            val enableHeader = prefs.getBoolean("flutter.enable_reply_header", false)
            val headerText = prefs.getString("flutter.reply_header_text", "*[Balasan Otomatis]*\n") ?: "*[Balasan Otomatis]*\n"
            val enableFooter = prefs.getBoolean("flutter.enable_reply_footer", false)
            val footerText = prefs.getString("flutter.reply_footer_text", "\n_Terkirim via MaoneAuto_") ?: "\n_Terkirim via MaoneAuto_"

            var finalReply = replyText
            if (enableHeader && headerText.isNotBlank()) {
                finalReply = headerText.trimEnd() + "\n" + finalReply
            }
            if (enableFooter && footerText.isNotBlank()) {
                finalReply = finalReply + "\n" + footerText.trimStart()
            }

            // 8. Cek Mode Timer / Delay / Once
            val replyTimeMode = prefs.getString("flutter.reply_time_mode", "instantly") ?: "instantly"
            val replyDelaySeconds = try {
                prefs.getInt("flutter.reply_delay_seconds", 0)
            } catch (_: Exception) {
                try {
                    prefs.getLong("flutter.reply_delay_seconds", 0L).toInt()
                } catch (_: Exception) {
                    0
                }
            }

            if (replyTimeMode == "once") {
                val hasRepliedKey = "flutter.has_replied_$cleanSender"
                if (prefs.getBoolean(hasRepliedKey, false)) {
                    ServiceLogManager.log("1️⃣ Abaikan '$cleanSender': mode Balas Sekali (sudah pernah dibalas)")
                    return
                }
                prefs.edit().putBoolean(hasRepliedKey, true).apply()
            }

            // 9. Catat waktu sebelum kirim agar event susulan langsung di-drop
            lastReplyPerSender[cleanSender] = now
            processedKeys[messageKey] = now

            ServiceLogManager.log("🚀 Membalas '$cleanSender': '$finalReply'")

            if (replyTimeMode == "delay" && replyDelaySeconds > 0) {
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    sendReply(this, quickReplyAction, finalReply)
                }, (replyDelaySeconds * 1000).toLong())
            } else {
                sendReply(this, quickReplyAction, finalReply)
            }
        } catch (t: Throwable) {
            ServiceLogManager.log("❌ Unhandled error: ${t.message}")
            Log.e(TAG, "Unhandled error in onNotificationPosted: ${t.message}", t)
        }
    }

    private fun findQuickReplyAction(notification: Notification): ActionInfo? {
        var remoteInputs: Array<RemoteInput>? = null
        var pendingIntent: PendingIntent? = null

        // 1. Scan actions standar persis WhatsAuto resmi
        val actions = notification.actions
        if (actions != null) {
            for (action in actions) {
                if (action != null && action.remoteInputs != null && action.remoteInputs.isNotEmpty()) {
                    remoteInputs = action.remoteInputs
                    pendingIntent = action.actionIntent
                    break
                }
            }
        }
        // 2. Scan fallback WearableExtender persis WhatsAuto resmi
        if (pendingIntent == null || remoteInputs == null) {
            try {
                val wearableActions = Notification.WearableExtender(notification).actions
                if (wearableActions != null) {
                    for (action in wearableActions) {
                        if (action != null && action.remoteInputs != null && action.remoteInputs.isNotEmpty()) {
                            remoteInputs = action.remoteInputs
                            pendingIntent = action.actionIntent
                            break
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        // 3. Fallback scan via AndroidX NotificationCompat
        if (pendingIntent == null || remoteInputs == null) {
            try {
                val count = androidx.core.app.NotificationCompat.getActionCount(notification)
                for (i in 0 until count) {
                    val compatAction = androidx.core.app.NotificationCompat.getAction(notification, i)
                    val ris = compatAction?.remoteInputs
                    val intent = compatAction?.actionIntent
                    if (compatAction != null && intent != null && ris != null && ris.isNotEmpty()) {
                        val platformInputs = ris.map { ci ->
                            RemoteInput.Builder(ci.resultKey)
                                .setLabel(ci.label)
                                .setChoices(ci.choices)
                                .setAllowFreeFormInput(ci.allowFreeFormInput)
                                .addExtras(ci.extras)
                                .build()
                        }.toTypedArray()
                        return ActionInfo(intent, platformInputs)
                    }
                }
            } catch (_: Exception) {}
        }

        if (pendingIntent != null && remoteInputs != null && remoteInputs.isNotEmpty()) {
            return ActionInfo(pendingIntent, remoteInputs)
        }
        return null
    }

    private fun sendReply(context: Context, actionInfo: ActionInfo, replyMessage: String) {
        try {
            val intent = Intent().apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val bundle = Bundle()
            for (ri in actionInfo.remoteInputs) {
                if (ri != null && ri.resultKey != null) {
                    bundle.putCharSequence(ri.resultKey, replyMessage)
                }
            }
            RemoteInput.addResultsToIntent(actionInfo.remoteInputs, intent, bundle)
            actionInfo.pendingIntent.send(context, 0, intent)
            val replyNorm = replyMessage.trim().lowercase()
            recentSentReplies[replyNorm] = System.currentTimeMillis()
            if (recentSentReplies.size > 100) {
                val cutoff = System.currentTimeMillis() - 60000
                recentSentReplies.entries.removeIf { it.value < cutoff }
            }
            ServiceLogManager.log("✅ RemoteInput TERKIRIM SUKSES ke WhatsApp!")
            Log.i(TAG, "Auto-reply sent successfully via RemoteInput: $replyMessage")
        } catch (e: Throwable) {
            ServiceLogManager.log("❌ Gagal eksekusi sendReply: ${e.message}")
            Log.e(TAG, "Failed to send auto-reply: ${e.message}", e)
        }
    }

    private fun formatTags(
        template: String,
        sender: String,
        incomingMessage: String = "",
        calendar: Calendar = Calendar.getInstance()
    ): String {
        try {
            // 1. Ekstraksi nama pengirim (deteksi format grup & tilde WhatsApp)
            var cleanSender = sender.trim()
            if (cleanSender.startsWith("~")) {
                cleanSender = cleanSender.removePrefix("~").trim()
            }
            if (cleanSender.contains("@") && cleanSender.indexOf('@') > 1) {
                cleanSender = cleanSender.substring(0, cleanSender.indexOf('@') - 1).trim()
            } else if (cleanSender.contains(":") && !cleanSender.startsWith("+")) {
                cleanSender = cleanSender.substring(cleanSender.lastIndexOf(':') + 1).trim()
            }

            val isPhone = cleanSender.matches(Regex("^[+0-9\\s\\-()]+$"))
            val displayName = if (isPhone || cleanSender.isEmpty()) "Kak" else cleanSender

            val senderParts = displayName.split(Regex("\\s+")).filter { it.isNotEmpty() }
            val firstName = senderParts.firstOrNull() ?: displayName
            val lastName = if (senderParts.size > 1) senderParts.drop(1).joinToString(" ") else ""

            // 2. Format jam & tanggal Indonesia hari ini (Persis WhatsAuto dd-MM-yyyy / format lokal)
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val currentJam = timeFormat.format(calendar.time)

            val dayNames = arrayOf("Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu")
            val monthNames = arrayOf(
                "Januari", "Februari", "Maret", "April", "Mei", "Juni",
                "Juli", "Agustus", "September", "Oktober", "November", "Desember"
            )
            val currentHari = dayNames[calendar.get(Calendar.DAY_OF_WEEK) - 1]
            val currentTanggal = "${calendar.get(Calendar.DAY_OF_MONTH)} ${monthNames[calendar.get(Calendar.MONTH)]} ${calendar.get(Calendar.YEAR)}"

            val tagMap = mapOf(
                "nama" to displayName,
                "name" to displayName,
                "nama_depan" to firstName,
                "nama depan" to firstName,
                "first_name" to firstName,
                "first name" to firstName,
                "nama_belakang" to lastName,
                "nama belakang" to lastName,
                "last_name" to lastName,
                "last name" to lastName,
                "jam" to currentJam,
                "time" to currentJam,
                "tanggal" to currentTanggal,
                "date" to currentTanggal,
                "hari" to currentHari,
                "pesan" to incomingMessage,
                "message" to incomingMessage
            )

            var rep = template
            for ((tag, value) in tagMap) {
                rep = rep.replace("{{$tag}}", value, ignoreCase = true)
                rep = rep.replace("{$tag}", value, ignoreCase = true)
            }
            return rep
        } catch (_: Throwable) {
            return template
        }
    }

    private fun queryWebhook(webhookUrl: String, sender: String, message: String): String? {
        val trimmed = webhookUrl.trim()
        if (trimmed.isEmpty()) {
            ServiceLogManager.log("⚠️ URL Webhook kosong di pengaturan")
            return null
        }

        try {
            val policy = android.os.StrictMode.ThreadPolicy.Builder().permitAll().build()
            android.os.StrictMode.setThreadPolicy(policy)
        } catch (_: Exception) {}

        ServiceLogManager.log("🌐 Menghubungi Webhook: $trimmed (pengirim: $sender, pesan: $message)")

        return try {
            val url = java.net.URL(trimmed)
            var conn = url.openConnection() as java.net.HttpURLConnection
            conn.instanceFollowRedirects = false
            conn.requestMethod = "POST"
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            conn.setRequestProperty("Accept", "application/json, text/plain, */*")
            conn.setRequestProperty("User-Agent", "MaoneAuto-Android-Bot")

            val payload = JSONObject().apply {
                put("sender", sender)
                put("message", message)
                put("app", "WhatsApp")
                put("timestamp", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(java.util.Date()))
            }

            conn.outputStream.use { os ->
                os.write(payload.toString().toByteArray(Charsets.UTF_8))
            }

            var responseCode = conn.responseCode
            ServiceLogManager.log("🌐 Webhook respon kode: $responseCode")

            // Handle HTTP 301, 302, 303, 307, 308 Redirect (Google Apps Script Web App mengembalikan 302 ke Echo URL)
            if (responseCode == java.net.HttpURLConnection.HTTP_MOVED_TEMP ||
                responseCode == java.net.HttpURLConnection.HTTP_MOVED_PERM ||
                responseCode == java.net.HttpURLConnection.HTTP_SEE_OTHER ||
                responseCode == 307 || responseCode == 308) {
                val newLocation = conn.getHeaderField("Location")
                if (!newLocation.isNullOrEmpty()) {
                    ServiceLogManager.log("🔄 Mengikuti Webhook Redirect...")
                    conn.disconnect()
                    val redirectUrl = java.net.URL(newLocation)
                    conn = redirectUrl.openConnection() as java.net.HttpURLConnection
                    conn.requestMethod = "GET"
                    conn.connectTimeout = 8000
                    conn.readTimeout = 8000
                    conn.setRequestProperty("Accept", "application/json, text/plain, */*")
                    conn.setRequestProperty("User-Agent", "MaoneAuto-Android-Bot")
                    responseCode = conn.responseCode
                    ServiceLogManager.log("🌐 Webhook respon kode setelah redirect: $responseCode")
                }
            }

            if (responseCode in 200..299) {
                val responseBody = conn.inputStream.bufferedReader().use { it.readText() }.trim()
                ServiceLogManager.log("🌐 Webhook balasan diterima: $responseBody")
                if (responseBody.isNotEmpty()) {
                    try {
                        val json = JSONObject(responseBody)
                        if (json.has("reply")) {
                            return json.optString("reply").trim()
                        }
                    } catch (_: Exception) {
                        return responseBody
                    }
                }
            } else {
                ServiceLogManager.log("❌ Webhook error: status HTTP $responseCode")
            }
            null
        } catch (e: Exception) {
            ServiceLogManager.log("❌ Webhook Exception: ${e.javaClass.simpleName}: ${e.message}")
            Log.e(TAG, "Error querying webhook: ${e.message}", e)
            null
        }
    }

    private fun queryAi(sender: String, message: String, prefs: android.content.SharedPreferences): String? {
        val provider = prefs.getString("flutter.ai_provider", "9router") ?: "9router"
        val apiKey = prefs.getString("flutter.ai_api_key", "") ?: ""
        val customPrompt = prefs.getString("flutter.ai_custom_prompt", "") ?: ""
        val systemPrompt = if (customPrompt.isNotBlank()) customPrompt else "Anda adalah asisten WhatsApp cerdas MaoneAuto. Jawab pertanyaan pengguna dengan ramah, informatif, ringkas, dan jelas dalam bahasa Indonesia."

        return try {
            if (provider == "gemini") {
                if (apiKey.isBlank()) return null
                val endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"
                val url = java.net.URL(endpoint)
                val conn = url.openConnection() as java.net.HttpURLConnection
                conn.requestMethod = "POST"
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")

                val payload = JSONObject().apply {
                    val contents = JSONArray().apply {
                        val obj = JSONObject().apply {
                            val parts = JSONArray().apply {
                                put(JSONObject().put("text", "System: $systemPrompt\nPesan dari $sender: $message"))
                            }
                            put("parts", parts)
                        }
                        put(obj)
                    }
                    put("contents", contents)
                }

                conn.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
                if (conn.responseCode in 200..299) {
                    val resp = conn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(resp)
                    val cand = json.optJSONArray("candidates")?.optJSONObject(0)
                    val parts = cand?.optJSONObject("content")?.optJSONArray("parts")
                    val text = parts?.optJSONObject(0)?.optString("text")?.trim()
                    if (!text.isNullOrBlank()) return text
                }
            } else {
                // Default: 9Router AI Gateway (Local port 20128)
                val endpoint = "http://127.0.0.1:20128/v1/chat/completions"
                val url = java.net.URL(endpoint)
                val conn = url.openConnection() as java.net.HttpURLConnection
                conn.requestMethod = "POST"
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                if (apiKey.isNotBlank()) {
                    conn.setRequestProperty("Authorization", "Bearer $apiKey")
                }

                val payload = JSONObject().apply {
                    put("model", "gemini-2.5-flash")
                    val messages = JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put("content", systemPrompt)
                        })
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", message)
                        })
                    }
                    put("messages", messages)
                    put("temperature", 0.7)
                    put("max_tokens", 400)
                }

                conn.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
                if (conn.responseCode in 200..299) {
                    val resp = conn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(resp)
                    val choices = json.optJSONArray("choices")
                    val msg = choices?.optJSONObject(0)?.optJSONObject("message")
                    val content = msg?.optString("content")?.trim()
                    if (!content.isNullOrBlank()) return content
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error querying AI: ${e.message}")
            null
        }
    }

    private fun computeReply(sender: String, messageText: String, prefs: android.content.SharedPreferences): String? {
        val cleanMsg = messageText.trim()
        if (cleanMsg.isEmpty()) return null

        val normalizedMsg = cleanMsg.replace(Regex("[?!.\\n]"), "").trim().lowercase()
        val compactMsg = cleanMsg.replace(Regex("[ ?!.\\n]"), "").trim().lowercase()
        val paddedMsg = " $normalizedMsg "
        val defaultReply = prefs.getString("flutter.default_reply", "Halo! Terima kasih telah menghubungi kami.") ?: "Halo!"
        val onlyKeywords = prefs.getBoolean("flutter.only_reply_keywords", false)

        val sessionPrefKey = "flutter.session_$sender"
        val currentParent = prefs.getString(sessionPrefKey, "idle") ?: "idle"

        // Baca cache tree nodes jika ada (opsional)
        val treeJsonStr = prefs.getString("flutter.menu_nodes_cache", null)
        val nodes = mutableListOf<JSONObject>()
        if (!treeJsonStr.isNullOrEmpty()) {
            try {
                val nodesArray = JSONArray(treeJsonStr)
                for (i in 0 until nodesArray.length()) {
                    nodes.add(nodesArray.getJSONObject(i))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing menu nodes cache: ${e.message}")
            }
        }

        try {
            // =========================================================================
            // FASE 1: Cek Balasan Kata Kunci (Keyword Replies) TERLEBIH DAHULU
            // Persis WhatsAuto resmi: kata kunci selalu memiliki prioritas lebih tinggi daripada menu
            // =========================================================================
            val isKeywordEnabled = prefs.getBoolean("flutter.is_keyword_reply_enabled", true)
            var keywordJsonStr = prefs.getString("flutter.keyword_replies_cache", null)
            if (keywordJsonStr == null) {
                keywordJsonStr = """[{"id":"default_hay","incomingKeywords":"hay","replyMessage":"hallo","isExactMatch":true,"isEnabled":true,"useMenuReply":false},{"id":"default_menu","incomingKeywords":"menu","replyMessage":"Silakan pilih menu layanan kami di bawah ini:","isExactMatch":true,"isEnabled":true,"useMenuReply":true}]"""
            }
            if (isKeywordEnabled && !keywordJsonStr.isNullOrEmpty()) {
                try {
                    val kwArray = JSONArray(keywordJsonStr)

                    // Prioritas 1: Exact Match untuk kata kunci spesifik (bukan '*')
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true) || !rule.optBoolean("isExactMatch", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val keywordsList = rawKeywords.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }

                        val isMatch = keywordsList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            kw != "*" && (kw == normalizedMsg || (cleanKw.isNotEmpty() && cleanKw == compactMsg))
                        }
                        if (isMatch) {
                            var rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false) && nodes.isNotEmpty()) {
                                prefs.edit().putString(sessionPrefKey, "parent").apply()
                                val menuText = renderMenu(nodes, "parent")
                                return if (rep.isBlank() || rep.equals("Menu Balas", ignoreCase = true)) menuText else "$rep\n\n$menuText"
                            }
                            if (rule.optBoolean("useWebhook", false)) {
                                val webhookUrl = prefs.getString("flutter.server_webhook_url", "")?.ifEmpty {
                                    prefs.getString("server_webhook_url", "") ?: ""
                                } ?: ""
                                val hookRep = queryWebhook(webhookUrl, sender, cleanMsg)
                                if (!hookRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(hookRep, sender, cleanMsg)
                                }
                                return null
                            }
                            if (rule.optBoolean("useAiReply", false)) {
                                val aiRep = queryAi(sender, cleanMsg, prefs)
                                if (!aiRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(aiRep, sender, cleanMsg)
                                }
                                return null
                            }
                            // Jika kata kunci biasa (tidak pakai menu), reset sesi menu menjadi idle
                            prefs.edit().putString(sessionPrefKey, "idle").apply()
                            if (rep.isNotBlank()) return rep
                        }
                    }

                    // Prioritas 2: Contains Match untuk kata kunci spesifik (bukan '*')
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true) || rule.optBoolean("isExactMatch", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val keywordsList = rawKeywords.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }

                        val isMatch = keywordsList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            kw != "*" && cleanKw.isNotEmpty() && (paddedMsg.contains(" $kw ") || normalizedMsg.contains(kw) || compactMsg.contains(cleanKw))
                        }
                        if (isMatch) {
                            var rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false) && nodes.isNotEmpty()) {
                                prefs.edit().putString(sessionPrefKey, "parent").apply()
                                val menuText = renderMenu(nodes, "parent")
                                return if (rep.isBlank() || rep.equals("Menu Balas", ignoreCase = true)) menuText else "$rep\n\n$menuText"
                            }
                            if (rule.optBoolean("useWebhook", false)) {
                                val webhookUrl = prefs.getString("flutter.server_webhook_url", "")?.ifEmpty {
                                    prefs.getString("server_webhook_url", "") ?: ""
                                } ?: ""
                                val hookRep = queryWebhook(webhookUrl, sender, cleanMsg)
                                if (!hookRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(hookRep, sender, cleanMsg)
                                }
                                return null
                            }
                            if (rule.optBoolean("useAiReply", false)) {
                                val aiRep = queryAi(sender, cleanMsg, prefs)
                                if (!aiRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(aiRep, sender, cleanMsg)
                                }
                                return null
                            }
                            // Jika kata kunci biasa (tidak pakai menu), reset sesi menu menjadi idle
                            prefs.edit().putString(sessionPrefKey, "idle").apply()
                            if (rep.isNotBlank()) return rep
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking keyword replies: ${e.message}")
                }
            }

            // =========================================================================
            // FASE 2: Sesi Menu Aktif (Hanya jika TIDAK ADA kata kunci yang cocok)
            // =========================================================================
            if (currentParent != "idle" && nodes.isNotEmpty()) {
                // 1. Perintah Keluar / Batal
                if (normalizedMsg == "batal" || normalizedMsg == "keluar" || normalizedMsg == "exit") {
                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                    return "Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali."
                }

                // 2. Tombol 0 (Kembali ke Menu Utama atau Keluar)
                if (normalizedMsg == "0") {
                    if (currentParent != "parent") {
                        prefs.edit().putString(sessionPrefKey, "parent").apply()
                        return renderMenu(nodes, "parent")
                    } else {
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        return "Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali."
                    }
                }

                // 3. Cocokkan pilihan dengan opsi di bawah currentParent
                val options = nodes.filter { it.optString("parentId") == currentParent && it.optInt("type") == 2 }
                val previousMenuNum = options.size + 1

                val numChoice = normalizedMsg.toIntOrNull()
                // Cek tombol 'Menu Sebelumnya' persis WhatsAuto
                if (numChoice == previousMenuNum || normalizedMsg == "kembali" || normalizedMsg == "back") {
                    if (currentParent != "parent") {
                        val currentNode = nodes.firstOrNull { it.optString("id") == currentParent }
                        val grandParent = currentNode?.optString("parentId")?.ifEmpty { "parent" } ?: "parent"
                        prefs.edit().putString(sessionPrefKey, grandParent).apply()
                        return renderMenu(nodes, grandParent)
                    } else {
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        return "Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali."
                    }
                }

                var matchedOption: JSONObject? = null
                if (numChoice != null && numChoice in 1..options.size) {
                    matchedOption = options[numChoice - 1]
                } else {
                    matchedOption = options.firstOrNull {
                        val optText = it.optString("text").replace(Regex("[?!.\\n]"), "").trim().lowercase()
                        optText == normalizedMsg || optText.contains(normalizedMsg)
                    }
                }

                if (matchedOption != null) {
                    val matchedId = matchedOption.optString("id")
                    val subPrompt = nodes.firstOrNull { it.optString("parentId") == matchedId && it.optInt("type") == 1 }
                    val subOptions = nodes.filter { it.optString("parentId") == matchedId && it.optInt("type") == 2 }

                    if (subOptions.isNotEmpty()) {
                        prefs.edit().putString(sessionPrefKey, matchedId).apply()
                        return renderMenu(nodes, matchedId)
                    } else if (subPrompt != null) {
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        val rendered = formatTags(subPrompt.optString("text").trim(), sender, cleanMsg)
                        return "$rendered\n\n*(Sesi menu selesai. Ketik 'menu' untuk membuka kembali)*"
                    } else {
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        val rendered = formatTags(matchedOption.optString("text").trim(), sender, cleanMsg)
                        return "$rendered\n\n*(Sesi menu selesai. Ketik 'menu' untuk membuka kembali)*"
                    }
                }

                return "⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera:\n\n" + renderMenu(nodes, currentParent)
            }

            // B. Cek Balasan Google Spreadsheet (Katalog Lembar Kerja)
            val isSheetEnabled = prefs.getBoolean("flutter.is_spreadsheet_reply_enabled", false)
            val sheetJsonStr = prefs.getString("flutter.spreadsheet_items_cache", null)
            if (isSheetEnabled && !sheetJsonStr.isNullOrEmpty()) {
                try {
                    val sheetArray = JSONArray(sheetJsonStr)
                    var wildcardReply: String? = null

                    // 1. Exact Match di Sheet
                    for (i in 0 until sheetArray.length()) {
                        val item = sheetArray.getJSONObject(i)
                        val rawKw = item.optString("keyword", "").trim()
                        if (rawKw == "*") {
                            wildcardReply = item.optString("reply", "")
                            continue
                        }
                        if (item.optInt("matchOption", 1) != 0) continue

                        val kwList = rawKw.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }
                        val isMatch = kwList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            kw == normalizedMsg || (cleanKw.isNotEmpty() && cleanKw == compactMsg)
                        }
                        if (isMatch) {
                            val rep = formatTags(item.optString("reply", ""), sender, cleanMsg)
                            if (rep.isNotBlank()) return rep
                        }
                    }

                    // 2. Contains Match di Sheet
                    for (i in 0 until sheetArray.length()) {
                        val item = sheetArray.getJSONObject(i)
                        val rawKw = item.optString("keyword", "").trim()
                        if (rawKw == "*") {
                            wildcardReply = item.optString("reply", "")
                            continue
                        }
                        if (item.optInt("matchOption", 1) != 1) continue

                        val kwList = rawKw.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }
                        val isMatch = kwList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            cleanKw.isNotEmpty() && (paddedMsg.contains(" $kw ") || normalizedMsg.contains(kw) || compactMsg.contains(cleanKw))
                        }
                        if (isMatch) {
                            val rep = formatTags(item.optString("reply", ""), sender, cleanMsg)
                            if (rep.isNotBlank()) return rep
                        }
                    }

                    // 3. Fallback Wildcard (*) dari Spreadsheet (Balas semua jika tidak ada kata kunci spesifik yang cocok)
                    if (!wildcardReply.isNullOrBlank()) {
                        return formatTags(wildcardReply, sender, cleanMsg)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking spreadsheet replies: ${e.message}")
                }
            }

            // C. Wildcard Catch-All (*) dari Balasan Kata Kunci (Membalas SEMUA pesan masuk)
            if (isKeywordEnabled && !keywordJsonStr.isNullOrEmpty()) {
                try {
                    val kwArray = JSONArray(keywordJsonStr)
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val hasWildcard = rawKeywords.split(",").any { it.trim() == "*" }
                        if (hasWildcard) {
                            var rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false) && nodes.isNotEmpty()) {
                                prefs.edit().putString(sessionPrefKey, "parent").apply()
                                val menuText = renderMenu(nodes, "parent")
                                return if (rep.isBlank() || rep.equals("Menu Balas", ignoreCase = true)) menuText else "$rep\n\n$menuText"
                            }
                            if (rule.optBoolean("useWebhook", false)) {
                                val webhookUrl = prefs.getString("flutter.server_webhook_url", "")?.ifEmpty {
                                    prefs.getString("server_webhook_url", "") ?: ""
                                } ?: ""
                                val hookRep = queryWebhook(webhookUrl, sender, cleanMsg)
                                if (!hookRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(hookRep, sender, cleanMsg)
                                }
                                return null
                            }
                            if (rule.optBoolean("useAiReply", false)) {
                                val aiRep = queryAi(sender, cleanMsg, prefs)
                                if (!aiRep.isNullOrBlank()) {
                                    prefs.edit().putString(sessionPrefKey, "idle").apply()
                                    return formatTags(aiRep, sender, cleanMsg)
                                }
                                return null
                            }
                            prefs.edit().putString(sessionPrefKey, "idle").apply()
                            if (rep.isNotBlank()) return rep
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking wildcard keyword reply: ${e.message}")
                }
            }

            // D. Kata kunci default pemanggil menu ("menu", "katalog", "bantuan")
            if (nodes.isNotEmpty() && (normalizedMsg == "menu" ||
                normalizedMsg == "katalog" ||
                normalizedMsg == "pilihan" ||
                normalizedMsg == "bantuan")) {
                prefs.edit().putString(sessionPrefKey, "parent").apply()
                return renderMenu(nodes, "parent")
            }

            // D. Pesan Sambutan untuk kontak baru pertama kali (Welcome Message)
            val isWelcomeEnabled = prefs.getBoolean("flutter.welcome_message_enabled", false)
            val welcomeText = prefs.getString("flutter.welcome_message", "") ?: ""
            if (isWelcomeEnabled && welcomeText.isNotBlank()) {
                val welcomeKey = "flutter.welcomed_$sender"
                if (!prefs.getBoolean(welcomeKey, false)) {
                    prefs.edit().putBoolean(welcomeKey, true).apply()
                    return formatTags(welcomeText, sender, cleanMsg)
                }
            }

            // E. Pesan biasa di luar menu -> Balas dengan balasan default (kecuali user mengaktifkan only_reply_keywords)
            if (onlyKeywords) {
                return null
            }
            return formatTags(defaultReply, sender, cleanMsg)
        } catch (e: Exception) {
            Log.e(TAG, "Error in computeReply: ${e.message}")
            if (onlyKeywords) {
                return null
            }
            return formatTags(defaultReply, sender, cleanMsg)
        }
    }

    private fun renderMenu(nodes: List<JSONObject>, parentId: String): String {
        val promptNode = nodes.firstOrNull { it.optString("parentId") == parentId && it.optInt("type") == 1 }
        val options = nodes.filter { it.optString("parentId") == parentId && it.optInt("type") == 2 }

        val sb = StringBuilder()
        if (promptNode != null) {
            sb.append(promptNode.optString("text").trim()).append("\n\n")
        }

        for (i in options.indices) {
            val opt = options[i]
            val rawTitle = opt.optString("text").trim()
            val cleanTitle = rawTitle.replaceFirst(Regex("^\\d+\\.\\s*"), "")
            sb.append("${i + 1}. ").append(cleanTitle).append("\n")
        }

        if (parentId != "parent") {
            // Persis WhatsAuto asli: opsi N untuk Menu Sebelumnya, dan 0 untuk Menu Utama
            sb.append("\n${options.size + 1}. ↩️ Menu Sebelumnya\n")
            sb.append("0. 🏠 Kembali ke Menu Utama")
        } else {
            sb.append("\n0. ❌ Tutup Menu")
        }

        return sb.toString().trim()
    }

    data class ActionInfo(
        val pendingIntent: PendingIntent,
        val remoteInputs: Array<RemoteInput>
    )
}
