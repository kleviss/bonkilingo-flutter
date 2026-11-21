package com.bonkilingo.app.keyboard

// Plain Kotlin on purpose: unit-tested in android/app/src/test (the same
// capture and replace rules as ios/BonkilingoKeyboard/TextEditing.swift).

/** The text Correct works on, captured when the button is tapped. */
data class CapturedText(
    val scope: Scope,
    val before: String,
    val after: String,
    val selected: String,
) {
    enum class Scope { SELECTION, SURROUNDING_TEXT }

    /** Exactly what the keyboard read (selection, or text before + after the cursor). */
    val full: String get() = if (scope == Scope.SELECTION) selected else before + after

    /** [full] without leading/trailing whitespace: what is sent for correction. */
    val core: String get() = full.trim()

    /** Puts the original leading/trailing whitespace back around a correction. */
    fun restoringWhitespace(corrected: String): String {
        val leading = full.takeWhile { it.isWhitespace() }
        val trailing = full.takeLastWhile { it.isWhitespace() }
        if (leading.length == full.length) return corrected.trim()
        return leading + corrected.trim() + trailing
    }

    /** The field shows the keyboard at most [TextCapture.WINDOW] characters each side. */
    val mayBeCutOff: Boolean
        get() = scope == Scope.SURROUNDING_TEXT &&
            (before.length >= TextCapture.WINDOW || after.length >= TextCapture.WINDOW)
}

object TextCapture {
    /** Characters read on each side of the cursor. */
    const val WINDOW = 2000

    /** Selection first; otherwise the text around the cursor. Null when there is nothing to correct. */
    fun capture(before: CharSequence?, after: CharSequence?, selected: CharSequence?): CapturedText? {
        val b = before?.toString() ?: ""
        val a = after?.toString() ?: ""
        val s = selected?.toString() ?: ""
        if (s.isNotBlank()) return CapturedText(CapturedText.Scope.SELECTION, b, a, s)
        val captured = CapturedText(CapturedText.Scope.SURROUNDING_TEXT, b, a, "")
        return if (captured.core.isEmpty()) null else captured
    }
}

/**
 * How to turn the captured text into the correction: replace [start, end)
 * with [insertion], then put the cursor at [cursor]. Offsets are UTF-16
 * units from the start of the captured window (where `before` begins), like
 * Android text offsets.
 */
data class ReplacementPlan(val start: Int, val end: Int, val insertion: String, val cursor: Int)

object Replacement {
    /**
     * Only the part that differs is rewritten: the shared beginning and end
     * stay untouched. The cursor keeps its place relative to the end of the
     * text, or lands after the insertion if it was inside the changed part.
     * Null when nothing changes. Selections are replaced by the caller.
     */
    fun plan(captured: CapturedText, rawCorrected: String): ReplacementPlan? {
        val corrected = captured.restoringWhitespace(rawCorrected)
        val old = captured.full
        if (corrected == old) return null

        val maxShared = minOf(old.length, corrected.length)
        var prefix = 0
        while (prefix < maxShared && old[prefix] == corrected[prefix]) prefix++
        var suffix = 0
        while (suffix < maxShared - prefix &&
            old[old.length - 1 - suffix] == corrected[corrected.length - 1 - suffix]
        ) suffix++

        val changeEnd = old.length - suffix
        val insertion = corrected.substring(prefix, corrected.length - suffix)
        val cursor = captured.before.length
        val newCursor = when {
            cursor >= changeEnd -> cursor + (insertion.length - (changeEnd - prefix))
            cursor <= prefix -> cursor
            else -> prefix + insertion.length
        }
        return ReplacementPlan(prefix, changeEnd, insertion, newCursor)
    }

    /** Applies a plan to a plain string (what the field should contain afterwards). */
    fun apply(plan: ReplacementPlan, text: String): String =
        text.substring(0, plan.start) + plan.insertion + text.substring(plan.end)
}

/** Word-level diff, to highlight what the correction changed. */
object WordDiff {
    data class Piece(val text: String, val changed: Boolean)

    /** Splits [corrected] into words and spaces, marking words that aren't kept from [original]. */
    fun highlight(original: String, corrected: String): List<Piece> {
        val oldWords = tokens(original).filter { !it.second }.map { it.first }
        val newTokens = tokens(corrected)
        val newWords = newTokens.filter { !it.second }.map { it.first }
        val kept = lcsMask(oldWords, newWords)

        var wordIndex = 0
        return newTokens.map { (text, isSpace) ->
            if (isSpace) Piece(text, false) else Piece(text, !kept[wordIndex++])
        }
    }

    private fun tokens(text: String): List<Pair<String, Boolean>> {
        val result = mutableListOf<Pair<String, Boolean>>()
        val current = StringBuilder()
        var currentIsSpace = false
        for (c in text) {
            val isSpace = c.isWhitespace()
            if (current.isNotEmpty() && isSpace != currentIsSpace) {
                result += current.toString() to currentIsSpace
                current.clear()
            }
            current.append(c)
            currentIsSpace = isSpace
        }
        if (current.isNotEmpty()) result += current.toString() to currentIsSpace
        return result
    }

    /** True for each word of [b] that is part of a longest common subsequence with [a]. */
    private fun lcsMask(a: List<String>, b: List<String>): BooleanArray {
        val mask = BooleanArray(b.size)
        if (a.isEmpty() || b.isEmpty() || a.size * b.size > 250_000) return mask
        val table = Array(a.size + 1) { IntArray(b.size + 1) }
        for (i in a.indices.reversed()) {
            for (j in b.indices.reversed()) {
                table[i][j] = if (a[i] == b[j]) table[i + 1][j + 1] + 1
                else maxOf(table[i + 1][j], table[i][j + 1])
            }
        }
        var i = 0
        var j = 0
        while (i < a.size && j < b.size) {
            when {
                a[i] == b[j] -> { mask[j] = true; i++; j++ }
                table[i + 1][j] >= table[i][j + 1] -> i++
                else -> j++
            }
        }
        return mask
    }
}
