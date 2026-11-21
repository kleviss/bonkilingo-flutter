package com.bonkilingo.app.keyboard

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TextCaptureTest {
    @Test
    fun selectionWinsOverSurroundingText() {
        val captured = TextCapture.capture("Hi. ", " Bye", "i has a apple")!!
        assertEquals(CapturedText.Scope.SELECTION, captured.scope)
        assertEquals("i has a apple", captured.full)
    }

    @Test
    fun surroundingTextWhenNothingSelected() {
        val captured = TextCapture.capture("I has a ", "apple ", "")!!
        assertEquals(CapturedText.Scope.SURROUNDING_TEXT, captured.scope)
        assertEquals("I has a apple ", captured.full)
        assertEquals("I has a apple", captured.core)
    }

    @Test
    fun nothingToCorrect() {
        assertNull(TextCapture.capture("  ", "\n", null))
        assertNull(TextCapture.capture(null, null, "   "))
    }

    @Test
    fun restoresLeadingAndTrailingWhitespace() {
        val captured = TextCapture.capture("\n  i has", " a apple  ", null)!!
        assertEquals("\n  I have an apple.  ", captured.restoringWhitespace(" I have an apple. "))
    }
}

class ReplacementTest {
    private fun check(before: String, after: String, corrected: String, expectedText: String, expectedCursor: Int) {
        val captured = TextCapture.capture(before, after, null)!!
        val plan = Replacement.plan(captured, corrected)!!
        assertEquals(expectedText, Replacement.apply(plan, captured.full))
        assertEquals(expectedCursor, plan.cursor)
    }

    @Test
    fun onlyTheChangedPartIsRewritten() {
        val captured = TextCapture.capture("I has a apple", "", null)!!
        val plan = Replacement.plan(captured, "I have an apple.")!!
        // "I ha" is shared; the rest differs from "s" onwards except nothing at the end.
        assertEquals(4, plan.start)
        assertEquals("I have an apple.", Replacement.apply(plan, captured.full))
    }

    @Test
    fun cursorAtEndStaysAtEnd() = check("I has a apple", "", "I have an apple.", "I have an apple.", 16)

    @Test
    fun cursorAfterTheChangeKeepsItsPlaceFromTheEnd() =
        check("I has a apple and ", "a pear", "I have an apple and a pear", "I have an apple and a pear", 20)

    @Test
    fun cursorBeforeTheChangeStays() = check("", "I has a apple", "I have an apple", "I have an apple", 0)

    @Test
    fun cursorInsideTheChangeLandsAfterIt() =
        check("I has", " a apple", "I have an apple", "I have an apple", 9)

    @Test
    fun unchangedTextNeedsNoPlan() {
        val captured = TextCapture.capture("All good.", " ", null)!!
        assertNull(Replacement.plan(captured, "All good."))
    }

    @Test
    fun handlesEmojiAsUtf16() {
        check("😀 i has", "", "😀 I have", "😀 I have", 9)
    }
}

class WordDiffTest {
    @Test
    fun marksChangedWords() {
        val pieces = WordDiff.highlight("I has a apple", "I have an apple.")
        val changed = pieces.filter { it.changed }.map { it.text }
        assertEquals(listOf("have", "an", "apple."), changed)
        assertEquals("I have an apple.", pieces.joinToString("") { it.text })
    }

    @Test
    fun identicalTextHasNoChanges() {
        assertTrue(WordDiff.highlight("Hello there", "Hello there").none { it.changed })
    }
}

class HistoryQueueTest {
    @Test
    fun appendsEntriesInTheIosShape() {
        val json = HistoryQueue.append(null, "I has a apple", "I have an apple.", 1700000000000, "a")
        val entry = HistoryQueue.entries(json).single()
        assertEquals("a", entry["id"])
        assertEquals("I has a apple", entry["original"])
        assertEquals("I have an apple.", entry["corrected"])
        assertEquals(1700000000000L, (entry["timestamp"] as Number).toLong())
    }

    @Test
    fun skipsEmptyOrUnchangedCorrections() {
        assertNull(HistoryQueue.append(null, " ", "x", 1, "a"))
        assertNull(HistoryQueue.append(null, "same", "same", 1, "a"))
    }

    @Test
    fun dropsOldestBeyondTheCap() {
        var json: String? = null
        for (i in 1..HistoryQueue.MAX_ENTRIES + 5) json = HistoryQueue.append(json, "o$i", "c$i", i.toLong(), "id$i")
        val ids = HistoryQueue.entries(json).map { it["id"] }
        assertEquals(HistoryQueue.MAX_ENTRIES, ids.size)
        assertEquals("id6", ids.first())
    }

    @Test
    fun truncatesLongTexts() {
        val json = HistoryQueue.append(null, "a".repeat(3000), "b".repeat(3000), 1, "x")
        assertEquals(HistoryQueue.MAX_TEXT_LENGTH, (HistoryQueue.entries(json).single()["original"] as String).length)
    }

    @Test
    fun removesAcknowledgedAndIdlessEntries() {
        var json = HistoryQueue.append(null, "o1", "c1", 1, "a")
        json = HistoryQueue.append(json, "o2", "c2", 2, "b")
        val withBroken = JSONArray(json).put(org.json.JSONObject().put("original", "x")).toString()
        val left = HistoryQueue.entries(HistoryQueue.remove(withBroken, setOf("a")))
        assertEquals(listOf("b"), left.map { it["id"] })
    }

    @Test
    fun survivesCorruptJson() {
        assertTrue(HistoryQueue.entries("not json").isEmpty())
        assertFalse(HistoryQueue.append("not json", "o", "c", 1, "a").isNullOrEmpty())
    }
}
