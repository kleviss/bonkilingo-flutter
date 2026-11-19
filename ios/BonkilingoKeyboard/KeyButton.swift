import UIKit

struct KeyColors {
  let key: UIColor
  let specialKey: UIColor
  let keyPressed: UIColor
  let specialKeyPressed: UIColor
  let text: UIColor
  let shadow: UIColor

  static func make(dark: Bool) -> KeyColors {
    if dark {
      return KeyColors(
        key: UIColor(white: 0.42, alpha: 1),
        specialKey: UIColor(white: 0.27, alpha: 1),
        keyPressed: UIColor(white: 0.27, alpha: 1),
        specialKeyPressed: UIColor(white: 0.42, alpha: 1),
        text: .white,
        shadow: UIColor(white: 0, alpha: 0.6)
      )
    }
    return KeyColors(
      key: .white,
      specialKey: UIColor(red: 0.67, green: 0.69, blue: 0.73, alpha: 1),
      keyPressed: UIColor(red: 0.67, green: 0.69, blue: 0.73, alpha: 1),
      specialKeyPressed: .white,
      text: .black,
      shadow: UIColor(red: 0.53, green: 0.54, blue: 0.56, alpha: 1)
    )
  }
}

/// One key. Inserts nothing itself: KeyboardView forwards its touch events.
final class KeyButton: UIControl {
  let spec: KeySpec

  /// Grows the touch area into the gaps between keys (negative insets),
  /// like the system keyboard, so taps between keys still land.
  var touchInsets = UIEdgeInsets.zero

  /// Drawn like a letter key even though it is a special key (shift while on).
  var showsActive = false { didSet { updateColors() } }

  var colors = KeyColors.make(dark: false) { didSet { updateColors() } }

  private let label = UILabel()
  private let iconView = UIImageView()

  init(spec: KeySpec) {
    self.spec = spec
    super.init(frame: .zero)
    isAccessibilityElement = true
    accessibilityTraits = .keyboardKey

    layer.cornerRadius = 8
    layer.shadowOffset = CGSize(width: 0, height: 1)
    layer.shadowOpacity = 1
    layer.shadowRadius = 0

    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.6
    label.isUserInteractionEnabled = false
    iconView.contentMode = .center
    iconView.isUserInteractionEnabled = false
    addSubview(label)
    addSubview(iconView)
    updateColors()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  func setTitle(_ title: String?, fontSize: CGFloat) {
    label.text = title
    label.font = .systemFont(ofSize: fontSize, weight: .regular)
    label.isHidden = title == nil
    if let title { accessibilityLabel = title }
  }

  func setIcon(_ systemName: String?, accessibilityLabel: String? = nil) {
    if let systemName {
      let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
      iconView.image = UIImage(systemName: systemName, withConfiguration: config)
    } else {
      iconView.image = nil
    }
    iconView.isHidden = systemName == nil
    if let accessibilityLabel { self.accessibilityLabel = accessibilityLabel }
  }

  override var isHighlighted: Bool { didSet { updateColors() } }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds.insetBy(dx: 2, dy: 0)
    iconView.frame = bounds
    layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    bounds.inset(by: touchInsets).contains(point)
  }

  private func updateColors() {
    let special = spec.key.isSpecial && !showsActive
    if isHighlighted {
      backgroundColor = special ? colors.specialKeyPressed : colors.keyPressed
    } else {
      backgroundColor = special ? colors.specialKey : colors.key
    }
    label.textColor = colors.text
    iconView.tintColor = colors.text
    layer.shadowColor = colors.shadow.cgColor
  }
}

/// The row of variants shown above a held letter. The finger slides across
/// it and lifting inserts the highlighted variant.
final class AlternatesPopup: UIView {
  let options: [String]
  private(set) var selectedIndex: Int?
  private var labels: [UILabel] = []
  private let colors: KeyColors

  static let cellWidth: CGFloat = 36
  static let height: CGFloat = 50

  init(options: [String], colors: KeyColors) {
    self.options = options
    self.colors = colors
    super.init(frame: .zero)
    backgroundColor = colors.key
    layer.cornerRadius = 10
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.3
    layer.shadowRadius = 4
    layer.shadowOffset = CGSize(width: 0, height: 2)
    for option in options {
      let label = UILabel()
      label.text = option
      label.font = .systemFont(ofSize: 24)
      label.textAlignment = .center
      label.textColor = colors.text
      label.layer.cornerRadius = 6
      label.layer.masksToBounds = true
      addSubview(label)
      labels.append(label)
    }
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  var selectedOption: String? { selectedIndex.map { options[$0] } }

  override func layoutSubviews() {
    super.layoutSubviews()
    for (index, label) in labels.enumerated() {
      label.frame = CGRect(x: 4 + CGFloat(index) * Self.cellWidth, y: 4,
                           width: Self.cellWidth, height: bounds.height - 8)
    }
  }

  /// Highlights the variant under `point` (in this view's coordinates).
  /// Points beside the popup select the nearest end; far above or below
  /// selects nothing, so sliding away cancels.
  func select(at point: CGPoint) {
    guard point.y > -60, point.y < bounds.height + 80 else {
      setSelected(nil)
      return
    }
    let index = Int((point.x - 4) / Self.cellWidth)
    setSelected(min(max(index, 0), options.count - 1))
  }

  private func setSelected(_ index: Int?) {
    selectedIndex = index
    for (i, label) in labels.enumerated() {
      let selected = i == index
      label.backgroundColor = selected ? UIColor.systemBlue : .clear
      label.textColor = selected ? .white : colors.text
    }
  }
}
