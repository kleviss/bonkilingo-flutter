import UIKit

protocol KeyboardViewDelegate: AnyObject {
  /// Finger went down on a key (shift and delete act here, like the system keyboard).
  func keyboardView(_ view: KeyboardView, didPress key: Key)
  /// Finger lifted on the key (characters, space, return and page keys act here).
  func keyboardView(_ view: KeyboardView, didRelease key: Key)
  /// Finger slid off or the touch was cancelled.
  func keyboardView(_ view: KeyboardView, didCancel key: Key)
  /// A variant picked from the long-press popup.
  func keyboardView(_ view: KeyboardView, didSelectAlternate text: String)
  /// The globe key needs the input view controller's own handler.
  func keyboardView(_ view: KeyboardView, didCreateGlobeKey button: KeyButton)
}

/// The keys: lays out a KeyboardPage and reports touches to its delegate.
final class KeyboardView: UIView {
  weak var delegate: KeyboardViewDelegate?

  /// Where the long-press popup is drawn. It must be large enough to show
  /// the popup above the top row (the keyboard's root view, which includes
  /// the Bonkilingo bar).
  weak var popupContainer: UIView?

  var colors = KeyColors.make(dark: false) {
    didSet { buttons.forEach { $0.colors = colors } }
  }

  var keyHeight: CGFloat = 42 { didSet { setNeedsLayout() } }

  private let sideInset: CGFloat = 3
  private let keyGap: CGFloat = 6
  private let rowGap: CGFloat = 11
  private let topInset: CGFloat = 6

  private var page = KeyboardPage(rows: [], columns: 10)
  private var buttons: [KeyButton] = []
  private var rowsOfButtons: [[KeyButton]] = []
  private var popup: AlternatesPopup?
  private var uppercase = false
  private var shiftSymbol = "shift"
  private var returnTitle: String?

  /// Keys whose finger is still down but which were already committed
  /// because the next key went down first (rollover); their lift is ignored.
  private var committedEarly = Set<ObjectIdentifier>()
  /// Character keys currently held, oldest first.
  private var heldCharacters: [KeyButton] = []
  private var previews: [ObjectIdentifier: KeyPreview] = [:]

  override init(frame: CGRect) {
    super.init(frame: frame)
    // Two-thumb typing: the next key can go down before the last one lifts.
    isMultipleTouchEnabled = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  var preferredHeight: CGFloat {
    let rows = CGFloat(page.rows.count)
    return topInset + rows * keyHeight + max(0, rows - 1) * rowGap + 4
  }

  func load(_ page: KeyboardPage) {
    dismissPopup()
    previews.values.forEach { $0.removeFromSuperview() }
    previews = [:]
    heldCharacters = []
    committedEarly = []
    buttons.forEach { $0.removeFromSuperview() }
    buttons = []
    rowsOfButtons = []
    self.page = page

    for row in page.rows {
      var rowButtons: [KeyButton] = []
      for spec in row.keys {
        let button = KeyButton(spec: spec)
        button.colors = colors
        button.isMultipleTouchEnabled = true
        button.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(keyUp(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(keyCancel(_:)), for: [.touchUpOutside, .touchCancel])
        if case .character(let base) = spec.key, !KeyboardLayouts.alternates(for: base).isEmpty {
          let press = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
          press.minimumPressDuration = 0.4
          button.addGestureRecognizer(press)
        }
        if spec.key == .globe {
          delegate?.keyboardView(self, didCreateGlobeKey: button)
        }
        addSubview(button)
        buttons.append(button)
        rowButtons.append(button)
      }
      rowsOfButtons.append(rowButtons)
    }
    updateLabels()
    setNeedsLayout()
  }

  /// Letter case and the shift key's look: "shift", "shift.fill" or "capslock.fill".
  /// Called after every keystroke, so it only redraws when something changed.
  func setShift(uppercase: Bool, symbol: String) {
    guard uppercase != self.uppercase || symbol != shiftSymbol else { return }
    self.uppercase = uppercase
    shiftSymbol = symbol
    updateLabels()
  }

  /// nil shows the return arrow.
  func setReturnTitle(_ title: String?) {
    guard title != returnTitle else { return }
    returnTitle = title
    updateLabels()
  }

  private func updateLabels() {
    for button in buttons {
      switch button.spec.key {
      case .character(let text):
        button.setTitle(uppercase ? text.uppercased() : text, fontSize: 23)
        button.setIcon(nil)
      case .shift:
        button.setTitle(nil, fontSize: 16)
        button.setIcon(shiftSymbol, accessibilityLabel: "Shift")
        button.showsActive = shiftSymbol != "shift"
      case .delete:
        button.setTitle(nil, fontSize: 16)
        button.setIcon("delete.left", accessibilityLabel: "Delete")
      case .space:
        button.setTitle("space", fontSize: 16)
        button.setIcon(nil)
        button.accessibilityLabel = "Space"
      case .returnKey:
        button.setTitle(returnTitle, fontSize: 16)
        button.setIcon(returnTitle == nil ? "return.left" : nil, accessibilityLabel: returnTitle ?? "Return")
      case .globe:
        button.setTitle(nil, fontSize: 16)
        button.setIcon("globe", accessibilityLabel: "Next keyboard")
      case .mode(let target):
        let title: String
        switch target {
        case .letters: title = "ABC"
        case .numbers: title = "123"
        case .symbols: title = "#+="
        }
        button.setTitle(title, fontSize: 16)
        button.setIcon(nil)
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let available = bounds.width - 2 * sideInset
    let unit = (available - (page.columns - 1) * keyGap) / page.columns

    for (rowIndex, rowButtons) in rowsOfButtons.enumerated() {
      let row = page.rows[rowIndex]
      let y = topInset + CGFloat(rowIndex) * (keyHeight + rowGap)

      let fixedWidth = row.keys.compactMap { $0.units }.reduce(0) { $0 + $1 * unit }
      let gaps = CGFloat(row.keys.count - 1) * keyGap
      let flexibleCount = CGFloat(row.keys.filter { $0.units == nil }.count)
      let flexibleWidth = flexibleCount > 0 ? max(0, (available - fixedWidth - gaps) / flexibleCount) : 0
      let widths = row.keys.map { $0.units.map { $0 * unit } ?? flexibleWidth }

      var frames: [CGRect] = []
      if row.pinsEdges, widths.count >= 2 {
        let middle = widths.dropFirst().dropLast()
        let middleWidth = middle.reduce(0, +) + CGFloat(max(0, middle.count - 1)) * keyGap
        frames.append(CGRect(x: sideInset, y: y, width: widths[0], height: keyHeight))
        var x = (bounds.width - middleWidth) / 2
        for width in middle {
          frames.append(CGRect(x: x, y: y, width: width, height: keyHeight))
          x += width + keyGap
        }
        frames.append(CGRect(x: bounds.width - sideInset - widths[widths.count - 1], y: y,
                             width: widths[widths.count - 1], height: keyHeight))
      } else {
        let total = widths.reduce(0, +) + gaps
        var x = (bounds.width - total) / 2
        for width in widths {
          frames.append(CGRect(x: x, y: y, width: width, height: keyHeight))
          x += width + keyGap
        }
      }

      for (button, frame) in zip(rowButtons, frames) {
        button.frame = frame.integral
        // Share the gaps between neighbors so taps between keys still land.
        button.touchInsets = UIEdgeInsets(top: -rowGap / 2, left: -keyGap / 2,
                                          bottom: -rowGap / 2, right: -keyGap / 2)
      }
    }
  }

  // MARK: - Touches

  @objc private func keyDown(_ sender: KeyButton) {
    // Rollover, like the system keyboard: a new key going down commits the
    // letters still held, so fast two-thumb typing never waits for a lift.
    for held in heldCharacters where held !== sender {
      committedEarly.insert(ObjectIdentifier(held))
      hidePreview(for: held)
      delegate?.keyboardView(self, didRelease: held.spec.key)
    }
    heldCharacters.removeAll()

    if case .character = sender.spec.key {
      heldCharacters.append(sender)
      showPreview(for: sender)
    }
    delegate?.keyboardView(self, didPress: sender.spec.key)
  }

  @objc private func keyUp(_ sender: KeyButton) {
    hidePreview(for: sender)
    heldCharacters.removeAll { $0 === sender }
    if committedEarly.remove(ObjectIdentifier(sender)) != nil { return }
    delegate?.keyboardView(self, didRelease: sender.spec.key)
  }

  @objc private func keyCancel(_ sender: KeyButton) {
    hidePreview(for: sender)
    heldCharacters.removeAll { $0 === sender }
    if committedEarly.remove(ObjectIdentifier(sender)) != nil { return }
    delegate?.keyboardView(self, didCancel: sender.spec.key)
  }

  // MARK: - Key preview

  /// The enlarged letter above a pressed key, as on the system keyboard.
  private func showPreview(for button: KeyButton) {
    guard case .character(let text) = button.spec.key else { return }
    let container = popupContainer ?? self
    let keyFrame = button.convert(button.bounds, to: container)
    let width = max(keyFrame.width + 16, 46)
    let height = keyHeight + 10
    var x = keyFrame.midX - width / 2
    x = min(max(x, 1), container.bounds.width - width - 1)
    let y = max(0, keyFrame.minY - height - 2)

    let preview = previews[ObjectIdentifier(button)] ?? KeyPreview()
    preview.configure(text: uppercase ? text.uppercased() : text, colors: colors)
    preview.frame = CGRect(x: x, y: y, width: width, height: height)
    container.addSubview(preview)
    previews[ObjectIdentifier(button)] = preview
  }

  private func hidePreview(for button: KeyButton) {
    previews.removeValue(forKey: ObjectIdentifier(button))?.removeFromSuperview()
  }

  @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard let button = gesture.view as? KeyButton, case .character(let base) = button.spec.key else { return }
    let container = popupContainer ?? self

    switch gesture.state {
    case .began:
      hidePreview(for: button)
      let options = KeyboardLayouts.alternates(for: base).map { uppercase ? $0.uppercased() : $0 }
      guard !options.isEmpty else { return }
      let popup = AlternatesPopup(options: options, colors: colors)
      let keyFrame = button.convert(button.bounds, to: container)
      let width = CGFloat(options.count) * AlternatesPopup.cellWidth + 8
      var x = keyFrame.midX - AlternatesPopup.cellWidth / 2 - 4
      x = min(max(x, 2), container.bounds.width - width - 2)
      let y = max(0, keyFrame.minY - AlternatesPopup.height - 4)
      popup.frame = CGRect(x: x, y: y, width: width, height: AlternatesPopup.height)
      container.addSubview(popup)
      self.popup = popup
      popup.select(at: gesture.location(in: popup))
    case .changed:
      if let popup { popup.select(at: gesture.location(in: popup)) }
    case .ended:
      if let choice = popup?.selectedOption {
        delegate?.keyboardView(self, didSelectAlternate: choice)
      }
      dismissPopup()
    default:
      dismissPopup()
    }
  }

  private func dismissPopup() {
    popup?.removeFromSuperview()
    popup = nil
  }
}
