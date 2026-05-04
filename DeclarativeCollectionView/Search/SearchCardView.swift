//
//  SearchCardView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - SearchCardView

/// A card-style cell view used in grid and carousel layouts.
final class SearchCardView: UIView, ModelableView {

	var model: SearchItem {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let colorView = UIView()
	private let titleLabel = UILabel()
	private let subtitleLabel = UILabel()

	required init(_ model: SearchItem) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
		updateUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		layer.cornerRadius = 10
		layer.masksToBounds = true
		backgroundColor = .secondarySystemBackground

		colorView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(colorView)

		titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 2

		subtitleLabel.font = .systemFont(ofSize: 12)
		subtitleLabel.textColor = .secondaryLabel
		subtitleLabel.textAlignment = .center

		let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
		stack.axis = .vertical
		stack.spacing = 2
		stack.alignment = .center
		stack.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stack)

		NSLayoutConstraint.activate([
			colorView.topAnchor.constraint(equalTo: topAnchor),
			colorView.leadingAnchor.constraint(equalTo: leadingAnchor),
			colorView.trailingAnchor.constraint(equalTo: trailingAnchor),
			colorView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),

			stack.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 8),
			stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
		])
	}

	private func updateUI() {
		colorView.backgroundColor = model.color
		titleLabel.text = model.title
		subtitleLabel.text = model.subtitle
	}
}
