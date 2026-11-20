import Foundation

/// Settings the Bonkilingo app writes for the keyboard
/// (lib/data/data_sources/local/keyboard_settings.dart and
/// ios/Runner/AppDelegate.swift). Read-only here: writing to the App Group
/// container needs Full Access.
///
/// Both targets carry the App Group entitlement (Runner.entitlements and
/// BonkilingoKeyboard.entitlements), so this suite is shared between them.
enum SharedSettings {
  static let appGroup = "group.com.bonkilingo.app"
  static let correctionsEnabledKey = "keyboard.correctionsEnabled"
  static let saveToHistoryKey = "keyboard.saveToHistory"

  static var correctionsEnabled: Bool {
    UserDefaults(suiteName: appGroup)?.object(forKey: correctionsEnabledKey) as? Bool ?? true
  }

  /// Whether corrections are kept for the app's History. On by default; the
  /// app's Settings has the switch.
  static var saveToHistory: Bool {
    UserDefaults(suiteName: appGroup)?.object(forKey: saveToHistoryKey) as? Bool ?? true
  }
}

/// Corrections made with the keyboard, waiting in the App Group for the app
/// to add them to History (ios/Runner/AppDelegate.swift drains it,
/// lib/data/data_sources/local/keyboard_history_queue.dart parses it).
///
/// Local only: nothing extra is sent anywhere. Writing needs Full Access,
/// which Correct needs anyway.
enum KeyboardHistoryQueue {
  static let key = "keyboard.historyQueue"
  /// Oldest entries are dropped beyond this, so an app that is never opened
  /// doesn't grow the queue without bound.
  static let maxEntries = 50
  static let maxTextLength = 2000

  static func append(original: String, corrected: String, date: Date = Date(),
                     defaults: UserDefaults? = UserDefaults(suiteName: SharedSettings.appGroup)) {
    guard let defaults else { return }
    let original = String(original.prefix(maxTextLength))
    let corrected = String(corrected.prefix(maxTextLength))
    guard !original.isEmpty, !corrected.isEmpty, original != corrected else { return }

    var queue = defaults.array(forKey: key) as? [[String: Any]] ?? []
    queue.append([
      "id": UUID().uuidString,
      "original": original,
      "corrected": corrected,
      "timestamp": Int(date.timeIntervalSince1970 * 1000),
    ])
    if queue.count > maxEntries { queue.removeFirst(queue.count - maxEntries) }
    defaults.set(queue, forKey: key)
  }
}

/// The keyboard's own preferences, kept in its own container (writable
/// without Full Access).
enum KeyboardPreferences {
  private static let defaults = UserDefaults.standard
  private static let letterLayoutKey = "letterLayout"
  private static let showsContextReadoutKey = "showsContextReadout"

  static var letterLayout: LetterLayout {
    get { defaults.string(forKey: letterLayoutKey).flatMap(LetterLayout.init(rawValue:)) ?? .german }
    set { defaults.set(newValue.rawValue, forKey: letterLayoutKey) }
  }

  /// Shows how much text the keyboard can read around the cursor (counts
  /// only, never the text). Toggled by long-pressing "Bonkilingo"; used to
  /// measure what each host app exposes (roadmap Phase 1 spike).
  static var showsContextReadout: Bool {
    get { defaults.bool(forKey: showsContextReadoutKey) }
    set { defaults.set(newValue, forKey: showsContextReadoutKey) }
  }
}
