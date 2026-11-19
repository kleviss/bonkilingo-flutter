import UIKit
import os

/// The Bonkilingo keyboard: a full German/English keyboard with a Bonkilingo
/// bar on top. Phase 1 of BONKILINGO_ROADMAP.md: it types; the Correct
/// button is shown but not wired to the API yet (Phase 2).
///
/// Plain UIKit on purpose: keyboard extensions get a small, unpublished
/// memory budget, so no Flutter engine and no CocoaPods dependencies.
final class KeyboardViewController: UIInputViewController {
  private enum ShiftState { case off, on, locked }

  private let bar = BonkilingoBar()
  private let keysView = KeyboardView()
  private var heightConstraint: NSLayoutConstraint?

  private var mode: KeyboardMode = .letters
  private var letterLayout = KeyboardPreferences.letterLayout
  private var shiftState: ShiftState = .off
  private var lastShiftTap: Date?
  private var showsGlobe = true
  private var appliedDark: Bool?
  /// The app's Correct on/off switch, read when the keyboard appears.
  private var correctionsEnabled = true
  private var showsContextReadout = KeyboardPreferences.showsContextReadout

  private var deleteTimer: Timer?
  private var deleteRepeats = 0

  private let log = Logger(subsystem: "com.bonkilingo.app.keyboard", category: "context")

  // MARK: - Lifecycle

  override func loadView() {
    // A UIInputView that adopts UIInputViewAudioFeedback, so playInputClick()
    // plays the system key click (when the user has keyboard clicks on).
    view = ClickingInputView(frame: .zero, inputViewStyle: .keyboard)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // The window's system gesture recognizers (edge swipes, home indicator)
    // otherwise hold back touches near the screen edges until they fail,
    // which makes q, a, shift, 123 and delete feel laggy.
    view.window?.gestureRecognizers?.forEach { $0.delaysTouchesBegan = false }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    bar.translatesAutoresizingMaskIntoConstraints = false
    keysView.translatesAutoresizingMaskIntoConstraints = false
    keysView.delegate = self
    keysView.popupContainer = view
    view.addSubview(bar)
    view.addSubview(keysView)

    let height = view.heightAnchor.constraint(equalToConstant: 260)
    height.priority = UILayoutPriority(999)
    heightConstraint = height

    NSLayoutConstraint.activate([
      bar.topAnchor.constraint(equalTo: view.topAnchor),
      bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bar.heightAnchor.constraint(equalToConstant: BonkilingoBar.height),
      keysView.topAnchor.constraint(equalTo: bar.bottomAnchor),
      keysView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      keysView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      keysView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      height,
    ])

    bar.onToggleLayout = { [weak self] in self?.toggleLetterLayout() }
    bar.onToggleContextReadout = { [weak self] in self?.toggleContextReadout() }
    bar.onCorrect = { [weak self] in self?.updateBar() }

    reloadKeys()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    correctionsEnabled = SharedSettings.correctionsEnabled
    applyKeyboardType()
    refresh()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    // iPhone landscape has a compact height: shorter keys, like the system keyboard.
    keysView.keyHeight = traitCollection.verticalSizeClass == .compact ? 32 : 42
    heightConstraint?.constant = BonkilingoBar.height + keysView.preferredHeight

    if needsInputModeSwitchKey != showsGlobe {
      showsGlobe = needsInputModeSwitchKey
      reloadKeys()
    }
  }

  override func textDidChange(_ textInput: UITextInput?) {
    super.textDidChange(textInput)
    refresh()
  }

  override func selectionDidChange(_ textInput: UITextInput?) {
    super.selectionDidChange(textInput)
    updateReadout()
  }

  private func refresh() {
    applyAppearance()
    keysView.setReturnTitle(returnTitle())
    updateAutoShift()
    updateBar()
  }

  // MARK: - Keys

  private func reloadKeys() {
    let page = KeyboardLayouts.page(mode: mode, letters: letterLayout, showsGlobe: showsGlobe)
    keysView.load(page)
    keysView.setReturnTitle(returnTitle())
    applyShiftAppearance()
    bar.setLayoutTitle(letterLayout.label)
    heightConstraint?.constant = BonkilingoBar.height + keysView.preferredHeight
  }

  private func applyKeyboardType() {
    switch textDocumentProxy.keyboardType {
    case .numberPad, .decimalPad, .numbersAndPunctuation, .asciiCapableNumberPad:
      mode = .numbers
    default:
      mode = .letters
    }
    reloadKeys()
  }

  private func applyAppearance() {
    let dark = textDocumentProxy.keyboardAppearance == .dark
      || traitCollection.userInterfaceStyle == .dark
    guard dark != appliedDark else { return }
    appliedDark = dark
    keysView.colors = KeyColors.make(dark: dark)
    bar.apply(dark: dark)
  }

  private func returnTitle() -> String? {
    switch textDocumentProxy.returnKeyType {
    case .go: return "Go"
    case .search, .google, .yahoo: return "Search"
    case .send: return "Send"
    case .done: return "Done"
    case .next: return "Next"
    case .join: return "Join"
    case .route: return "Route"
    case .continue: return "Continue"
    case .emergencyCall: return "Emergency"
    default: return nil
    }
  }

  // MARK: - Typing

  private func insert(_ text: String) {
    textDocumentProxy.insertText(text)
    UIDevice.current.playInputClick()
  }

  private func handleSpace() {
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    // Double space ends a sentence: "word  " becomes "word. ".
    if before.hasSuffix(" "),
       let previous = before.dropLast().last,
       previous.isLetter || previous.isNumber {
      textDocumentProxy.deleteBackward()
      insert(". ")
    } else {
      insert(" ")
    }
    // Like the system keyboard, a space on the number pages returns to letters.
    if mode != .letters, textDocumentProxy.keyboardType != .numberPad {
      mode = .letters
      reloadKeys()
    }
  }

  private func deleteOnce() {
    textDocumentProxy.deleteBackward()
    UIDevice.current.playInputClick()
  }

  private func startDeleteRepeat() {
    deleteTimer?.invalidate()
    deleteRepeats = 0
    deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
      self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
        guard let self else { return }
        self.deleteRepeats += 1
        // After a while, delete whole words, like the system keyboard.
        if self.deleteRepeats > 15 { self.deleteWord() } else { self.deleteOnce() }
      }
    }
  }

  private func stopDeleteRepeat() {
    deleteTimer?.invalidate()
    deleteTimer = nil
    updateAutoShift()
    updateReadout()
  }

  private func deleteWord() {
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    guard !before.isEmpty else { return }
    var count = 0
    var sawWordCharacter = false
    for character in before.reversed() {
      if character.isWhitespace || character.isPunctuation {
        if sawWordCharacter { break }
      } else {
        sawWordCharacter = true
      }
      count += 1
    }
    for _ in 0..<max(count, 1) { textDocumentProxy.deleteBackward() }
  }

  // MARK: - Shift

  private func shiftTapped() {
    let now = Date()
    if let last = lastShiftTap, now.timeIntervalSince(last) < 0.3 {
      shiftState = .locked
      lastShiftTap = nil
    } else {
      shiftState = shiftState == .off ? .on : .off
      lastShiftTap = now
    }
    applyShiftAppearance()
  }

  private func applyShiftAppearance() {
    let symbol: String
    switch shiftState {
    case .off: symbol = "shift"
    case .on: symbol = "shift.fill"
    case .locked: symbol = "capslock.fill"
    }
    keysView.setShift(uppercase: shiftState != .off && mode == .letters, symbol: symbol)
  }

  /// Turns shift on at the start of a sentence (or word, or always),
  /// following the text field's autocapitalization setting.
  private func updateAutoShift() {
    guard shiftState != .locked, mode == .letters else { return }
    let before = textDocumentProxy.documentContextBeforeInput ?? ""
    let shouldShift: Bool
    switch textDocumentProxy.autocapitalizationType ?? .sentences {
    case .allCharacters:
      shouldShift = true
    case .words:
      shouldShift = before.isEmpty || before.last?.isWhitespace == true
    case .sentences:
      shouldShift = Self.isSentenceStart(before)
    default:
      shouldShift = false
    }
    shiftState = shouldShift ? .on : .off
    applyShiftAppearance()
  }

  static func isSentenceStart(_ before: String) -> Bool {
    if before.isEmpty || before.last == "\n" { return true }
    guard before.last == " " else { return false }
    let trimmed = before.trimmingCharacters(in: .whitespaces)
    guard let last = trimmed.last else { return true }
    return ".!?".contains(last) || last == "\n"
  }

  // MARK: - Bar

  private func toggleLetterLayout() {
    letterLayout = letterLayout.toggled
    KeyboardPreferences.letterLayout = letterLayout
    if mode == .letters || mode == .numbers { reloadKeys() } else { bar.setLayoutTitle(letterLayout.label) }
  }

  private func toggleContextReadout() {
    showsContextReadout.toggle()
    KeyboardPreferences.showsContextReadout = showsContextReadout
    updateBar()
  }

  /// Per keystroke: only the context readout changes as you type.
  private func updateReadout() {
    if showsContextReadout { updateBar() }
  }

  private func updateBar() {
    if showsContextReadout {
      // Counts only, never the text itself.
      let before = textDocumentProxy.documentContextBeforeInput?.count ?? 0
      let after = textDocumentProxy.documentContextAfterInput?.count ?? 0
      let selected = textDocumentProxy.selectedText?.count ?? 0
      bar.setStatus("Sees \(before) before · \(after) after · \(selected) selected")
      log.info("context before=\(before) after=\(after) selected=\(selected)")
      bar.setCorrect(visible: false, enabled: false)
      return
    }

    if !correctionsEnabled {
      bar.setStatus("Correct is off in the Bonkilingo app")
      bar.setCorrect(visible: false, enabled: false)
    } else if !hasFullAccess {
      bar.setStatus("Allow Full Access in Settings to use Correct")
      bar.setCorrect(visible: true, enabled: false)
    } else {
      bar.setStatus("Correct is coming soon")
      bar.setCorrect(visible: true, enabled: false)
    }
  }
}

final class ClickingInputView: UIInputView, UIInputViewAudioFeedback {
  var enableInputClicksWhenVisible: Bool { true }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {
  func keyboardView(_ view: KeyboardView, didPress key: Key) {
    switch key {
    case .shift:
      shiftTapped()
    case .delete:
      deleteOnce()
      startDeleteRepeat()
    default:
      break
    }
  }

  func keyboardView(_ view: KeyboardView, didRelease key: Key) {
    switch key {
    case .character(let text):
      insert(shiftState != .off && mode == .letters ? text.uppercased() : text)
      if shiftState == .on { shiftState = .off }
      updateAutoShift()
      updateReadout()
    case .space:
      handleSpace()
      updateAutoShift()
      updateReadout()
    case .returnKey:
      insert("\n")
      updateAutoShift()
      updateReadout()
    case .mode(let target):
      mode = target
      reloadKeys()
      if target == .letters { updateAutoShift() }
    case .delete:
      stopDeleteRepeat()
    case .shift, .globe:
      break
    }
  }

  func keyboardView(_ view: KeyboardView, didCancel key: Key) {
    if key == .delete { stopDeleteRepeat() }
  }

  func keyboardView(_ view: KeyboardView, didSelectAlternate text: String) {
    insert(text)
    if shiftState == .on { shiftState = .off }
    updateAutoShift()
    updateReadout()
  }

  func keyboardView(_ view: KeyboardView, didCreateGlobeKey button: KeyButton) {
    // Tap switches keyboards; holding shows the system keyboard list.
    button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
  }
}
