import Foundation

// Plain Foundation on purpose: this file is also compiled into RunnerTests,
// where the capture and replace rules are unit-tested against a fake document.

/// What the keyboard can see of the text field and do to it. Matches the
/// parts of UITextDocumentProxy the Correct flow uses.
protocol TextDocument: AnyObject {
  var documentContextBeforeInput: String? { get }
  var documentContextAfterInput: String? { get }
  var selectedText: String? { get }
  func insertText(_ text: String)
  func deleteBackward()
  func adjustTextPosition(byCharacterOffset offset: Int)
}

/// The text Correct works on, captured when the button is tapped.
struct CapturedText: Equatable {
  enum Scope: Equatable { case selection, surroundingText }

  let scope: Scope
  let before: String
  let after: String
  let selected: String

  /// Exactly what the keyboard read (selection, or text before + after the cursor).
  var full: String { scope == .selection ? selected : before + after }

  /// `full` without leading/trailing whitespace: what is sent for correction.
  var core: String { full.trimmingCharacters(in: .whitespacesAndNewlines) }

  /// Puts the original leading/trailing whitespace back around a correction.
  func restoringWhitespace(_ corrected: String) -> String {
    let leading = full.prefix { $0.isWhitespace || $0.isNewline }
    let trailing = String(full.reversed().prefix { $0.isWhitespace || $0.isNewline }.reversed())
    let body = corrected.trimmingCharacters(in: .whitespacesAndNewlines)
    return leading + body + trailing
  }

  /// iOS shows a keyboard only a window of text around the cursor. When that
  /// window is long, the message most likely continues beyond it.
  var mayBeCutOff: Bool {
    scope == .surroundingText && before.count + after.count >= TextCapture.cutOffSuspectLength
  }
}

enum TextCapture {
  /// Characters around the cursor at which the visible window probably ended
  /// before the message did. Tuned from the device spike (BONKILINGO_ROADMAP.md).
  static var cutOffSuspectLength = 180

  /// Selection first; otherwise everything visible around the cursor.
  /// nil when there is nothing to correct.
  static func capture(from document: TextDocument) -> CapturedText? {
    let before = document.documentContextBeforeInput ?? ""
    let after = document.documentContextAfterInput ?? ""
    let selected = document.selectedText ?? ""

    if !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return CapturedText(scope: .selection, before: before, after: after, selected: selected)
    }
    let captured = CapturedText(scope: .surroundingText, before: before, after: after, selected: "")
    return captured.core.isEmpty ? nil : captured
  }
}

/// One step sent to the text field, in order.
enum TextEdit: Equatable {
  /// Moves the cursor; the offset is in UTF-16 units, like UIKit text positions.
  case moveCursor(Int)
  /// Deletes this many characters before the cursor, one deleteBackward() each.
  case deleteBackward(Int)
  case insert(String)
}

enum Replacement {
  /// The edits that turn the captured text into `corrected`.
  ///
  /// Only the part that differs is rewritten: the shared beginning and end
  /// stay untouched, which keeps the edit small (fewer deleteBackward calls
  /// for host apps to get wrong). For surrounding text the cursor ends where
  /// it was relative to the end of the text.
  static func edits(for captured: CapturedText, corrected rawCorrected: String) -> [TextEdit] {
    let corrected = captured.restoringWhitespace(rawCorrected)
    if captured.scope == .selection {
      // Typing over a selection replaces it.
      return corrected == captured.full ? [] : [.insert(corrected)]
    }

    let old = Array(captured.full)
    let new = Array(corrected)
    let maxShared = min(old.count, new.count)

    var prefix = 0
    while prefix < maxShared, old[prefix] == new[prefix] { prefix += 1 }
    var suffix = 0
    while suffix < maxShared - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }

    if prefix == old.count, prefix == new.count { return [] }

    let cursor = captured.before.count
    let changeEnd = old.count - suffix
    var edits: [TextEdit] = []

    // Put the cursor at the end of the changed part.
    if changeEnd > cursor {
      edits.append(.moveCursor(utf16Length(old[cursor..<changeEnd])))
    } else if changeEnd < cursor {
      edits.append(.moveCursor(-utf16Length(old[changeEnd..<cursor])))
    }
    let deleteCount = changeEnd - prefix
    if deleteCount > 0 { edits.append(.deleteBackward(deleteCount)) }
    let insertion = String(new[prefix..<(new.count - suffix)])
    if !insertion.isEmpty { edits.append(.insert(insertion)) }

    // Back to where the cursor was, measured from the end of the text.
    let cursorFromEnd = old.count - cursor
    if suffix > cursorFromEnd {
      edits.append(.moveCursor(utf16Length(old[changeEnd..<(old.count - cursorFromEnd)])))
    } else if suffix < cursorFromEnd {
      // The cursor sat inside the changed part: leave it after the insertion.
    }
    return edits
  }

  static func apply(_ edits: [TextEdit], to document: TextDocument) {
    for edit in edits {
      switch edit {
      case .moveCursor(let offset):
        document.adjustTextPosition(byCharacterOffset: offset)
      case .deleteBackward(let count):
        for _ in 0..<count { document.deleteBackward() }
      case .insert(let text):
        document.insertText(text)
      }
    }
  }

  private static func utf16Length(_ characters: ArraySlice<Character>) -> Int {
    characters.reduce(0) { $0 + $1.utf16.count }
  }
}

/// Word-level diff, to highlight what the correction changed.
enum WordDiff {
  struct Piece: Equatable {
    let text: String
    let changed: Bool
  }

  /// Splits `corrected` into words and the spaces between them, marking the
  /// words that are not in `original` at the same place in the sequence.
  static func highlight(original: String, corrected: String) -> [Piece] {
    let oldWords = words(in: original)
    let newTokens = tokens(in: corrected)
    let newWords = newTokens.filter { !$0.isWhitespace }.map(\.text)
    let kept = lcsMask(oldWords, newWords)

    var pieces: [Piece] = []
    var wordIndex = 0
    for token in newTokens {
      if token.isWhitespace {
        pieces.append(Piece(text: token.text, changed: false))
      } else {
        pieces.append(Piece(text: token.text, changed: !kept[wordIndex]))
        wordIndex += 1
      }
    }
    return pieces
  }

  private struct Token { let text: String; let isWhitespace: Bool }

  private static func tokens(in text: String) -> [Token] {
    var result: [Token] = []
    var current = ""
    var currentIsSpace = false
    for character in text {
      let isSpace = character.isWhitespace
      if !current.isEmpty, isSpace != currentIsSpace {
        result.append(Token(text: current, isWhitespace: currentIsSpace))
        current = ""
      }
      current.append(character)
      currentIsSpace = isSpace
    }
    if !current.isEmpty { result.append(Token(text: current, isWhitespace: currentIsSpace)) }
    return result
  }

  private static func words(in text: String) -> [String] {
    tokens(in: text).filter { !$0.isWhitespace }.map(\.text)
  }

  /// true for each word of `b` that is part of a longest common subsequence with `a`.
  private static func lcsMask(_ a: [String], _ b: [String]) -> [Bool] {
    guard !a.isEmpty, !b.isEmpty else { return Array(repeating: false, count: b.count) }
    var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
    for i in stride(from: a.count - 1, through: 0, by: -1) {
      for j in stride(from: b.count - 1, through: 0, by: -1) {
        table[i][j] = a[i] == b[j] ? table[i + 1][j + 1] + 1 : max(table[i + 1][j], table[i][j + 1])
      }
    }
    var mask = Array(repeating: false, count: b.count)
    var i = 0, j = 0
    while i < a.count, j < b.count {
      if a[i] == b[j] {
        mask[j] = true
        i += 1; j += 1
      } else if table[i + 1][j] >= table[i][j + 1] {
        i += 1
      } else {
        j += 1
      }
    }
    return mask
  }
}
