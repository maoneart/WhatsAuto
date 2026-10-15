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

    private val TAG = "MaoneAutoService"
    private val processedKeys = mutableMapOf<String, Long>()
    private val lastReplyPerSender = mutableMapOf<String, Long>()

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        val supportedPackages = listOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "com.facebook.orca"
        )

        if (!supportedPackages.contains(packageName)) return

        val notification = sbn.notification ?: return

        // 1. Abaikan notifikasi ringkasan grup/thread WhatsApp (mencegah balasan ganda)
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        if ((notification.flags and Notification.FLAG_ONGOING_EVENT) != 0) return

        // 2. Baca pengaturan dari Flutter SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.is_auto_reply_enabled", false)
        if (!isEnabled) return

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
                if (!isAppAllowed) return
            } catch (_: Exception) {}
        }

        val extras = notification.extras ?: return

        val rawTitle = extras.getString(Notification.EXTRA_TITLE) ?: ""
        var rawText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        if (rawText.isEmpty()) {
            rawText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
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

        // 2b. Deteksi & Abaikan Pesan Sendiri (Self-Message Prevention)
        val selfDisplayName = extras.getString("android.selfDisplayName") ?: ""
        if (selfDisplayName.isNotEmpty() && (cleanSender.equals(selfDisplayName, ignoreCase = true) || rawTitle.contains(selfDisplayName, ignoreCase = true))) {
            Log.d(TAG, "Abaikan pesan sendiri dari: $cleanSender (selfDisplayName=$selfDisplayName)")
            return
        }

        // 2c. Deteksi & Filter Pesan Grup WhatsApp
        val isGroup = rawTitle.contains(":") || (rawTitle.contains("@") && !rawTitle.startsWith("+"))
        val enableGroups = prefs.getBoolean("flutter.enable_groups", false)
        if (isGroup && !enableGroups) {
            Log.d(TAG, "Abaikan pesan grup karena grup dinonaktifkan: $rawTitle")
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

        // 3. Debounce per-pengirim: jangan balas lebih dari 1 kali dalam 2.5 detik untuk pengirim yang sama
        val lastSenderReply = lastReplyPerSender[cleanSender] ?: 0L
        if (now - lastSenderReply < 2500) return

        // 4. Deduplikasi pesan identik dalam 3 detik
        val messageKey = "$packageName:$cleanSender:$cleanMsg"
        val lastSeen = processedKeys[messageKey] ?: 0L
        if (now - lastSeen < 3000) return
        processedKeys[messageKey] = now

        // 5. Cari Quick Reply Action dengan RemoteInput (actions standar + fallback WearableExtender)
        val quickReplyAction = findQuickReplyAction(notification) ?: return

        // 6. Hitung teks balasan dengan Tree Menu & Rule Kata Kunci
        val replyText = computeReply(cleanSender, cleanMsg, prefs) ?: return

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

        if (replyTimeMode == "delay" && replyDelaySeconds > 0) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                sendReply(this, quickReplyAction, finalReply)
            }, (replyDelaySeconds * 1000).toLong())
        } else {
            sendReply(this, quickReplyAction, finalReply)
        }
    }

    private fun findQuickReplyAction(notification: Notification): ActionInfo? {
        // 1. Scan actions standar
        val actions = notification.actions
        if (actions != null) {
            for (action in actions) {
                val pendingIntent = action.actionIntent ?: continue
                val remoteInputs = action.remoteInputs ?: continue
                for (ri in remoteInputs) {
                    if (ri.resultKey != null) {
                        return ActionInfo(pendingIntent, ri)
                    }
                }
            }
        }
        // 2. Scan fallback WearableExtender persis WhatsAuto NotificationListener
        try {
            val wearableActions = Notification.WearableExtender(notification).actions
            if (wearableActions != null) {
                for (action in wearableActions) {
                    val pendingIntent = action.actionIntent ?: continue
                    val remoteInputs = action.remoteInputs ?: continue
                    for (ri in remoteInputs) {
                        if (ri.resultKey != null) {
                            return ActionInfo(pendingIntent, ri)
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun sendReply(context: Context, actionInfo: ActionInfo, replyMessage: String) {
        try {
            val intent = Intent()
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val bundle = Bundle()
            bundle.putCharSequence(actionInfo.remoteInput.resultKey, replyMessage)
            RemoteInput.addResultsToIntent(arrayOf(actionInfo.remoteInput), intent, bundle)
            actionInfo.pendingIntent.send(context, 0, intent)
            Log.d(TAG, "Auto-reply sent successfully via RemoteInput")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send auto-reply: ${e.message}")
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

        var rep = template
        // Dukung kurung kurawal ganda {{...}} MAUPUN kurung kurawal tunggal {...} persis WhatsAuto
        rep = rep.replace(Regex("(?i)\\{\\{?nama\\}?}"), displayName)
        rep = rep.replace(Regex("(?i)\\{\\{?name\\}?}"), displayName)

        rep = rep.replace(Regex("(?i)\\{\\{?nama_depan\\}?}"), firstName)
        rep = rep.replace(Regex("(?i)\\{\\{?nama depan\\}?}"), firstName)
        rep = rep.replace(Regex("(?i)\\{\\{?first_name\\}?}"), firstName)
        rep = rep.replace(Regex("(?i)\\{\\{?first name\\}?}"), firstName)

        rep = rep.replace(Regex("(?i)\\{\\{?nama_belakang\\}?}"), lastName)
        rep = rep.replace(Regex("(?i)\\{\\{?nama belakang\\}?}"), lastName)
        rep = rep.replace(Regex("(?i)\\{\\{?last_name\\}?}"), lastName)
        rep = rep.replace(Regex("(?i)\\{\\{?last name\\}?}"), lastName)

        rep = rep.replace(Regex("(?i)\\{\\{?jam\\}?}"), currentJam)
        rep = rep.replace(Regex("(?i)\\{\\{?time\\}?}"), currentJam)

        rep = rep.replace(Regex("(?i)\\{\\{?tanggal\\}?}"), currentTanggal)
        rep = rep.replace(Regex("(?i)\\{\\{?date\\}?}"), currentTanggal)

        rep = rep.replace(Regex("(?i)\\{\\{?hari\\}?}"), currentHari)

        rep = rep.replace(Regex("(?i)\\{\\{?pesan\\}?}"), incomingMessage)
        rep = rep.replace(Regex("(?i)\\{\\{?message\\}?}"), incomingMessage)
        return rep
    }

    private fun computeReply(sender: String, messageText: String, prefs: android.content.SharedPreferences): String? {
        val cleanMsg = messageText.trim()
        val normalizedMsg = cleanMsg.replace(Regex("[?!.\\n]"), "").trim().lowercase()
        val treeJsonStr = prefs.getString("flutter.menu_nodes_cache", null)
        val defaultReply = prefs.getString("flutter.default_reply", "Halo! Terima kasih telah menghubungi kami.") ?: "Halo!"

        if (treeJsonStr.isNullOrEmpty()) {
            val onlyKeywords = prefs.getBoolean("flutter.only_reply_keywords", true)
            return if (onlyKeywords) null else formatTags(defaultReply, sender, cleanMsg)
        }

        try {
            val nodesArray = JSONArray(treeJsonStr)
            val nodes = mutableListOf<JSONObject>()
            for (i in 0 until nodesArray.length()) {
                nodes.add(nodesArray.getJSONObject(i))
            }

            val sessionPrefKey = "flutter.session_$sender"
            val currentParent = prefs.getString(sessionPrefKey, "idle") ?: "idle"

            // =========================================================================
            // FASE 1: Jika Pengguna Sedang Berada di Dalam Sesi Menu Aktif (Bukan Idle)
            // =========================================================================
            if (currentParent != "idle") {
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
                        // Masuk ke submenu bertingkat berikutnya
                        prefs.edit().putString(sessionPrefKey, matchedId).apply()
                        return renderMenu(nodes, matchedId)
                    } else if (subPrompt != null) {
                        // Leaf response (detail produk/harga) -> reset sesi persis WhatsAuto
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        val rendered = formatTags(subPrompt.optString("text").trim(), sender, cleanMsg)
                        return "$rendered\n\n*(Sesi menu selesai. Ketik 'menu' untuk membuka kembali)*"
                    } else {
                        prefs.edit().putString(sessionPrefKey, "idle").apply()
                        val rendered = formatTags(matchedOption.optString("text").trim(), sender, cleanMsg)
                        return "$rendered\n\n*(Sesi menu selesai. Ketik 'menu' untuk membuka kembali)*"
                    }
                }

                // Jika input salah saat berada di dalam menu
                return "⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera:\n\n" + renderMenu(nodes, currentParent)
            }

            // =========================================================================
            // FASE 2: Sesi Idle (Pesan biasa / Pemicu Kata Kunci Baru)
            // =========================================================================

            // A. Cek Balasan Kata Kunci (Keyword Replies)
            // WhatsAuto mengecek Exact Match (k=0) terlebih dahulu, lalu Contains Match (k=1)
            val isKeywordEnabled = prefs.getBoolean("flutter.is_keyword_reply_enabled", true)
            val keywordJsonStr = prefs.getString("flutter.keyword_replies_cache", null)
            if (isKeywordEnabled && !keywordJsonStr.isNullOrEmpty()) {
                try {
                    val kwArray = JSONArray(keywordJsonStr)
                    val paddedMsg = " $normalizedMsg "

                    // Prioritas 1: Exact Match
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true) || !rule.optBoolean("isExactMatch", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val keywordsList = rawKeywords.split(",").map { it.replace(Regex("[?!.]"), "").trim().lowercase() }.filter { it.isNotEmpty() }

                        val isMatch = keywordsList.any { it == normalizedMsg }
                        if (isMatch) {
                            val rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false)) {
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

                        val isMatch = keywordsList.any { paddedMsg.contains(" $it ") || normalizedMsg.contains(it) }
                        if (isMatch) {
                            val rep = formatTags(rule.optString("replyMessage", ""), sender, cleanMsg)
                            if (rule.optBoolean("useMenuReply", false)) {
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

            // B. Kata kunci default pemanggil menu ("menu", "katalog", "bantuan")
            if (normalizedMsg == "menu" ||
                normalizedMsg == "katalog" ||
                normalizedMsg == "pilihan" ||
                normalizedMsg == "bantuan") {
                prefs.edit().putString(sessionPrefKey, "parent").apply()
                return renderMenu(nodes, "parent")
            }

            // C. Pesan biasa di luar menu -> Diam sepenuhnya jika bukan kata kunci terdaftar!
            val onlyKeywords = prefs.getBoolean("flutter.only_reply_keywords", true)
            if (onlyKeywords) {
                return null
            }
            return formatTags(defaultReply, sender, cleanMsg)
        } catch (e: Exception) {
            Log.e(TAG, "Error in computeReply: ${e.message}")
            val onlyKeywords = prefs.getBoolean("flutter.only_reply_keywords", true)
            return if (onlyKeywords) null else formatTags(defaultReply, sender, cleanMsg)
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
        val remoteInput: RemoteInput
    )
}
