package com.bonkilingo.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import android.view.textclassifier.TextClassificationManager
import android.view.textclassifier.TextLanguage
import com.bonkilingo.app.keyboard.BonkilingoKeyboardService
import com.bonkilingo.app.keyboard.KeyboardStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val background = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerKeyboardSettingsChannel(flutterEngine)
    }

    override fun onDestroy() {
        background.shutdown()
        super.onDestroy()
    }

    /**
     * Settings and data for the Bonkilingo keyboard
     * (keyboard/BonkilingoKeyboardService.kt), read and written from Flutter
     * (lib/data/data_sources/local/keyboard_settings.dart). Same channel and
     * methods as ios/Runner/AppDelegate.swift, plus the Android-only setup
     * helpers (opening keyboard settings, the keyboard picker, status).
     */
    private fun registerKeyboardSettingsChannel(engine: FlutterEngine) {
        val store = KeyboardStore(this)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.bonkilingo.app/keyboard_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBool" -> {
                        val key = call.argument<String>("key")
                            ?: return@setMethodCallHandler result.error("bad_args", "Missing key", null)
                        result.success(store.getBool(key, call.argument<Boolean>("defaultValue") ?: false))
                    }
                    "setBool" -> {
                        val key = call.argument<String>("key")
                        val value = call.argument<Boolean>("value")
                        if (key == null || value == null) {
                            result.error("bad_args", "Missing key or value", null)
                        } else {
                            store.setBool(key, value)
                            result.success(null)
                        }
                    }
                    "readHistoryQueue" -> background.execute {
                        val entries = store.readHistory().map { entry ->
                            val corrected = entry["corrected"] as? String
                            val language = corrected?.let { detectLanguage(it) }
                            if (language != null) entry + ("languageCode" to language) else entry
                        }
                        mainHandler.post { result.success(entries) }
                    }
                    "removeHistoryEntries" -> {
                        store.removeHistory(call.argument<List<String>>("ids")?.toSet() ?: emptySet())
                        result.success(null)
                    }
                    "setKeyboardToken" -> {
                        store.token = call.argument<String>("token")
                        result.success(null)
                    }
                    "keyboardStatus" -> result.success(keyboardStatus())
                    "openKeyboardSettings" -> {
                        startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(true)
                    }
                    "showKeyboardPicker" -> {
                        (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Whether the Bonkilingo keyboard is turned on in system settings, and whether it is the current one. */
    private fun keyboardStatus(): Map<String, Boolean> {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val ours = ComponentName(this, BonkilingoKeyboardService::class.java)
        val enabled = imm.enabledInputMethodList.any { it.component == ours }
        val current = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?.let { ComponentName.unflattenFromString(it) }
        return mapOf("enabled" to enabled, "selected" to (current == ours))
    }

    /** The text's language as an ISO code, detected on the device (Android 10+). Off the main thread. */
    private fun detectLanguage(text: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        return try {
            val classifier = getSystemService(TextClassificationManager::class.java)?.textClassifier ?: return null
            val language = classifier.detectLanguage(TextLanguage.Request.Builder(text).build())
            if (language.localeHypothesisCount == 0) return null
            val locale = language.getLocale(0)
            if (language.getConfidenceScore(locale) < 0.5f) null else locale.toLanguageTag()
        } catch (e: Exception) {
            null
        }
    }
}
