import Flutter
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
  /// own process, can read them. Until both targets carry the App Group
  /// entitlement (roadmap Phase 3), iOS keeps this suite inside the app only.
  private func registerKeyboardSettingsChannel() {
    guard let registrar = registrar(forPlugin: "KeyboardSettingsChannel") else { return }
    let channel = FlutterMethodChannel(
      name: "com.bonkilingo.app/keyboard_settings",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(suiteName: "group.com.bonkilingo.app") else {
        result(FlutterError(code: "unavailable", message: "App Group defaults unavailable", details: nil))
        return
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
}
