import Foundation
import Security

/// The keyboard token the Bonkilingo app leaves in the shared Keychain
/// (lib/data/services/keyboard_auth_service.dart). With it, corrections count
/// as the signed-in user's (their own hourly limit) instead of anonymous.
///
/// The app writes it with flutter_secure_storage, so this reads the same
/// item: a generic password with that plugin's service name, the key as the
/// account, in the shared access group.
enum KeyboardAuth {
  /// Must match both .entitlements files and KeyboardAuthService.keychainGroup.
  /// H9DTLRUW87 is the Apple team ID.
  static let accessGroup = "H9DTLRUW87.com.bonkilingo.shared"
  static let service = "flutter_secure_storage_service"
  static let tokenAccount = "keyboard_token"

  /// nil when signed out in the app (or before the app first ran).
  static func token() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: tokenAccount,
      kSecAttrAccessGroup as String: accessGroup,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data,
          let token = String(data: data, encoding: .utf8),
          token.hasPrefix("kb_") else { return nil }
    return token
  }
}
