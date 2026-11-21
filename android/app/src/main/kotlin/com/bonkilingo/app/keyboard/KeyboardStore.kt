package com.bonkilingo.app.keyboard

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Settings and data shared by the Bonkilingo keyboard and the app.
 *
 * The keyboard is an InputMethodService in the app's own package, so unlike
 * iOS no App Group is needed: both read the same private SharedPreferences.
 * The keys match the iOS App Group keys, and MainActivity exposes them to
 * Flutter over the same channel as ios/Runner/AppDelegate.swift
 * (lib/data/data_sources/local/keyboard_settings.dart).
 */
class KeyboardStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun getBool(key: String, defaultValue: Boolean): Boolean = prefs.getBoolean(key, defaultValue)

    fun setBool(key: String, value: Boolean) = prefs.edit().putBoolean(key, value).apply()

    /** The app's Correct on/off switch. */
    val correctionsEnabled: Boolean get() = getBool(CORRECTIONS_ENABLED, true)

    /** Whether corrections are kept for the app's History. */
    val saveToHistory: Boolean get() = getBool(SAVE_TO_HISTORY, true)

    /** The signed-in user's keyboard token (lib/data/services/keyboard_auth_service.dart). */
    var token: String?
        get() = prefs.getString(TOKEN, null)?.takeIf { it.startsWith("kb_") }
        set(value) {
            prefs.edit().apply { if (value == null) remove(TOKEN) else putString(TOKEN, value) }.apply()
        }

    /** The keyboard's own letter layout ("en" or "de"). */
    var letterLayout: String
        get() = prefs.getString(LETTER_LAYOUT, null) ?: defaultLayout()
        set(value) = prefs.edit().putString(LETTER_LAYOUT, value).apply()

    @Synchronized
    fun appendHistory(original: String, corrected: String, timestampMs: Long = System.currentTimeMillis()) {
        val queue = HistoryQueue.append(
            prefs.getString(HISTORY_QUEUE, null), original, corrected, timestampMs, UUID.randomUUID().toString(),
        )
        prefs.edit().putString(HISTORY_QUEUE, queue).apply()
    }

    /** The queued corrections, as JSON objects for the Flutter channel. */
    @Synchronized
    fun readHistory(): List<Map<String, Any>> = HistoryQueue.entries(prefs.getString(HISTORY_QUEUE, null))

    @Synchronized
    fun removeHistory(ids: Set<String>) {
        prefs.edit().putString(HISTORY_QUEUE, HistoryQueue.remove(prefs.getString(HISTORY_QUEUE, null), ids)).apply()
    }

    private fun defaultLayout(): String =
        if (java.util.Locale.getDefault().language == "de") "de" else "en"

    companion object {
        const val FILE = "bonkilingo_keyboard"
        const val CORRECTIONS_ENABLED = "keyboard.correctionsEnabled"
        const val SAVE_TO_HISTORY = "keyboard.saveToHistory"
        const val HISTORY_QUEUE = "keyboard.historyQueue"
        const val TOKEN = "keyboard.token"
        const val LETTER_LAYOUT = "keyboard.letterLayout"
    }
}

/**
 * The History queue as a JSON array string: entries
 * `{id, original, corrected, timestamp}` (milliseconds), oldest first, the
 * same shape the iOS keyboard writes (lib/data/data_sources/local/keyboard_history_queue.dart).
 */
object HistoryQueue {
    /** Oldest entries are dropped beyond this, so an app that is never opened doesn't grow it. */
    const val MAX_ENTRIES = 50
    const val MAX_TEXT_LENGTH = 2000

    fun append(json: String?, original: String, corrected: String, timestampMs: Long, id: String): String? {
        val o = original.take(MAX_TEXT_LENGTH)
        val c = corrected.take(MAX_TEXT_LENGTH)
        if (o.isBlank() || c.isBlank() || o == c) return json
        val items = parse(json)
        items += JSONObject()
            .put("id", id)
            .put("original", o)
            .put("corrected", c)
            .put("timestamp", timestampMs)
        while (items.size > MAX_ENTRIES) items.removeAt(0)
        return JSONArray(items).toString()
    }

    fun entries(json: String?): List<Map<String, Any>> = parse(json).map { item ->
        buildMap {
            for (key in item.keys()) put(key, item.get(key))
        }
    }

    /** Removes the given entries, and any without an id (they can never be acknowledged). */
    fun remove(json: String?, ids: Set<String>): String =
        JSONArray(
            parse(json).filter { item ->
                val id = item.optString("id", "")
                id.isNotEmpty() && id !in ids
            },
        ).toString()

    private fun parse(json: String?): MutableList<JSONObject> {
        if (json.isNullOrEmpty()) return mutableListOf()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { array.optJSONObject(it) }.toMutableList()
        } catch (e: org.json.JSONException) {
            mutableListOf()
        }
    }
}
