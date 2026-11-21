package com.bonkilingo.app.keyboard

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.BackgroundColorSpan
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView

internal val BRAND_YELLOW = Color.rgb(0xEA, 0xB3, 0x08)

internal fun View.dp(value: Float): Int = (value * resources.displayMetrics.density).toInt()

private fun rounded(color: Int, radius: Float, stroke: Int? = null, strokeWidth: Int = 0) =
    GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius
        if (stroke != null) setStroke(strokeWidth, stroke)
    }

/** The strip above the keys: brand, layout switch, a status line and Correct. */
class BonkilingoBar(context: Context) : LinearLayout(context) {
    var onCorrect: (() -> Unit)? = null
    var onToggleLayout: (() -> Unit)? = null

    private val dot = View(context)
    private val brand = TextView(context)
    private val layoutButton = TextView(context)
    private val status = TextView(context)
    private val correct = TextView(context)

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(10f), 0, dp(8f), 0)

        dot.background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(BRAND_YELLOW) }
        addView(dot, LayoutParams(dp(8f), dp(8f)).apply { marginEnd = dp(6f) })

        brand.text = "Bonkilingo"
        brand.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        brand.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        addView(brand, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))

        layoutButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        layoutButton.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        layoutButton.gravity = Gravity.CENTER
        layoutButton.setPadding(dp(6f), dp(2f), dp(6f), dp(2f))
        layoutButton.setOnClickListener { onToggleLayout?.invoke() }
        addView(layoutButton, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            marginStart = dp(8f)
        })

        status.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        status.maxLines = 2
        addView(status, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
            marginStart = dp(10f)
            marginEnd = dp(8f)
        })

        correct.text = "Correct"
        correct.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        correct.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        correct.setTextColor(Color.BLACK)
        correct.gravity = Gravity.CENTER
        correct.setPadding(dp(16f), dp(6f), dp(16f), dp(6f))
        correct.background = rounded(BRAND_YELLOW, dp(16f).toFloat())
        correct.setOnClickListener { if (correct.isEnabled) onCorrect?.invoke() }
        addView(correct, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT))
    }

    fun apply(dark: Boolean) {
        val text = if (dark) Color.WHITE else Color.BLACK
        val muted = if (dark) Color.rgb(0xA1, 0xA1, 0xA6) else Color.rgb(0x5F, 0x60, 0x66)
        setBackgroundColor(if (dark) Color.rgb(0x1F, 0x1F, 0x21) else Color.rgb(0xD1, 0xD4, 0xDA))
        brand.setTextColor(text)
        status.setTextColor(muted)
        layoutButton.setTextColor(text)
        layoutButton.background = rounded(Color.TRANSPARENT, dp(6f).toFloat(), muted, dp(1f))
    }

    fun setLayoutTitle(title: String) {
        layoutButton.text = title
        layoutButton.contentDescription = "Keyboard layout $title"
    }

    fun setStatus(text: String) {
        status.text = text
    }

    fun setCorrect(visible: Boolean, enabled: Boolean) {
        correct.visibility = if (visible) VISIBLE else GONE
        correct.isEnabled = enabled
        correct.alpha = if (enabled) 1f else 0.5f
    }
}

/** Shown over the keys while correcting: progress, then the corrected text with Copy and Replace. */
class CorrectionPanel(context: Context) : FrameLayout(context) {
    sealed class State {
        object Loading : State()
        data class Result(val original: String, val corrected: String, val note: String?) : State()
        object Unchanged : State()
        data class Message(val text: String, val canCopy: Boolean) : State()
    }

    var onClose: (() -> Unit)? = null
    var onReplace: (() -> Unit)? = null
    var onCopy: (() -> Unit)? = null

    private val title = TextView(context)
    private val close = TextView(context)
    private val body = TextView(context)
    private val progress = ProgressBar(context)
    private val buttons = LinearLayout(context)
    private val copy = TextView(context)
    private val replace = TextView(context)
    private var dark = false

    init {
        // Covers the keys: taps on the panel must not reach them.
        isClickable = true
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14f), dp(10f), dp(14f), dp(12f))
        }
        addView(column, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        val header = LinearLayout(context).apply { gravity = Gravity.CENTER_VERTICAL }
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        header.addView(title, LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        close.text = "✕"
        close.contentDescription = "Close"
        close.gravity = Gravity.CENTER
        close.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        close.setOnClickListener { onClose?.invoke() }
        header.addView(close, LinearLayout.LayoutParams(dp(30f), dp(30f)))
        column.addView(header)

        val scroll = ScrollView(context)
        val content = FrameLayout(context)
        body.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
        body.setLineSpacing(0f, 1.15f)
        content.addView(body)
        content.addView(progress, LayoutParams(dp(28f), dp(28f), Gravity.START or Gravity.TOP))
        scroll.addView(content)
        column.addView(scroll, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f).apply {
            topMargin = dp(8f)
        })

        buttons.orientation = LinearLayout.HORIZONTAL
        for ((button, label) in listOf(copy to "Copy", replace to "Replace")) {
            button.text = label
            button.gravity = Gravity.CENTER
            button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            button.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            buttons.addView(button, LinearLayout.LayoutParams(0, dp(44f), 1f).apply {
                if (button === replace) marginStart = dp(10f)
            })
        }
        copy.setOnClickListener { onCopy?.invoke() }
        replace.setOnClickListener { onReplace?.invoke() }
        column.addView(buttons, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(8f)
        })
    }

    fun apply(dark: Boolean) {
        this.dark = dark
        val text = if (dark) Color.WHITE else Color.BLACK
        setBackgroundColor(if (dark) Color.rgb(0x2A, 0x2A, 0x2D) else Color.rgb(0xC6, 0xCA, 0xD1))
        title.setTextColor(text)
        body.setTextColor(text)
        close.setTextColor(if (dark) Color.BLACK else Color.WHITE)
        close.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(if (dark) Color.rgb(0xA1, 0xA1, 0xA6) else Color.rgb(0x7A, 0x7C, 0x82))
        }
        copy.setTextColor(text)
        copy.background = rounded(if (dark) Color.rgb(0x5A, 0x5A, 0x5E) else Color.WHITE, dp(10f).toFloat())
        replace.setTextColor(Color.BLACK)
        replace.background = rounded(BRAND_YELLOW, dp(10f).toFloat())
    }

    fun show(state: State) {
        progress.visibility = GONE
        body.visibility = VISIBLE
        when (state) {
            State.Loading -> {
                title.text = "Correcting…"
                body.visibility = INVISIBLE
                progress.visibility = VISIBLE
                setButtons(copy = false, replace = false)
            }
            is State.Result -> {
                title.text = "Suggestion"
                body.text = highlighted(state.original, state.corrected, state.note)
                setButtons(copy = true, replace = true)
            }
            State.Unchanged -> {
                title.text = "Looks good"
                body.text = "No changes needed."
                setButtons(copy = false, replace = false)
            }
            is State.Message -> {
                title.text = "Bonkilingo"
                body.text = state.text
                setButtons(copy = state.canCopy, replace = false)
            }
        }
    }

    private fun setButtons(copy: Boolean, replace: Boolean) {
        this.copy.visibility = if (copy) VISIBLE else GONE
        this.replace.visibility = if (replace) VISIBLE else GONE
        buttons.visibility = if (copy || replace) VISIBLE else GONE
        (this.replace.layoutParams as LinearLayout.LayoutParams).marginStart = if (copy) dp(10f) else 0
    }

    /** The corrected text with changed words tinted and bold. */
    private fun highlighted(original: String, corrected: String, note: String?): CharSequence {
        val tint = if (dark) Color.argb(0x66, 0xEA, 0xB3, 0x08) else Color.argb(0x55, 0xEA, 0xB3, 0x08)
        val out = SpannableStringBuilder()
        for (piece in WordDiff.highlight(original, corrected)) {
            val start = out.length
            out.append(piece.text)
            if (piece.changed) {
                out.setSpan(BackgroundColorSpan(tint), start, out.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                out.setSpan(StyleSpan(Typeface.BOLD), start, out.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }
        if (note != null) out.append("\n\n").append(note)
        return out
    }
}
