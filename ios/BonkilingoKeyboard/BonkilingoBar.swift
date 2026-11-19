import UIKit

/// The strip above the keys: brand, letter layout toggle, a status line and
/// the Correct button.
final class BonkilingoBar: UIView {
  static let height: CGFloat = 44
  static let brandYellow = UIColor(red: 0.92, green: 0.70, blue: 0.03, alpha: 1)

  var onToggleLayout: (() -> Void)?
  var onToggleContextReadout: (() -> Void)?
  var onCorrect: (() -> Void)?

  private let brandLabel = UILabel()
  private let layoutButton = UIButton(type: .system)
  private let statusLabel = UILabel()
  private let correctButton = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)

    let dot = UIView()
    dot.backgroundColor = Self.brandYellow
    dot.layer.cornerRadius = 4
    dot.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      dot.widthAnchor.constraint(equalToConstant: 8),
      dot.heightAnchor.constraint(equalToConstant: 8),
    ])

    brandLabel.text = "Bonkilingo"
    brandLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    let brand = UIStackView(arrangedSubviews: [dot, brandLabel])
    brand.spacing = 6
    brand.alignment = .center
    brand.isAccessibilityElement = true
    brand.accessibilityLabel = "Bonkilingo"
    brand.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(brandHeld(_:))))

    layoutButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
    layoutButton.layer.cornerRadius = 6
    layoutButton.layer.borderWidth = 1
    layoutButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    layoutButton.addTarget(self, action: #selector(layoutTapped), for: .touchUpInside)

    statusLabel.font = .systemFont(ofSize: 12)
    statusLabel.numberOfLines = 2
    statusLabel.adjustsFontSizeToFitWidth = true
    statusLabel.minimumScaleFactor = 0.8
    statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    correctButton.setTitle("Correct", for: .normal)
    correctButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    correctButton.backgroundColor = Self.brandYellow
    correctButton.setTitleColor(.black, for: .normal)
    correctButton.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .disabled)
    correctButton.layer.cornerRadius = 15
    correctButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14)
    correctButton.addTarget(self, action: #selector(correctTapped), for: .touchUpInside)
    correctButton.setContentCompressionResistancePriority(.required, for: .horizontal)

    let stack = UIStackView(arrangedSubviews: [brand, layoutButton, statusLabel, correctButton])
    stack.spacing = 10
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  func apply(dark: Bool) {
    let text: UIColor = dark ? .white : .black
    brandLabel.textColor = text
    statusLabel.textColor = text.withAlphaComponent(0.6)
    layoutButton.setTitleColor(text, for: .normal)
    layoutButton.layer.borderColor = text.withAlphaComponent(0.35).cgColor
  }

  func setLayoutTitle(_ title: String) {
    layoutButton.setTitle(title, for: .normal)
    layoutButton.accessibilityLabel = "Keyboard layout \(title)"
  }

  func setStatus(_ text: String?) {
    statusLabel.text = text
  }

  func setCorrect(visible: Bool, enabled: Bool) {
    correctButton.isHidden = !visible
    correctButton.isEnabled = enabled
    correctButton.alpha = enabled ? 1 : 0.55
  }

  @objc private func layoutTapped() { onToggleLayout?() }

  @objc private func correctTapped() { onCorrect?() }

  @objc private func brandHeld(_ gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began { onToggleContextReadout?() }
  }
}
