package com.bonkilingo.app.keyboard

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View

/** Colours for light and dark keyboards, close to the system keyboard. */
data class KeyColors(
    val background: Int,
    val key: Int,
    val keyPressed: Int,
    val specialKey: Int,
    val specialKeyPressed: Int,
    val shadow: Int,
    val label: Int,
) {
    companion object {
        fun make(dark: Boolean) = if (dark) {
            KeyColors(
                background = Color.rgb(0x1F, 0x1F, 0x21),
                key = Color.rgb(0x5A, 0x5A, 0x5E),
                keyPressed = Color.rgb(0x7A, 0x7A, 0x80),
                specialKey = Color.rgb(0x3A, 0x3A, 0x3D),
                specialKeyPressed = Color.rgb(0x5A, 0x5A, 0x5E),
                shadow = Color.rgb(0x0E, 0x0E, 0x10),
                label = Color.WHITE,
            )
        } else {
            KeyColors(
                background = Color.rgb(0xD1, 0xD4, 0xDA),
                key = Color.WHITE,
                keyPressed = Color.rgb(0xE4, 0xE6, 0xEA),
                specialKey = Color.rgb(0xAC, 0xB2, 0xBD),
                specialKeyPressed = Color.WHITE,
                shadow = Color.rgb(0x89, 0x8A, 0x8D),
                label = Color.BLACK,
            )
        }
    }
}

enum class ShiftState { OFF, ON, LOCKED }

/**
 * The keys, drawn on one canvas (cheaper than a view per key, which matters
 * for keyboards). Handles several fingers at once, so fast two-thumb typing
 * doesn't drop letters, and repeats delete while it is held.
 */
class KeyboardView(context: Context) : View(context) {
    interface Listener {
        fun onKeyPressed(key: Key)
        fun onKeyReleased(key: Key)
        fun onSwitchKeyboardLongPress()
    }

    var listener: Listener? = null
    var colors: KeyColors = KeyColors.make(false)
        set(value) { field = value; invalidate() }
    var keyHeightDp: Float = 48f
        set(value) { field = value; requestLayout() }

    private val density = resources.displayMetrics.density
    private var rows: List<List<Key>> = emptyList()
    private var rects: List<Pair<Key, RectF>> = emptyList()
    private var shift = ShiftState.OFF
    private var returnLabel: String? = null

    /** Pointer id → the key it is on. */
    private val active = mutableMapOf<Int, Pair<Key, RectF>>()
    private val handler = Handler(Looper.getMainLooper())
    private var longPressRunnable: Runnable? = null

    private val keyPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }

    private val hGap get() = 6 * density
    private val vGap get() = 10 * density
    private val sidePadding get() = 3 * density
    private val topPadding get() = 6 * density
    private val radius get() = 6 * density

    fun load(page: List<List<Key>>) {
        rows = page
        cancelAll()
        layoutKeys()
        requestLayout()
        invalidate()
    }

    fun setShift(state: ShiftState) {
        shift = state
        invalidate()
    }

    fun setReturnLabel(label: String?) {
        returnLabel = label
        invalidate()
    }

    val isUppercase: Boolean get() = shift != ShiftState.OFF

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val rowHeight = keyHeightDp * density
        val height = topPadding + rows.size * rowHeight + (rows.size) * vGap
        setMeasuredDimension(width, height.toInt())
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        layoutKeys()
    }

    private fun layoutKeys() {
        if (width == 0) return
        val rowHeight = keyHeightDp * density
        val result = mutableListOf<Pair<Key, RectF>>()
        rows.forEachIndexed { index, row ->
            val units = row.sumOf { it.width.toDouble() }.toFloat()
            val unit = (width - 2 * sidePadding) / units
            var x = sidePadding
            val top = topPadding + index * (rowHeight + vGap)
            for (key in row) {
                val w = key.width * unit
                if (key !is Key.Gap) {
                    result += key to RectF(x + hGap / 2, top, x + w - hGap / 2, top + rowHeight)
                }
                x += w
            }
        }
        rects = result
    }

    override fun onDraw(canvas: Canvas) {
        canvas.drawColor(colors.background)
        val pressed = active.values.map { it.first }.toSet()
        for ((key, rect) in rects) {
            val special = key !is Key.Character && key !is Key.Space
            val isPressed = key in pressed || (key is Key.Shift && shift != ShiftState.OFF)
            keyPaint.color = colors.shadow
            canvas.drawRoundRect(rect.left, rect.top + density, rect.right, rect.bottom + density, radius, radius, keyPaint)
            keyPaint.color = when {
                special && isPressed -> colors.specialKeyPressed
                special -> colors.specialKey
                isPressed -> colors.keyPressed
                else -> colors.key
            }
            canvas.drawRoundRect(rect, radius, radius, keyPaint)
            drawLabel(canvas, key, rect)
        }
    }

    private fun drawLabel(canvas: Canvas, key: Key, rect: RectF) {
        val (text, sizeSp, bold) = when (key) {
            is Key.Character -> Triple(if (isUppercase) key.text.uppercase() else key.text, 23f, false)
            is Key.Shift -> Triple(if (shift == ShiftState.LOCKED) "⇪" else "⇧", 22f, shift != ShiftState.OFF)
            is Key.Delete -> Triple("⌫", 20f, false)
            is Key.Mode -> Triple(key.label, 16f, false)
            is Key.Space -> Triple("space", 15f, false)
            is Key.Return -> Triple(returnLabel ?: "⏎", if (returnLabel == null) 20f else 15f, false)
            is Key.SwitchKeyboard -> Triple("🌐", 18f, false)
            is Key.Gap -> return
        }
        labelPaint.color = colors.label
        labelPaint.textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sizeSp, resources.displayMetrics)
        labelPaint.typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        val y = rect.centerY() - (labelPaint.descent() + labelPaint.ascent()) / 2
        canvas.drawText(text, rect.centerX(), y, labelPaint)
    }

    private fun keyAt(x: Float, y: Float): Pair<Key, RectF>? {
        rects.firstOrNull { it.second.contains(x, y) }?.let { return it }
        // Between keys: take the nearest one in reach, so gaps don't swallow taps.
        val reach = hGap.coerceAtLeast(vGap)
        return rects
            .filter { (_, r) -> x >= r.left - reach && x <= r.right + reach && y >= r.top - reach && y <= r.bottom + reach }
            .minByOrNull { (_, r) -> (r.centerX() - x) * (r.centerX() - x) + (r.centerY() - y) * (r.centerY() - y) }
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val index = event.actionIndex
                val hit = keyAt(event.getX(index), event.getY(index)) ?: return true
                // A new finger commits the key under the previous one first (rollover).
                for ((id, entry) in active.toMap()) {
                    if (entry.first is Key.Character || entry.first is Key.Space) {
                        active.remove(id)
                        listener?.onKeyReleased(entry.first)
                    }
                }
                active[event.getPointerId(index)] = hit
                performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                listener?.onKeyPressed(hit.first)
                if (hit.first is Key.SwitchKeyboard) scheduleLongPress()
                invalidate()
            }
            MotionEvent.ACTION_MOVE -> {
                var changed = false
                for (i in 0 until event.pointerCount) {
                    val id = event.getPointerId(i)
                    val current = active[id] ?: continue
                    if (current.first !is Key.Character) continue
                    val hit = keyAt(event.getX(i), event.getY(i)) ?: continue
                    if (hit.first is Key.Character && hit.first != current.first) {
                        active[id] = hit
                        changed = true
                    }
                }
                if (changed) invalidate()
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                val id = event.getPointerId(event.actionIndex)
                cancelSwitchLongPress()
                active.remove(id)?.let { listener?.onKeyReleased(it.first) }
                invalidate()
            }
            MotionEvent.ACTION_CANCEL -> cancelAll()
        }
        return true
    }

    private fun scheduleLongPress() {
        cancelSwitchLongPress()
        longPressRunnable = Runnable {
            // Consumed: the release must not also switch to the next keyboard.
            active.entries.removeAll { it.value.first is Key.SwitchKeyboard }
            listener?.onSwitchKeyboardLongPress()
            invalidate()
        }.also { handler.postDelayed(it, 450) }
    }

    private fun cancelSwitchLongPress() {
        longPressRunnable?.let { handler.removeCallbacks(it) }
        longPressRunnable = null
    }

    private fun cancelAll() {
        cancelSwitchLongPress()
        if (active.values.any { it.first is Key.Delete }) {
            listener?.onKeyReleased(Key.Delete())
        }
        active.clear()
        invalidate()
    }

    /** Total height for a given key height, so the service can size itself. */
    fun preferredHeight(): Int = (topPadding + rows.size * (keyHeightDp * density + vGap)).toInt()
}
