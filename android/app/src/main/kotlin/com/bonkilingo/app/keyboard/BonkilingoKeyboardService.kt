package com.bonkilingo.app.keyboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.res.Configuration
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import com.bonkilingo.app.R
import java.util.concurrent.Executors

/**
 * The Bonkilingo keyboard for Android: a German/English keyboard with a
 * Bonkilingo bar on top. Correct sends the selection (or the text around the
 * cursor) to the backend and offers to replace it with the correction, like
 * the iOS keyboard (ios/BonkilingoKeyboard/KeyboardViewController.swift).
 *
 * Plain Android views on purpose: no Flutter engine in the keyboard.
 */
class BonkilingoKeyboardService : InputMethodService(), KeyboardView.Listener {
    private lateinit var store: KeyboardStore
    private lateinit var client: CorrectionClient
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private lateinit var bar: BonkilingoBar
    private lateinit var keys: KeyboardView
    private lateinit var panel: CorrectionPanel
    private lateinit var keyArea: FrameLayout

    private var mode = KeyboardMode.LETTERS
    private var letterLayout = LetterLayout.ENGLISH
    private var shift = ShiftState.OFF
    private var lastShiftTap = 0L
    private var correctionsEnabled = true

    /** The cursor/selection in the field, from onUpdateSelection. */
    private var selStart = -1
    private var selEnd = -1

    /** Bumped to drop the result of a correction that was cancelled. */
    private var generation = 0
    private var pending: Pair<CapturedText, String>? = null

    private var deleteRepeats = 0
    private val deleteRepeat = object : Runnable {
        override fun run() {
            deleteRepeats++
            // After a while, delete whole words, like the system keyboard.
            if (deleteRepeats > 15) deleteWord() else deleteOnce()
            mainHandler.postDelayed(this, 80)
        }
    }

    override fun onCreate() {
        super.onCreate()
        store = KeyboardStore(this)
        client = CorrectionClient(getString(R.string.bonkilingo_api_base_url))
        letterLayout = LetterLayout.of(store.letterLayout)
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }

    override fun onCreateInputView(): View {
        bar = BonkilingoBar(this).apply {
            onCorrect = { startCorrection() }
            onToggleLayout = { toggleLetterLayout() }
        }
        keys = KeyboardView(this).apply { listener = this@BonkilingoKeyboardService }
        panel = CorrectionPanel(this).apply {
            visibility = View.GONE
            onClose = { closePanel() }
            onReplace = { replaceWithCorrection() }
            onCopy = { copyCorrection() }
        }

        keyArea = FrameLayout(this).apply {
            addView(keys, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))
            addView(panel, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(bar, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, bar.dp(48f)))
            addView(keyArea, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        // Keep the keys above the navigation bar (keyboards draw behind it on recent Android).
        root.setOnApplyWindowInsetsListener { view, insets ->
            val bottom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                insets.getInsets(WindowInsets.Type.navigationBars()).bottom
            } else {
                @Suppress("DEPRECATION") insets.systemWindowInsetBottom
            }
            view.setPadding(0, 0, 0, bottom)
            insets
        }
        applyAppearance(root)
        reloadKeys()
        return root
    }

    // Fullscreen (extract) mode in landscape would hide the field the user is correcting.
    override fun onEvaluateFullscreenMode(): Boolean = false

    /**
     * Android hides on-screen keyboards while a physical keyboard is attached.
     * Like Gboard's strip, keep the Bonkilingo bar so Correct still works;
     * only the keys go away (see [hasHardwareKeyboard]).
     */
    override fun onEvaluateInputViewShown(): Boolean {
        super.onEvaluateInputViewShown()
        return true
    }

    private fun hasHardwareKeyboard(): Boolean {
        val config = resources.configuration
        return config.keyboard != Configuration.KEYBOARD_NOKEYS &&
            config.hardKeyboardHidden == Configuration.HARDKEYBOARDHIDDEN_NO
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        correctionsEnabled = store.correctionsEnabled
        selStart = info.initialSelStart
        selEnd = info.initialSelEnd
        mode = when (info.inputType and InputType.TYPE_MASK_CLASS) {
            InputType.TYPE_CLASS_NUMBER, InputType.TYPE_CLASS_PHONE, InputType.TYPE_CLASS_DATETIME -> KeyboardMode.NUMBERS
            else -> KeyboardMode.LETTERS
        }
        if (!restarting) shift = ShiftState.OFF
        keys.keyHeightDp = if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) 38f else 46f
        keys.visibility = if (hasHardwareKeyboard()) View.GONE else View.VISIBLE
        (keys.parent?.parent as? View)?.let { applyAppearance(it) }
        reloadKeys()
        closePanel()
        updateAutoShift()
        updateBar()
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        stopDeleteRepeat()
        generation++
        pending = null
        super.onFinishInputView(finishingInput)
    }

    override fun onUpdateSelection(
        oldSelStart: Int, oldSelEnd: Int, newSelStart: Int, newSelEnd: Int,
        candidatesStart: Int, candidatesEnd: Int,
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        selStart = newSelStart
        selEnd = newSelEnd
        if (deleteRepeats == 0) updateAutoShift()
    }

    // MARK: Appearance and keys

    private fun applyAppearance(root: View) {
        val dark = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val colors = KeyColors.make(dark)
        root.setBackgroundColor(colors.background)
        keys.colors = colors
        bar.apply(dark)
        panel.apply(dark)
    }

    private fun showsSwitchKey(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) shouldOfferSwitchingToNextInputMethod() else true

    private fun reloadKeys() {
        keys.load(KeyboardLayouts.page(mode, letterLayout, showsSwitchKey()))
        keys.setReturnLabel(returnLabel())
        keys.setShift(if (mode == KeyboardMode.LETTERS) shift else ShiftState.OFF)
        bar.setLayoutTitle(letterLayout.label)
    }

    private fun returnLabel(): String? {
        val info = currentInputEditorInfo ?: return null
        if ((info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) != 0) return null
        return when (info.imeOptions and EditorInfo.IME_MASK_ACTION) {
            EditorInfo.IME_ACTION_GO -> "Go"
            EditorInfo.IME_ACTION_SEARCH -> "Search"
            EditorInfo.IME_ACTION_SEND -> "Send"
            EditorInfo.IME_ACTION_NEXT -> "Next"
            EditorInfo.IME_ACTION_DONE -> "Done"
            EditorInfo.IME_ACTION_PREVIOUS -> "Back"
            else -> null
        }
    }

    private fun toggleLetterLayout() {
        letterLayout = letterLayout.toggled
        store.letterLayout = letterLayout.code
        reloadKeys()
    }

    // MARK: Typing

    override fun onKeyPressed(key: Key) {
        when (key) {
            is Key.Delete -> {
                deleteOnce()
                deleteRepeats = 0
                mainHandler.removeCallbacks(deleteRepeat)
                mainHandler.postDelayed(deleteRepeat, 450)
            }
            is Key.Shift -> shiftTapped()
            else -> Unit
        }
    }

    override fun onKeyReleased(key: Key) {
        val ic = currentInputConnection ?: return
        when (key) {
            is Key.Character -> {
                val upper = shift != ShiftState.OFF && mode == KeyboardMode.LETTERS
                ic.commitText(if (upper) key.text.uppercase() else key.text, 1)
                if (shift == ShiftState.ON) setShift(ShiftState.OFF)
            }
            is Key.Space -> handleSpace(ic)
            is Key.Return -> sendKeyChar('\n')
            is Key.Mode -> {
                mode = key.target
                reloadKeys()
                if (mode == KeyboardMode.LETTERS) updateAutoShift()
            }
            is Key.Delete -> stopDeleteRepeat()
            is Key.SwitchKeyboard -> switchKeyboard()
            is Key.Shift, is Key.Gap -> Unit
        }
    }

    override fun onSwitchKeyboardLongPress() {
        (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker()
    }

    private fun switchKeyboard() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            switchToNextInputMethod(false)
        } else {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            @Suppress("DEPRECATION")
            window.window?.attributes?.token?.let { imm.switchToNextInputMethod(it, false) }
        }
    }

    private fun handleSpace(ic: InputConnection) {
        val before = ic.getTextBeforeCursor(2, 0)?.toString() ?: ""
        // Double space ends a sentence: "word  " becomes "word. ".
        if (before.length == 2 && before[1] == ' ' && before[0].isLetterOrDigit()) {
            ic.deleteSurroundingText(1, 0)
            ic.commitText(". ", 1)
        } else {
            ic.commitText(" ", 1)
        }
        // Like the system keyboard, a space on the number pages returns to letters.
        val numberField = ((currentInputEditorInfo?.inputType ?: 0) and InputType.TYPE_MASK_CLASS) != InputType.TYPE_CLASS_TEXT
        if (mode != KeyboardMode.LETTERS && !numberField) {
            mode = KeyboardMode.LETTERS
            reloadKeys()
        }
    }

    private fun deleteOnce() {
        // Key events handle selections and emoji (surrogate pairs) correctly in every editor.
        sendDownUpKeyEvents(KeyEvent.KEYCODE_DEL)
    }

    private fun deleteWord() {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(64, 0)?.toString() ?: return
        if (before.isEmpty()) return
        var count = 0
        var sawWordCharacter = false
        for (c in before.reversed()) {
            if (c.isWhitespace() || !c.isLetterOrDigit()) {
                if (sawWordCharacter) break
            } else {
                sawWordCharacter = true
            }
            count++
        }
        ic.deleteSurroundingText(maxOf(count, 1), 0)
    }

    private fun stopDeleteRepeat() {
        mainHandler.removeCallbacks(deleteRepeat)
        deleteRepeats = 0
        updateAutoShift()
    }

    private fun shiftTapped() {
        val now = System.currentTimeMillis()
        if (now - lastShiftTap < 300) {
            setShift(ShiftState.LOCKED)
            lastShiftTap = 0
        } else {
            setShift(if (shift == ShiftState.OFF) ShiftState.ON else ShiftState.OFF)
            lastShiftTap = now
        }
    }

    private fun setShift(state: ShiftState) {
        shift = state
        if (::keys.isInitialized) keys.setShift(if (mode == KeyboardMode.LETTERS) state else ShiftState.OFF)
    }

    /** Shift on at the start of a sentence (or word), following the field's capitalization setting. */
    private fun updateAutoShift() {
        if (!::keys.isInitialized || shift == ShiftState.LOCKED || mode != KeyboardMode.LETTERS) return
        val info = currentInputEditorInfo ?: return
        val ic = currentInputConnection ?: return
        setShift(if (ic.getCursorCapsMode(info.inputType) != 0) ShiftState.ON else ShiftState.OFF)
    }

    // MARK: Bar

    /** Password fields: never send their text, and never keep it. */
    private fun isSensitiveField(): Boolean {
        val type = currentInputEditorInfo?.inputType ?: return false
        val variation = type and InputType.TYPE_MASK_VARIATION
        return when (type and InputType.TYPE_MASK_CLASS) {
            InputType.TYPE_CLASS_TEXT -> variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
            InputType.TYPE_CLASS_NUMBER -> variation == InputType.TYPE_NUMBER_VARIATION_PASSWORD
            else -> false
        }
    }

    /** Incognito fields (e.g. private browser tabs) ask keyboards not to remember what is typed. */
    private fun isIncognito(): Boolean =
        ((currentInputEditorInfo?.imeOptions ?: 0) and EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING) != 0

    private fun updateBar() {
        when {
            isSensitiveField() -> {
                bar.setStatus("Correct is off in password fields")
                bar.setCorrect(visible = false, enabled = false)
            }
            !correctionsEnabled -> {
                bar.setStatus("Correct is off in the Bonkilingo app")
                bar.setCorrect(visible = false, enabled = false)
            }
            else -> {
                bar.setStatus("Select text, or tap Correct for the whole message")
                bar.setCorrect(visible = true, enabled = panel.visibility != View.VISIBLE)
            }
        }
    }

    // MARK: Correct

    private fun capture(): CapturedText? {
        val ic = currentInputConnection ?: return null
        return TextCapture.capture(
            ic.getTextBeforeCursor(TextCapture.WINDOW, 0),
            ic.getTextAfterCursor(TextCapture.WINDOW, 0),
            ic.getSelectedText(0),
        )
    }

    private fun startCorrection() {
        if (!correctionsEnabled || isSensitiveField()) return
        val captured = capture()
        if (captured == null) {
            showPanel(CorrectionPanel.State.Message("Write something first, or select the text to correct, then tap Correct.", canCopy = false))
            return
        }
        showPanel(CorrectionPanel.State.Loading)
        val run = ++generation
        val token = store.token
        val keep = store.saveToHistory && !isIncognito()
        executor.execute {
            val result = runCatching { client.correct(captured.core, token) }
            mainHandler.post {
                if (run != generation || panel.visibility != View.VISIBLE) return@post
                result.onSuccess { corrected ->
                    if (captured.restoringWhitespace(corrected) == captured.full) {
                        panel.show(CorrectionPanel.State.Unchanged)
                        return@onSuccess
                    }
                    pending = captured to corrected
                    if (keep) store.appendHistory(captured.core, corrected)
                    val note = if (captured.mayBeCutOff) {
                        "The keyboard may only see part of a long message. Select all of it to correct everything."
                    } else null
                    panel.show(CorrectionPanel.State.Result(captured.core, corrected, note))
                }.onFailure { error ->
                    val message = (error as? CorrectionException)?.message
                        ?: "Bonkilingo couldn't correct this right now. Try again."
                    panel.show(CorrectionPanel.State.Message(message, canCopy = false))
                }
            }
        }
    }

    private fun replaceWithCorrection() {
        val (captured, corrected) = pending ?: return
        val ic = currentInputConnection ?: return

        // Only replace what the correction was made for.
        if (capture() != captured) {
            panel.show(CorrectionPanel.State.Message("Your text changed since you tapped Correct. Tap Correct again.", canCopy = true))
            return
        }

        ic.beginBatchEdit()
        if (captured.scope == CapturedText.Scope.SELECTION) {
            // Typing over a selection replaces it.
            ic.commitText(captured.restoringWhitespace(corrected), 1)
        } else {
            val plan = Replacement.plan(captured, corrected)
            val cursor = if (selStart == selEnd) selStart else -1
            if (plan != null && cursor >= captured.before.length) {
                val base = cursor - captured.before.length
                ic.setSelection(base + plan.start, base + plan.end)
                ic.commitText(plan.insertion, 1)
                ic.setSelection(base + plan.cursor, base + plan.cursor)
            } else if (plan != null) {
                // Cursor position unknown: rewrite the whole captured text.
                ic.deleteSurroundingText(captured.before.length, captured.after.length)
                ic.commitText(captured.restoringWhitespace(corrected), 1)
            }
        }
        ic.endBatchEdit()
        closePanel()
    }

    private fun copyCorrection() {
        val (captured, corrected) = pending ?: return
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Bonkilingo correction", captured.restoringWhitespace(corrected)))
        closePanel()
        bar.setStatus("Copied. Paste it where you need it.")
    }

    private fun showPanel(state: CorrectionPanel.State) {
        panel.show(state)
        // Without keys (physical keyboard) the panel needs room of its own.
        keyArea.minimumHeight = if (keys.visibility == View.VISIBLE) 0 else keyArea.dp(220f)
        panel.visibility = View.VISIBLE
        bar.setCorrect(visible = true, enabled = false)
    }

    private fun closePanel() {
        if (!::panel.isInitialized) return
        generation++
        pending = null
        panel.visibility = View.GONE
        keyArea.minimumHeight = 0
        updateBar()
    }
}
