import Flutter
import NaturalLanguage
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerKeyboardSettingsChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Settings for the Bonkilingo keyboard extension, read and written from
  /// Flutter (lib/data/data_sources/local/keyboard_settings.dart).
  ///
  /// They live in the App Group's defaults so the keyboard, which runs in its
  /// own process, can read them (both targets carry the App Group
  /// entitlement). The keyboard also leaves its corrections there for History
  /// (`readHistoryQueue`, `removeHistoryEntries`).
  private func registerKeyboardSettingsChannel() {
    guard let registrar = registrar(forPlugin: "KeyboardSettingsChannel") else { return }
    let channel = FlutterMethodChannel(
      name: "com.bonkilingo.app/keyboard_settings",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(suiteName: "group.com.bonkilingo.shared") else {
        result(FlutterError(code: "unavailable", message: "App Group defaults unavailable", details: nil))
        return
      }
      switch call.method {
      case "readHistoryQueue":
        result(Self.readHistoryQueue(defaults))
        return
      case "removeHistoryEntries":
        let ids = (call.arguments as? [String: Any])?["ids"] as? [String] ?? []
        Self.removeHistoryEntries(Set(ids), from: defaults)
        result(nil)
        return
      default:
        break
      }
      guard let args = call.arguments as? [String: Any], let key = args["key"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing key", details: nil))
        return
      }
      switch call.method {
      case "getBool":
        let fallback = args["defaultValue"] as? Bool ?? false
        result(defaults.object(forKey: key) as? Bool ?? fallback)
      case "setBool":
        guard let value = args["value"] as? Bool else {
          result(FlutterError(code: "bad_args", message: "Missing value", details: nil))
          return
        }
        defaults.set(value, forKey: key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static let historyQueueKey = "keyboard.historyQueue"

  /// The corrections the keyboard queued (ios/BonkilingoKeyboard/
  /// Settings.swift, KeyboardHistoryQueue). Each entry gets the corrected
  /// text's language as an ISO code, detected on device, since the keyboard
  /// doesn't know it. Flutter removes entries once they're in History.
  private static func readHistoryQueue(_ defaults: UserDefaults) -> [[String: Any]] {
    let queue = defaults.array(forKey: historyQueueKey) as? [[String: Any]] ?? []
    return queue.map { entry in
      var entry = entry
      if let corrected = entry["corrected"] as? String,
         let language = NLLanguageRecognizer.dominantLanguage(for: corrected) {
        entry["languageCode"] = language.rawValue
      }
      return entry
    }
  }

  /// Removes only the given entries, keeping any the keyboard added since.
  private static func removeHistoryEntries(_ ids: Set<String>, from defaults: UserDefaults) {
    let queue = defaults.array(forKey: historyQueueKey) as? [[String: Any]] ?? []
    let remaining = queue.filter { entry in
      guard let id = entry["id"] as? String else { return false }
      return !ids.contains(id)
    }
    defaults.set(remaining, forKey: historyQueueKey)
  }
}
