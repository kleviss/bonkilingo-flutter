import UIKit

enum KeyboardMode {
  case letters, numbers, symbols
}

/// Letter arrangement for the letters page. German is the default because
/// Bonkilingo's first audience writes German.
enum LetterLayout: String, CaseIterable {
  case german = "de"
  case english = "en"

  var label: String { rawValue.uppercased() }

  var toggled: LetterLayout { self == .german ? .english : .german }
}

enum Key: Equatable {
  case character(String)
  case shift
  case delete
  case space
  case returnKey
  case globe
  /// Switches to another page: "123", "#+=" or "ABC".
  case mode(KeyboardMode)

  var isSpecial: Bool {
    if case .character = self { return false }
    return self != .space
  }
}

struct KeySpec {
  let key: Key
  /// Width in key units (one letter key = 1). nil fills the space left in the row.
  let units: CGFloat?

  init(_ key: Key, _ units: CGFloat? = 1) {
    self.key = key
    self.units = units
  }
}

struct KeyRow {
  let keys: [KeySpec]
  /// Pins the first and last key to the edges and centers the rest
  /// (the shift/delete row).
  var pinsEdges = false
}

struct KeyboardPage {
  let rows: [KeyRow]
  /// Letter keys across the widest row; sets the key unit width.
  let columns: CGFloat
}

enum KeyboardLayouts {
  static func page(mode: KeyboardMode, letters: LetterLayout, showsGlobe: Bool) -> KeyboardPage {
    let bottom = bottomRow(mode: mode, showsGlobe: showsGlobe)
    switch mode {
    case .letters:
      switch letters {
      case .german:
        return KeyboardPage(rows: [
          KeyRow(keys: chars("qwertzuiopü")),
          KeyRow(keys: chars("asdfghjklöä")),
          KeyRow(keys: [KeySpec(.shift, 1.4)] + chars("yxcvbnm") + [KeySpec(.delete, 1.4)], pinsEdges: true),
          bottom,
        ], columns: 11)
      case .english:
        return KeyboardPage(rows: [
          KeyRow(keys: chars("qwertyuiop")),
          KeyRow(keys: chars("asdfghjkl")),
          KeyRow(keys: [KeySpec(.shift, 1.4)] + chars("zxcvbnm") + [KeySpec(.delete, 1.4)], pinsEdges: true),
          bottom,
        ], columns: 10)
      }
    case .numbers:
      let currency = letters == .german ? "€" : "$"
      return KeyboardPage(rows: [
        KeyRow(keys: chars("1234567890")),
        KeyRow(keys: chars("-/:;()\(currency)&@\"")),
        KeyRow(keys: [KeySpec(.mode(.symbols), 1.4)] + chars(".,?!'", units: 1.4) + [KeySpec(.delete, 1.4)], pinsEdges: true),
        bottom,
      ], columns: 10)
    case .symbols:
      return KeyboardPage(rows: [
        KeyRow(keys: chars("[]{}#%^*+=")),
        KeyRow(keys: chars("_\\|~<>$£¥•")),
        KeyRow(keys: [KeySpec(.mode(.numbers), 1.4)] + chars(".,?!'", units: 1.4) + [KeySpec(.delete, 1.4)], pinsEdges: true),
        bottom,
      ], columns: 10)
    }
  }

  /// Variants shown when a letter is held down.
  static func alternates(for character: String) -> [String] {
    switch character.lowercased() {
    case "a": return ["ä", "à", "á", "â", "æ"]
    case "e": return ["é", "è", "ê", "ë"]
    case "i": return ["í", "ì", "î", "ï"]
    case "o": return ["ö", "ó", "ò", "ô", "œ"]
    case "u": return ["ü", "ú", "ù", "û"]
    case "s": return ["ß"]
    case "c": return ["ç"]
    case "n": return ["ñ"]
    case "y": return ["ÿ"]
    case "-": return ["–", "—"]
    case "\"": return ["„", "“", "”"]
    case "'": return ["‚", "‘", "’"]
    case "€", "$": return ["€", "$", "£", "¥"]
    default: return []
    }
  }

  private static func bottomRow(mode: KeyboardMode, showsGlobe: Bool) -> KeyRow {
    let modeKey = KeySpec(.mode(mode == .letters ? .numbers : .letters), 1.4)
    var keys = [modeKey]
    if showsGlobe { keys.append(KeySpec(.globe, 1.2)) }
    keys += [KeySpec(.space, nil), KeySpec(.returnKey, 2.4)]
    return KeyRow(keys: keys)
  }

  private static func chars(_ string: String, units: CGFloat = 1) -> [KeySpec] {
    string.map { KeySpec(.character(String($0)), units) }
  }
}
