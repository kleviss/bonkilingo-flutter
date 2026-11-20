import XCTest

// Tests for ios/BonkilingoKeyboard/TextEditing.swift (compiled into this
// target directly; the keyboard extension itself can't host tests).

/// A text field as a keyboard sees it: cursor moves in UTF-16 units like
/// UIKit text positions, deleteBackward removes one character (grapheme).
private final class FakeDocument: TextDocument {
  var text: String
  private var cursor: Int // in Characters
  private var selection: Range<Int>? // in Characters

  init(_ text: String, cursor: Int? = nil, selecting selected: String? = nil) {
    self.text = text
    self.cursor = cursor ?? text.count
    if let selected, let range = text.range(of: selected) {
      let lower = text.distance(from: text.startIndex, to: range.lowerBound)
      selection = lower..<(lower + selected.count)
      self.cursor = lower + selected.count
    }
  }

  private func index(_ offset: Int) -> String.Index { text.index(text.startIndex, offsetBy: offset) }

  var cursorPosition: Int { cursor }

  var documentContextBeforeInput: String? {
    String(text[..<index(selection?.lowerBound ?? cursor)])
  }

  var documentContextAfterInput: String? {
    String(text[index(selection?.upperBound ?? cursor)...])
  }

  var selectedText: String? {
    selection.map { String(text[index($0.lowerBound)..<index($0.upperBound)]) }
  }

  func insertText(_ inserted: String) {
    if let selection {
      text.replaceSubrange(index(selection.lowerBound)..<index(selection.upperBound), with: inserted)
      cursor = selection.lowerBound + inserted.count
      self.selection = nil
    } else {
      text.insert(contentsOf: inserted, at: index(cursor))
      cursor += inserted.count
    }
  }

  func deleteBackward() {
    if let selection {
      text.removeSubrange(index(selection.lowerBound)..<index(selection.upperBound))
      cursor = selection.lowerBound
      self.selection = nil
      return
    }
    guard cursor > 0 else { return }
    text.remove(at: index(cursor - 1))
    cursor -= 1
  }

  func adjustTextPosition(byCharacterOffset offset: Int) {
    selection = nil
    let utf16Cursor = text.utf16.distance(from: text.startIndex, to: index(cursor)) + offset
    let target = String.Index(utf16Offset: utf16Cursor, in: text)
    cursor = text.distance(from: text.startIndex, to: target)
  }
}

final class KeyboardTextEditingTests: XCTestCase {
  private func correct(_ document: FakeDocument, to corrected: String,
                       file: StaticString = #filePath, line: UInt = #line) {
    guard let captured = TextCapture.capture(from: document) else {
      return XCTFail("nothing captured", file: file, line: line)
    }
    Replacement.apply(Replacement.edits(for: captured, corrected: corrected), to: document)
  }

  // MARK: Capture

  func testCapturePrefersSelection() throws {
    let doc = FakeDocument("Hello. me go home. Bye.", selecting: "me go home.")
    let captured = try XCTUnwrap(TextCapture.capture(from: doc))
    XCTAssertEqual(captured.scope, .selection)
    XCTAssertEqual(captured.core, "me go home.")
  }

  func testCaptureUsesTextAroundCursorWithoutSelection() throws {
    let doc = FakeDocument("I has a cat. It are nice.", cursor: 12)
    let captured = try XCTUnwrap(TextCapture.capture(from: doc))
    XCTAssertEqual(captured.scope, .surroundingText)
    XCTAssertEqual(captured.core, "I has a cat. It are nice.")
  }

  func testCaptureIgnoresEmptyOrWhitespaceOnlyText() {
    XCTAssertNil(TextCapture.capture(from: FakeDocument("")))
    XCTAssertNil(TextCapture.capture(from: FakeDocument("   \n ")))
  }

  func testLongVisibleTextMayBeCutOff() throws {
    let short = try XCTUnwrap(TextCapture.capture(from: FakeDocument("Kurzer Satz.")))
    XCTAssertFalse(short.mayBeCutOff)
    let long = try XCTUnwrap(TextCapture.capture(from: FakeDocument(String(repeating: "Wort ", count: 40))))
    XCTAssertTrue(long.mayBeCutOff)
  }

  // MARK: Replace

  func testReplacesWholeMessageWithCursorAtEnd() {
    let doc = FakeDocument("Ich habe gestern nach Berlin gefahren")
    correct(doc, to: "Ich bin gestern nach Berlin gefahren.")
    XCTAssertEqual(doc.text, "Ich bin gestern nach Berlin gefahren.")
    XCTAssertEqual(doc.cursorPosition, doc.text.count)
  }

  func testOnlyRewritesTheChangedPart() throws {
    let doc = FakeDocument("Ich habe gestern nach Berlin gefahren")
    let captured = try XCTUnwrap(TextCapture.capture(from: doc))
    let edits = Replacement.edits(for: captured, corrected: "Ich bin gestern nach Berlin gefahren")
    // Only "habe" changes, so only a few characters are deleted, not all 37.
    let deleted = edits.reduce(0) { total, edit in
      if case .deleteBackward(let n) = edit { return total + n }
      return total
    }
    XCTAssertLessThan(deleted, 6)
    Replacement.apply(edits, to: doc)
    XCTAssertEqual(doc.text, "Ich bin gestern nach Berlin gefahren")
    XCTAssertEqual(doc.cursorPosition, doc.text.count)
  }

  func testReplacesWithCursorInTheMiddle() {
    let doc = FakeDocument("I has a cat. It are nice.", cursor: 12)
    correct(doc, to: "I have a cat. It is nice.")
    XCTAssertEqual(doc.text, "I have a cat. It is nice.")
  }

  func testKeepsLeadingAndTrailingWhitespace() {
    let doc = FakeDocument("hallo welt ")
    correct(doc, to: "Hallo Welt.")
    XCTAssertEqual(doc.text, "Hallo Welt. ")
  }

  func testHandlesUmlautsAndEmoji() {
    let doc = FakeDocument("Schöne Grüse 👋🏽 an alle", cursor: 13)
    correct(doc, to: "Schöne Grüße 👋🏽 an alle!")
    XCTAssertEqual(doc.text, "Schöne Grüße 👋🏽 an alle!")
  }

  func testReplacesSelectionOnly() {
    let doc = FakeDocument("Hello. me go home. Bye.", selecting: "me go home.")
    correct(doc, to: "I am going home.")
    XCTAssertEqual(doc.text, "Hello. I am going home. Bye.")
  }

  func testNoEditsWhenNothingChanged() throws {
    let doc = FakeDocument("Alles gut.")
    let captured = try XCTUnwrap(TextCapture.capture(from: doc))
    XCTAssertEqual(Replacement.edits(for: captured, corrected: "Alles gut."), [])
  }

  // MARK: Highlight

  func testHighlightsChangedWords() {
    let pieces = WordDiff.highlight(original: "Ich habe gestern gefahren", corrected: "Ich bin gestern gefahren.")
    let changed = pieces.filter(\.changed).map(\.text)
    XCTAssertEqual(changed, ["bin", "gefahren."])
    XCTAssertEqual(pieces.map(\.text).joined(), "Ich bin gestern gefahren.")
  }
}
