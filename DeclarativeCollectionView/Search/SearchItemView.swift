//
//  SearchItemView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - SearchItemView

/// A simple cell view displaying a colored indicator, title, and subtitle.
final class SearchItemView: UIView, ModelableView {

	var model: SearchItem {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let colorIndicator = UIView()
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
		let stack = UIStackView(arrangedSubviews: [colorIndicator, titleLabel, subtitleLabel])
		stack.axis = .horizontal
		stack.spacing = 12
		stack.alignment = .center
		stack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(stack)

		colorIndicator.layer.cornerRadius = 6
		colorIndicator.layer.masksToBounds = true

		titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
		subtitleLabel.font = .systemFont(ofSize: 14)
		subtitleLabel.textColor = .secondaryLabel
		subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
			stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
			colorIndicator.widthAnchor.constraint(equalToConstant: 12),
			colorIndicator.heightAnchor.constraint(equalToConstant: 12)
		])
	}

	private func updateUI() {
		colorIndicator.backgroundColor = model.color
		titleLabel.text = model.title
		subtitleLabel.text = model.subtitle
	}
}

// MARK: - SearchItemViewable

struct SearchItemViewable: CollectionViewable {
	typealias ViewType = SearchItemView

	let model: SearchItem

	var preferredSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 48)
	}

	func makeView() -> SearchItemView {
		SearchItemView(model)
	}
}

// MARK: - SectionHeaderView

/// A simple section header with a title label.
final class SectionHeaderView: UIView, ModelableView {

	struct Model: Identifiable {
		let id: String
		let title: String
	}

	var model: Model {
		didSet { titleLabel.text = model.title }
	}

	var updatable: Updatable?

	private let titleLabel = UILabel()

	required init(_ model: Model) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
		titleLabel.textColor = .secondaryLabel
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(titleLabel)

		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
			titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
		])

		titleLabel.text = model.title
	}
}

// MARK: - SectionHeaderViewable

struct SectionHeaderViewable: Viewable {
	typealias ViewType = SectionHeaderView

	let model: SectionHeaderView.Model

	var preferredSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 36)
	}

	func makeView() -> SectionHeaderView {
		SectionHeaderView(model)
	}
}
