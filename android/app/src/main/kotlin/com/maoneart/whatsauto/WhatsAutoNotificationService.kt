package com.maoneart.whatsauto

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

class WhatsAutoNotificationService : NotificationListenerService() {

    private val TAG = "WhatsAutoService"
    private val processedKeys = mutableMapOf<String, Long>()
    private val sessionState = mutableMapOf<String, String>() // senderId -> current parentId

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

        // Read settings from Flutter SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.is_auto_reply_enabled", false)
        if (!isEnabled) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        if (title.isEmpty() || text.isEmpty()) return
        if (title.contains("WhatsApp", ignoreCase = true) && text.contains("checking for new messages", ignoreCase = true)) return

        // Deduplication (ignore identical message from same sender within 2 seconds)
        val messageKey = "$packageName:$title:$text"
        val now = System.currentTimeMillis()
        val lastSeen = processedKeys[messageKey] ?: 0L
        if (now - lastSeen < 2500) return
        processedKeys[messageKey] = now

        // Find Quick Reply Action with RemoteInput
        val quickReplyAction = findQuickReplyAction(notification) ?: return

        // Compute reply text using Tree Menu & Rules
        val replyText = computeReply(title, text, prefs) ?: return

        // Send Auto Reply!
        sendReply(this, quickReplyAction, replyText)
    }

    private fun findQuickReplyAction(notification: Notification): ActionInfo? {
        val actions = notification.actions ?: return null
        for (action in actions) {
            val remoteInputs = action.remoteInputs ?: continue
            for (ri in remoteInputs) {
                if (ri.resultKey != null) {
                    return ActionInfo(action.actionIntent, ri)
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
            val nodesArray = JSONArray(treeJsonStr)
            val nodes = mutableListOf<JSONObject>()
            for (i in 0 until nodesArray.length()) {
                nodes.add(nodesArray.getJSONObject(i))
            }

            // Check if sender wants to restart/menu
            val currentParent = sessionState[sender] ?: "parent"
            if (cleanMsg.equals("menu", ignoreCase = true) || cleanMsg.equals("halo", ignoreCase = true) || cleanMsg.equals("batal", ignoreCase = true) || cleanMsg == "0") {
                sessionState[sender] = "parent"
                return renderMenu(nodes, "parent")
            }

            // Try matching user choice with options under currentParent
            val options = nodes.filter { it.optString("parentId") == currentParent && it.optInt("type") == 2 }

            var matchedOption: JSONObject? = null

            // 1. Check if user typed a number (1, 2, 3...)
            val numChoice = cleanMsg.toIntOrNull()
            if (numChoice != null && numChoice in 1..options.size) {
                matchedOption = options[numChoice - 1]
            } else {
                // 2. Check if user typed text matching the option title
                matchedOption = options.firstOrNull {
                    val optText = it.optString("text").trim()
                    optText.equals(cleanMsg, ignoreCase = true) || optText.contains(cleanMsg, ignoreCase = true)
                }
            }

            if (matchedOption != null) {
                val matchedId = matchedOption.optString("id")
                // Check if this option has children (submenu)
                val subPrompt = nodes.firstOrNull { it.optString("parentId") == matchedId && it.optInt("type") == 1 }
                val subOptions = nodes.filter { it.optString("parentId") == matchedId && it.optInt("type") == 2 }

                if (subOptions.isNotEmpty()) {
                    sessionState[sender] = matchedId
                    return renderMenu(nodes, matchedId)
                } else if (subPrompt != null) {
                    // Leaf response (e.g. Price or Spec detail)
                    sessionState[sender] = "parent" // Reset to root for next interaction
                    val returnPrompt = "\n\n*(Ketik 0 atau 'menu' untuk kembali ke menu utama)*"
                    return subPrompt.optString("text") + returnPrompt
                }
            }

            // If not in session or invalid input at root, show root menu
            if (currentParent == "parent") {
                return renderMenu(nodes, "parent")
            } else {
                // Invalid input at submenu, re-show current submenu
                return "Pilihan tidak valid. Silakan pilih nomor yang sesuai:\n\n" + renderMenu(nodes, currentParent)
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
