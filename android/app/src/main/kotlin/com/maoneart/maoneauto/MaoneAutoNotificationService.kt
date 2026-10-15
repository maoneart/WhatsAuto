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

class MaoneAutoNotificationService : NotificationListenerService() {

    companion object {
        var isServiceConnected: Boolean = false
    }

    private val TAG = "MaoneAutoService"
    private val processedKeys = mutableMapOf<String, Long>()
    private val lastReplyPerSender = mutableMapOf<String, Long>()

    override fun onListenerConnected() {
        super.onListenerConnected()
        isServiceConnected = true
        Log.i(TAG, "MaoneAutoNotificationService listener connected successfully!")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isServiceConnected = false
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
                Log.d(TAG, "Auto-reply is disabled in settings")
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
                        Log.d(TAG, "App $packageName is not enabled in supported apps")
                        return
                    }
                } catch (_: Exception) {}
            }

            val extras = notification.extras ?: return

            // Ekstraksi Title & Text secara aman untuk CharSequence / SpannableString
            val rawTitle = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                ?: extras.getString(Notification.EXTRA_TITLE) ?: ""
            var rawText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            if (rawText.isEmpty()) {
                val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                if (textLines != null && textLines.isNotEmpty()) {
                    rawText = textLines.lastOrNull()?.toString() ?: ""
                }
            }
            if (rawText.isEmpty()) {
                try {
                    val messages = extras.getParcelableArray("android.messages")
                    if (messages != null && messages.isNotEmpty()) {
                        val lastBundle = messages.lastOrNull() as? Bundle
                        rawText = lastBundle?.getCharSequence("text")?.toString() ?: ""
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

            Log.i(TAG, "Processing incoming notification -> App: $packageName | Sender: $cleanSender | Msg: $cleanMsg")

            // 2c. Deteksi & Filter Pesan Grup WhatsApp (Akurat menggunakan EXTRA_IS_GROUP_CONVERSATION)
            val isGroup = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                extras.getBoolean(Notification.EXTRA_IS_GROUP_CONVERSATION, false)
            } else {
                cleanSender.contains(" @ ")
            }
            val enableGroups = prefs.getBoolean("flutter.enable_groups", false)
            if (isGroup && !enableGroups) {
                Log.d(TAG, "Abaikan pesan grup karena grup dinonaktifkan: $cleanSender (rawTitle=$rawTitle)")
                return
            }

            // 2d. Filter Kontak (Kecuali Kontak Telepon / Unknown Number Only)
            val replyTo = prefs.getString("flutter.reply_to", "all") ?: "all"
            val isPhoneNumber = cleanSender.replace(Regex("[+0-9\\s\\-()]"), "").isEmpty()
            if (replyTo == "except_phone" && !isPhoneNumber) {
                Log.d(TAG, "Abaikan kontak tersimpan karena hanya membalas nomor baru: $cleanSender")
                return
            }

            val now = System.currentTimeMillis()

            // 3. Debounce per-pengirim: jangan balas lebih dari 1 kali dalam 1 detik untuk pengirim yang sama
            val lastSenderReply = lastReplyPerSender[cleanSender] ?: 0L
            if (now - lastSenderReply < 1000) {
                Log.d(TAG, "Debounce active for sender: $cleanSender (${now - lastSenderReply}ms ago)")
                return
            }

            // 4. Deduplikasi pesan identik dalam 1 detik
            val messageKey = "$packageName:$cleanSender:$cleanMsg"
            val lastSeen = processedKeys[messageKey] ?: 0L
            if (now - lastSeen < 1000) {
                Log.d(TAG, "Duplicate message key dropped: $messageKey (${now - lastSeen}ms ago)")
                return
            }

            // 5. Cari Quick Reply Action dengan RemoteInput (actions standar + fallback WearableExtender)
            val quickReplyAction = findQuickReplyAction(notification)
            if (quickReplyAction == null) {
                Log.d(TAG, "No quick reply action found for notification from $packageName")
                return
            }

            // 6. Hitung teks balasan dengan Tree Menu & Rule Kata Kunci
            val replyText = computeReply(cleanSender, cleanMsg, prefs)
            if (replyText.isNullOrBlank()) {
                Log.d(TAG, "No reply computed for message: '$cleanMsg' from $cleanSender")
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

            // 8. Catat waktu sebelum kirim agar event susulan langsung di-drop
            lastReplyPerSender[cleanSender] = now
            processedKeys[messageKey] = now

            // 9. Cek Mode Timer / Delay / Once
            val replyTimeMode = prefs.getString("flutter.reply_time_mode", "instantly") ?: "instantly"
            val replyDelaySeconds = prefs.getInt("flutter.reply_delay_seconds", 0)

            if (replyTimeMode == "once") {
                val hasRepliedKey = "flutter.has_replied_$cleanSender"
                if (prefs.getBoolean(hasRepliedKey, false)) {
                    Log.d(TAG, "Abaikan pengirim $cleanSender: sudah pernah dibalas sekali")
                    return
                }
                prefs.edit().putBoolean(hasRepliedKey, true).apply()
            }

            Log.i(TAG, "Sending auto-reply to $cleanSender ($packageName): $finalReply")

            if (replyTimeMode == "delay" && replyDelaySeconds > 0) {
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    sendReply(this, quickReplyAction, finalReply)
                }, (replyDelaySeconds * 1000).toLong())
            } else {
                sendReply(this, quickReplyAction, finalReply)
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Unhandled error in onNotificationPosted: ${t.message}", t)
        }
    }

    private fun findQuickReplyAction(notification: Notification): ActionInfo? {
        // 1. Scan actions standar
        val actions = notification.actions
        if (actions != null) {
            for (action in actions) {
                if (action == null) continue
                val pendingIntent = action.actionIntent ?: continue
                val remoteInputs = action.remoteInputs ?: continue
                if (remoteInputs.isNotEmpty()) {
                    return ActionInfo(pendingIntent, remoteInputs)
                }
            }
        }
        // 2. Scan fallback WearableExtender persis WhatsAuto NotificationListener
        try {
            val wearableActions = Notification.WearableExtender(notification).actions
            if (wearableActions != null) {
                for (action in wearableActions) {
                    if (action == null) continue
                    val pendingIntent = action.actionIntent ?: continue
                    val remoteInputs = action.remoteInputs ?: continue
                    if (remoteInputs.isNotEmpty()) {
                        return ActionInfo(pendingIntent, remoteInputs)
                    }
                }
            }
        } catch (_: Exception) {}
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
            Log.i(TAG, "Auto-reply sent successfully via RemoteInput!")
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to send auto-reply: ${e.message}", e)
        }
    }

    private fun formatTags(
        template: String,
        sender: String,
        incomingMessage: String = "",
        calendar: Calendar = Calendar.getInstance()
    ): String {
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

        val safeDisplayName = java.util.regex.Matcher.quoteReplacement(displayName)
        val safeFirstName = java.util.regex.Matcher.quoteReplacement(firstName)
        val safeLastName = java.util.regex.Matcher.quoteReplacement(lastName)
        val safeJam = java.util.regex.Matcher.quoteReplacement(currentJam)
        val safeTanggal = java.util.regex.Matcher.quoteReplacement(currentTanggal)
        val safeHari = java.util.regex.Matcher.quoteReplacement(currentHari)
        val safeIncomingMessage = java.util.regex.Matcher.quoteReplacement(incomingMessage)

        var rep = template
        // Dukung kurung kurawal ganda {{...}} MAUPUN kurung kurawal tunggal {...} persis WhatsAuto
        rep = rep.replace(Regex("(?i)\\{\\{?nama\\}?}"), safeDisplayName)
        rep = rep.replace(Regex("(?i)\\{\\{?name\\}?}"), safeDisplayName)

        rep = rep.replace(Regex("(?i)\\{\\{?nama_depan\\}?}"), safeFirstName)
        rep = rep.replace(Regex("(?i)\\{\\{?nama depan\\}?}"), safeFirstName)
        rep = rep.replace(Regex("(?i)\\{\\{?first_name\\}?}"), safeFirstName)
        rep = rep.replace(Regex("(?i)\\{\\{?first name\\}?}"), safeFirstName)

        rep = rep.replace(Regex("(?i)\\{\\{?nama_belakang\\}?}"), safeLastName)
        rep = rep.replace(Regex("(?i)\\{\\{?nama belakang\\}?}"), safeLastName)
        rep = rep.replace(Regex("(?i)\\{\\{?last_name\\}?}"), safeLastName)
        rep = rep.replace(Regex("(?i)\\{\\{?last name\\}?}"), safeLastName)

        rep = rep.replace(Regex("(?i)\\{\\{?jam\\}?}"), safeJam)
        rep = rep.replace(Regex("(?i)\\{\\{?time\\}?}"), safeJam)

        rep = rep.replace(Regex("(?i)\\{\\{?tanggal\\}?}"), safeTanggal)
        rep = rep.replace(Regex("(?i)\\{\\{?date\\}?}"), safeTanggal)

        rep = rep.replace(Regex("(?i)\\{\\{?hari\\}?}"), safeHari)

        rep = rep.replace(Regex("(?i)\\{\\{?pesan\\}?}"), safeIncomingMessage)
        rep = rep.replace(Regex("(?i)\\{\\{?message\\}?}"), safeIncomingMessage)
        return rep
    }

    private fun computeReply(sender: String, messageText: String, prefs: android.content.SharedPreferences): String? {
        val cleanMsg = messageText.trim()
        if (cleanMsg.isEmpty()) return null

        val normalizedMsg = cleanMsg.replace(Regex("[?!.\\n]"), "").trim().lowercase()
        val compactMsg = cleanMsg.replace(Regex("[ ?!.\\n]"), "").trim().lowercase()
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
            // FASE 1: Jika Pengguna Sedang Berada di Dalam Sesi Menu Aktif (Bukan Idle)
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

            // =========================================================================
            // FASE 2: Sesi Idle (Pesan biasa / Pemicu Kata Kunci Baru)
            // =========================================================================

            // A. Cek Balasan Kata Kunci (Keyword Replies)
            // WhatsAuto mengecek Exact Match terlebih dahulu, lalu Contains Match
            val isKeywordEnabled = prefs.getBoolean("flutter.is_keyword_reply_enabled", true)
            var keywordJsonStr = prefs.getString("flutter.keyword_replies_cache", null)
            if (keywordJsonStr == null) {
                keywordJsonStr = """[{"id":"default_hay","incomingKeywords":"hay","replyMessage":"hallo","isExactMatch":true,"isEnabled":true,"useMenuReply":false},{"id":"default_menu","incomingKeywords":"menu","replyMessage":"Silakan pilih menu layanan kami di bawah ini:","isExactMatch":true,"isEnabled":true,"useMenuReply":true}]"""
            }
            if (isKeywordEnabled && !keywordJsonStr.isNullOrEmpty()) {
                try {
                    val kwArray = JSONArray(keywordJsonStr)
                    val paddedMsg = " $normalizedMsg "

                    // Prioritas 1: Exact Match (cocok persis teks atau compact tanpa spasi/simbol)
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true) || !rule.optBoolean("isExactMatch", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val keywordsList = rawKeywords.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }

                        val isMatch = keywordsList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            kw == normalizedMsg || (cleanKw.isNotEmpty() && cleanKw == compactMsg)
                        }
                        if (isMatch) {
                            val rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false) && nodes.isNotEmpty()) {
                                prefs.edit().putString(sessionPrefKey, "parent").apply()
                                val menuText = renderMenu(nodes, "parent")
                                return if (rep.isBlank()) menuText else "$rep\n\n$menuText"
                            }
                            if (rep.isNotBlank()) return rep
                        }
                    }

                    // Prioritas 2: Contains Match
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true) || rule.optBoolean("isExactMatch", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val keywordsList = rawKeywords.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }

                        val isMatch = keywordsList.any { kw ->
                            val cleanKw = kw.replace(Regex("[ ?!.\\n]"), "")
                            cleanKw.isNotEmpty() && (paddedMsg.contains(" $kw ") || normalizedMsg.contains(kw) || compactMsg.contains(cleanKw))
                        }
                        if (isMatch) {
                            val rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false) && nodes.isNotEmpty()) {
                                prefs.edit().putString(sessionPrefKey, "parent").apply()
                                val menuText = renderMenu(nodes, "parent")
                                return if (rep.isBlank()) menuText else "$rep\n\n$menuText"
                            }
                            if (rep.isNotBlank()) return rep
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking keyword replies: ${e.message}")
                }
            }

            // B. Cek Balasan Google Spreadsheet (Katalog Lembar Kerja)
            val isSheetEnabled = prefs.getBoolean("flutter.is_spreadsheet_reply_enabled", false)
            val sheetJsonStr = prefs.getString("flutter.spreadsheet_items_cache", null)
            if (isSheetEnabled && !sheetJsonStr.isNullOrEmpty()) {
                try {
                    val sheetArray = JSONArray(sheetJsonStr)
                    val paddedMsg = " $normalizedMsg "

                    // Exact Match
                    for (i in 0 until sheetArray.length()) {
                        val item = sheetArray.getJSONObject(i)
                        if (item.optInt("matchOption", 1) != 0) continue
                        val kw = item.optString("keyword", "").replace(Regex("[?!.]"), "").trim().lowercase()
                        if (kw.isNotEmpty() && (kw == normalizedMsg || kw.replace(Regex("[ ?!.\\n]"), "") == compactMsg)) {
                            val rep = formatTags(item.optString("reply", ""), sender, cleanMsg)
                            if (rep.isNotBlank()) return rep
                        }
                    }

                    // Contains Match
                    for (i in 0 until sheetArray.length()) {
                        val item = sheetArray.getJSONObject(i)
                        if (item.optInt("matchOption", 1) != 1) continue
                        val kw = item.optString("keyword", "").replace(Regex("[?!.]"), "").trim().lowercase()
                        if (kw.isNotEmpty() && (paddedMsg.contains(" $kw ") || normalizedMsg.contains(kw))) {
                            val rep = formatTags(item.optString("reply", ""), sender, cleanMsg)
                            if (rep.isNotBlank()) return rep
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking spreadsheet replies: ${e.message}")
                }
            }

            // C. Kata kunci default pemanggil menu ("menu", "katalog", "bantuan")
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
