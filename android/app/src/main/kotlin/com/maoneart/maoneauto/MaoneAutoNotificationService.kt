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

        val extras = notification.extras ?: return

        val rawTitle = extras.getString(Notification.EXTRA_TITLE) ?: ""
        var rawText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        if (rawText.isEmpty()) {
            rawText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        }

        if (rawTitle.isEmpty() || rawText.isEmpty()) return
        if (rawTitle.contains("WhatsApp", ignoreCase = true) && rawText.contains("checking for new messages", ignoreCase = true)) return

        // Bersihkan title pengirim dari embel-embel "(1 pesan)"
        val cleanSender = rawTitle.replace(Regex("\\s*\\(\\d+\\s+pesan\\)", RegexOption.IGNORE_CASE), "").trim()
        val cleanMsg = rawText.trim()

        val now = System.currentTimeMillis()

        // 3. Debounce per-pengirim: jangan balas lebih dari 1 kali dalam 2.5 detik untuk pengirim yang sama
        val lastSenderReply = lastReplyPerSender[cleanSender] ?: 0L
        if (now - lastSenderReply < 2500) return

        // 4. Deduplikasi pesan identik
        val messageKey = "$packageName:$cleanSender:$cleanMsg"
        val lastSeen = processedKeys[messageKey] ?: 0L
        if (now - lastSeen < 3000) return
        processedKeys[messageKey] = now

        // 5. Cari Quick Reply Action dengan RemoteInput
        val quickReplyAction = findQuickReplyAction(notification) ?: return

        // 6. Hitung teks balasan dengan Tree Menu & Rule
        val replyText = computeReply(cleanSender, cleanMsg, prefs) ?: return

        // 7. Catat waktu sebelum kirim agar event susulan langsung di-drop
        lastReplyPerSender[cleanSender] = now

        // 8. Kirim Balasan Otomatis
        sendReply(this, quickReplyAction, replyText)
    }

    private fun findQuickReplyAction(notification: Notification): ActionInfo? {
        val actions = notification.actions ?: return null
        for (action in actions) {
            val pendingIntent = action.actionIntent ?: continue
            val remoteInputs = action.remoteInputs ?: continue
            for (ri in remoteInputs) {
                if (ri.resultKey != null) {
                    return ActionInfo(pendingIntent, ri)
                }
            }
        }
        return null
    }

    private fun sendReply(context: Context, actionInfo: ActionInfo, replyMessage: String) {
        try {
            val intent = Intent()
            val bundle = Bundle()
            bundle.putCharSequence(actionInfo.remoteInput.resultKey, replyMessage)
            RemoteInput.addResultsToIntent(arrayOf(actionInfo.remoteInput), intent, bundle)
            actionInfo.pendingIntent.send(context, 0, intent)
            Log.d(TAG, "Auto-reply sent successfully to notification")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send auto-reply: ${e.message}")
        }
    }

    private fun computeReply(sender: String, messageText: String, prefs: android.content.SharedPreferences): String? {
        val cleanMsg = messageText.trim()
        val treeJsonStr = prefs.getString("flutter.menu_nodes_cache", null)
        val defaultReply = prefs.getString("flutter.default_reply", "Halo! Terima kasih telah menghubungi kami.") ?: "Halo!"

        if (treeJsonStr.isNullOrEmpty()) {
            return defaultReply
        }

        try {
            // 0. Cek Balasan Kata Kunci (Keyword Replies)
            val isKeywordEnabled = prefs.getBoolean("flutter.is_keyword_reply_enabled", true)
            val keywordJsonStr = prefs.getString("flutter.keyword_replies_cache", null)
            if (isKeywordEnabled && !keywordJsonStr.isNullOrEmpty()) {
                try {
                    val kwArray = JSONArray(keywordJsonStr)
                    for (i in 0 until kwArray.length()) {
                        val rule = kwArray.getJSONObject(i)
                        if (!rule.optBoolean("isEnabled", true)) continue
                        val rawKeywords = rule.optString("incomingKeywords", "")
                        val isExact = rule.optBoolean("isExactMatch", true)
                        val keywordsList = rawKeywords.split(",").map { it.trim().lowercase() }.filter { it.isNotEmpty() }
                        val lowerMsg = cleanMsg.lowercase()

                        val isMatch = if (isExact) {
                            keywordsList.any { lowerMsg == it }
                        } else {
                            keywordsList.any { lowerMsg.contains(it) }
                        }

                        if (isMatch) {
                            var rep = rule.optString("replyMessage", "")
                            val senderParts = sender.split(" ")
                            val firstName = senderParts.firstOrNull() ?: sender
                            val lastName = if (senderParts.size > 1) senderParts.drop(1).joinToString(" ") else ""

                            rep = rep.replace("{{nama}}", sender, ignoreCase = true)
                            rep = rep.replace("{{nama_depan}}", firstName, ignoreCase = true)
                            rep = rep.replace("{{nama_belakang}}", lastName, ignoreCase = true)

                            if (rule.optBoolean("useMenuReply", false)) {
                                val nodesArray = JSONArray(treeJsonStr)
                                val nodes = mutableListOf<JSONObject>()
                                for (j in 0 until nodesArray.length()) {
                                    nodes.add(nodesArray.getJSONObject(j))
                                }
                                prefs.edit().putString("flutter.session_$sender", "parent").apply()
                                return "$rep\n\n" + renderMenu(nodes, "parent")
                            }
                            return rep
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error checking keyword replies: ${e.message}")
                }
            }

            val nodesArray = JSONArray(treeJsonStr)
            val nodes = mutableListOf<JSONObject>()
            for (i in 0 until nodesArray.length()) {
                nodes.add(nodesArray.getJSONObject(i))
            }

            val sessionPrefKey = "flutter.session_$sender"
            val currentParent = prefs.getString(sessionPrefKey, "parent") ?: "parent"

            // A. Cek apakah pengirim ingin reset ke menu utama
            if (cleanMsg.equals("menu", ignoreCase = true) ||
                cleanMsg.equals("halo", ignoreCase = true) ||
                cleanMsg.equals("hi", ignoreCase = true) ||
                cleanMsg.equals("batal", ignoreCase = true) ||
                cleanMsg == "0") {
                prefs.edit().putString(sessionPrefKey, "parent").apply()
                return renderMenu(nodes, "parent")
            }

            // B. Cocokkan pilihan dengan opsi di bawah currentParent
            val options = nodes.filter { it.optString("parentId") == currentParent && it.optInt("type") == 2 }

            var matchedOption: JSONObject? = null

            // 1. Cek kecocokan berdasarkan nomor urut (1, 2, 3...)
            val numChoice = cleanMsg.toIntOrNull()
            if (numChoice != null && numChoice in 1..options.size) {
                matchedOption = options[numChoice - 1]
            } else {
                // 2. Cek kecocokan berdasarkan teks judul opsi
                matchedOption = options.firstOrNull {
                    val optText = it.optString("text").trim()
                    optText.equals(cleanMsg, ignoreCase = true) || optText.contains(cleanMsg, ignoreCase = true)
                }
            }

            if (matchedOption != null) {
                val matchedId = matchedOption.optString("id")
                // Cek apakah node ini memiliki anak opsi (submenu)
                val subPrompt = nodes.firstOrNull { it.optString("parentId") == matchedId && it.optInt("type") == 1 }
                val subOptions = nodes.filter { it.optString("parentId") == matchedId && it.optInt("type") == 2 }

                if (subOptions.isNotEmpty()) {
                    prefs.edit().putString(sessionPrefKey, matchedId).apply()
                    return renderMenu(nodes, matchedId)
                } else if (subPrompt != null) {
                    // Leaf response (detail harga / info)
                    prefs.edit().putString(sessionPrefKey, "parent").apply()
                    val returnPrompt = "\n\n*(Ketik 0 atau 'menu' untuk kembali ke menu utama)*"
                    return subPrompt.optString("text") + returnPrompt
                } else {
                    prefs.edit().putString(sessionPrefKey, "parent").apply()
                    return matchedOption.optString("text") + "\n\n*(Ketik 0 atau 'menu' untuk kembali ke menu utama)*"
                }
            }

            // C. Jika input tidak cocok
            if (currentParent == "parent") {
                return renderMenu(nodes, "parent")
            } else {
                return "⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera di bawah:\n\n" + renderMenu(nodes, currentParent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in computeReply: ${e.message}")
            return defaultReply
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
            // Clean leading numbers if any to avoid double numbering
            val cleanTitle = rawTitle.replaceFirst(Regex("^\\d+\\.\\s*"), "")
            sb.append("${i + 1}. ").append(cleanTitle).append("\n")
        }

        if (parentId != "parent") {
            sb.append("\n0. ↩️ Kembali ke Menu Utama")
        }

        return sb.toString().trim()
    }

    data class ActionInfo(
        val pendingIntent: PendingIntent,
        val remoteInput: RemoteInput
    )
}
