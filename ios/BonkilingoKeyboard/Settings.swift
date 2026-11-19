import Foundation

/// Settings the Bonkilingo app writes for the keyboard
/// (lib/data/data_sources/local/keyboard_settings.dart and
/// ios/Runner/AppDelegate.swift). Read-only here: writing to the App Group
/// container needs Full Access.
///
/// Until both targets carry the App Group entitlement (roadmap Phase 3),
/// iOS gives the keyboard its own copy of this suite, so these read as their
/// defaults.
enum SharedSettings {
  static let appGroup = "group.com.bonkilingo.app"
  static let correctionsEnabledKey = "keyboard.correctionsEnabled"

  static var correctionsEnabled: Bool {
    UserDefaults(suiteName: appGroup)?.object(forKey: correctionsEnabledKey) as? Bool ?? true
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
