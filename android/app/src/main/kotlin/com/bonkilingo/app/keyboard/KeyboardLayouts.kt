package com.bonkilingo.app.keyboard

/** One key on the keyboard. [width] is relative to a letter key (1.0). */
sealed class Key(open val width: Float) {
    data class Character(val text: String, override val width: Float = 1f) : Key(width)
    data class Shift(override val width: Float = 1.5f) : Key(width)
    data class Delete(override val width: Float = 1.5f) : Key(width)
    data class Mode(val target: KeyboardMode, val label: String, override val width: Float = 1.25f) : Key(width)
    data class Space(override val width: Float = 4.5f) : Key(width)
    data class Return(override val width: Float = 1.75f) : Key(width)
    data class SwitchKeyboard(override val width: Float = 1f) : Key(width)
    /** Empty room, to indent a row. */
    data class Gap(override val width: Float) : Key(width)
}

enum class KeyboardMode { LETTERS, NUMBERS, SYMBOLS }

/** The German (QWERTZ, with umlauts) and English (QWERTY) letter layouts, like the iOS keyboard. */
enum class LetterLayout(val code: String, val label: String) {
    GERMAN("de", "DE"),
    ENGLISH("en", "EN");

    val toggled: LetterLayout get() = if (this == GERMAN) ENGLISH else GERMAN

    companion object {
        fun of(code: String): LetterLayout = entries.firstOrNull { it.code == code } ?: ENGLISH
    }
}

object KeyboardLayouts {
    fun page(mode: KeyboardMode, letters: LetterLayout, showsSwitchKey: Boolean): List<List<Key>> {
        val rows = when (mode) {
            KeyboardMode.LETTERS -> letterRows(letters)
            KeyboardMode.NUMBERS -> listOf(
                chars("1234567890"),
                chars("-/:;()€&@\""),
                listOf(Key.Mode(KeyboardMode.SYMBOLS, "#+=", 1.5f)) + chars(".,?!'", 1.4f) + Key.Delete(),
            )
            KeyboardMode.SYMBOLS -> listOf(
                chars("[]{}#%^*+="),
                chars("_\\|~<>$£¥•"),
                listOf(Key.Mode(KeyboardMode.NUMBERS, "123", 1.5f)) + chars(".,?!'", 1.4f) + Key.Delete(),
            )
        }
        return rows + listOf(bottomRow(mode, showsSwitchKey))
    }

    private fun letterRows(layout: LetterLayout): List<List<Key>> = when (layout) {
        LetterLayout.ENGLISH -> listOf(
            chars("qwertyuiop"),
            listOf(Key.Gap(0.5f)) + chars("asdfghjkl") + Key.Gap(0.5f),
            listOf(Key.Shift()) + chars("zxcvbnm") + Key.Delete(),
        )
        LetterLayout.GERMAN -> listOf(
            chars("qwertzuiopü"),
            chars("asdfghjklöä"),
            listOf(Key.Shift(2f)) + chars("yxcvbnm") + Key.Delete(2f),
        )
    }

    private fun bottomRow(mode: KeyboardMode, showsSwitchKey: Boolean): List<Key> {
        val modeKey = if (mode == KeyboardMode.LETTERS) {
            Key.Mode(KeyboardMode.NUMBERS, "123")
        } else {
            Key.Mode(KeyboardMode.LETTERS, "ABC")
        }
        return listOfNotNull(
            modeKey,
            if (showsSwitchKey) Key.SwitchKeyboard() else null,
            Key.Character(","),
            Key.Space(if (showsSwitchKey) 4f else 5f),
            Key.Character("."),
            Key.Return(),
        )
    }

    private fun chars(letters: String, width: Float = 1f): List<Key> =
        letters.map { Key.Character(it.toString(), width) }
}
