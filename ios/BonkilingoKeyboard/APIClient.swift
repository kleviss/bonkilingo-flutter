import Foundation

/// A failed correction, with the message the keyboard shows.
struct CorrectionError: Error {
  let message: String
}

/// Talks to the Bonkilingo backend's POST /api/correct (bonkilingo-backend).
///
/// Uses an ephemeral session: no cache, no cookies, nothing of the text kept
/// on disk. Text is only sent when the user taps Correct.
final class APIClient {
  private let baseURL: URL
  private let session: URLSession

  init(baseURL: URL) {
    self.baseURL = baseURL
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 20
    configuration.waitsForConnectivity = false
    session = URLSession(configuration: configuration)
  }

  /// The backend URL from the keyboard's Info.plist (BonkilingoAPIBaseURL,
  /// set from BONKILINGO_API_BASE_URL in Keyboard.xcconfig).
  static func fromBundle() -> APIClient? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "BonkilingoAPIBaseURL") as? String,
          let url = URL(string: value), url.scheme == "https" else { return nil }
    return APIClient(baseURL: url)
  }

  func correct(_ text: String) async throws -> String {
    var request = URLRequest(url: baseURL.appendingPathComponent("api/correct"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    // "auto": keep the text's own language (the server never translates).
    request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "language": "auto"])

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch let error as URLError {
      switch error.code {
      case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
        throw CorrectionError(message: "You're offline. Check your connection and try again.")
      case .timedOut:
        throw CorrectionError(message: "Bonkilingo took too long to answer. Try again.")
      case .cancelled:
        throw CancellationError()
      default:
        throw CorrectionError(message: "Couldn't reach Bonkilingo. Try again.")
      }
    }

    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    if status == 200, let corrected = json?["corrected"] as? String, !corrected.isEmpty {
      return corrected
    }
    // 4xx messages from the backend are written for users (limits, length, sign-in).
    if (400..<500).contains(status), let message = json?["error"] as? String {
      throw CorrectionError(message: message)
    }
    throw CorrectionError(message: "Bonkilingo couldn't correct this right now. Try again.")
  }
}
