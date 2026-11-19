import UIKit

/// Shown over the keys while correcting: progress, then the corrected text
/// with changed words highlighted, and Replace / Copy.
final class CorrectionPanel: UIView {
  enum State {
    case loading
    case result(original: String, corrected: String, note: String?)
    case unchanged
    case message(String, canCopy: Bool)
  }

  var onReplace: (() -> Void)?
  var onCopy: (() -> Void)?
  var onClose: (() -> Void)?

  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let textView = UITextView()
  private let noteLabel = UILabel()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let copyButton = UIButton(type: .system)
  private let replaceButton = UIButton(type: .system)
  private var dark = false

  override init(frame: CGRect) {
    super.init(frame: frame)

    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)

    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    closeButton.accessibilityLabel = "Close"
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

    textView.isEditable = false
    textView.isSelectable = false
    textView.backgroundColor = .clear
    textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    textView.textContainer.lineFragmentPadding = 0

    noteLabel.font = .systemFont(ofSize: 12)
    noteLabel.numberOfLines = 2

    copyButton.setTitle("Copy", for: .normal)
    copyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    copyButton.layer.cornerRadius = 10
    copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

    replaceButton.setTitle("Replace", for: .normal)
    replaceButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    replaceButton.setTitleColor(.black, for: .normal)
    replaceButton.backgroundColor = BonkilingoBar.brandYellow
    replaceButton.layer.cornerRadius = 10
    replaceButton.addTarget(self, action: #selector(replaceTapped), for: .touchUpInside)

    let header = UIStackView(arrangedSubviews: [titleLabel, spinner, UIView(), closeButton])
    header.spacing = 8
    header.alignment = .center

    let buttons = UIStackView(arrangedSubviews: [copyButton, replaceButton])
    buttons.spacing = 10
    buttons.distribution = .fillEqually

    let stack = UIStackView(arrangedSubviews: [header, textView, noteLabel, buttons])
    stack.axis = .vertical
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
      buttons.heightAnchor.constraint(equalToConstant: 42),
      closeButton.widthAnchor.constraint(equalToConstant: 28),
    ])
    textView.setContentHuggingPriority(.defaultLow, for: .vertical)
    textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  func apply(dark: Bool) {
    self.dark = dark
    let text: UIColor = dark ? .white : .black
    backgroundColor = dark ? UIColor(white: 0.17, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
    titleLabel.textColor = text
    noteLabel.textColor = text.withAlphaComponent(0.6)
    closeButton.tintColor = text.withAlphaComponent(0.4)
    copyButton.backgroundColor = dark ? UIColor(white: 0.32, alpha: 1) : .white
    copyButton.setTitleColor(text, for: .normal)
    spinner.color = text
  }

  func show(_ state: State) {
    let textColor: UIColor = dark ? .white : .black
    switch state {
    case .loading:
      titleLabel.text = "Correcting…"
      spinner.startAnimating()
      textView.attributedText = nil
      noteLabel.text = nil
      setButtons(copy: false, replace: false)
    case .result(let original, let corrected, let note):
      titleLabel.text = "Suggestion"
      spinner.stopAnimating()
      textView.attributedText = Self.highlighted(original: original, corrected: corrected, textColor: textColor)
      noteLabel.text = note
      setButtons(copy: true, replace: true)
    case .unchanged:
      titleLabel.text = "Looks good"
      spinner.stopAnimating()
      textView.attributedText = NSAttributedString(
        string: "No changes needed.",
        attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: textColor]
      )
      noteLabel.text = nil
      setButtons(copy: false, replace: false)
    case .message(let message, let canCopy):
      titleLabel.text = "Bonkilingo"
      spinner.stopAnimating()
      textView.attributedText = NSAttributedString(
        string: message,
        attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: textColor]
      )
      noteLabel.text = nil
      setButtons(copy: canCopy, replace: false)
    }
    textView.setContentOffset(.zero, animated: false)
  }

  private func setButtons(copy: Bool, replace: Bool) {
    copyButton.isHidden = !copy
    replaceButton.isHidden = !replace
    copyButton.superview?.isHidden = !copy && !replace
  }

  /// The corrected text with changed words underlined and tinted.
  static func highlighted(original: String, corrected: String, textColor: UIColor) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let base: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: textColor]
    for piece in WordDiff.highlight(original: original, corrected: corrected) {
      var attributes = base
      if piece.changed {
        attributes[.font] = UIFont.systemFont(ofSize: 17, weight: .semibold)
        attributes[.backgroundColor] = BonkilingoBar.brandYellow.withAlphaComponent(0.35)
      }
      result.append(NSAttributedString(string: piece.text, attributes: attributes))
    }
    return result
  }

  @objc private func closeTapped() { onClose?() }
  @objc private func copyTapped() { onCopy?() }
  @objc private func replaceTapped() { onReplace?() }
}
