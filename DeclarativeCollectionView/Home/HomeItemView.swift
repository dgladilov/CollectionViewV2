//
//  HomeItemView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - HomeItem

struct HomeItem: Identifiable {
	let id: String
	var title: String
	var subtitle: String
	var color: UIColor
	var details: String?
}

// MARK: - HomeItemView

final class HomeItemView: UIView, ModelableView {

	var model: HomeItem {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let colorIndicator = UIView()
	private let titleLabel = UILabel()
	private let subtitleLabel = UILabel()
	private let detailsLabel = UILabel()

	required init(_ model: HomeItem) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
		updateUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		colorIndicator.layer.cornerRadius = 8
		colorIndicator.layer.masksToBounds = true
		colorIndicator.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
		subtitleLabel.font = .systemFont(ofSize: 13)
		subtitleLabel.textColor = .secondaryLabel

		detailsLabel.font = .systemFont(ofSize: 13)
		detailsLabel.textColor = .secondaryLabel
		detailsLabel.numberOfLines = 0
		detailsLabel.isHidden = true

		let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, detailsLabel])
		textStack.axis = .vertical
		textStack.spacing = 2

		let mainStack = UIStackView(arrangedSubviews: [colorIndicator, textStack])
		mainStack.axis = .horizontal
		mainStack.spacing = 12
		mainStack.alignment = .center
		mainStack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(mainStack)

		NSLayoutConstraint.activate([
			mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
			mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

			colorIndicator.widthAnchor.constraint(equalToConstant: 36),
			colorIndicator.heightAnchor.constraint(equalToConstant: 36)
		])
	}

	private func updateUI() {
		colorIndicator.backgroundColor = model.color
		titleLabel.text = model.title
		subtitleLabel.text = model.subtitle
		if let details = model.details {
			detailsLabel.text = details
			detailsLabel.isHidden = false
		} else {
			detailsLabel.text = nil
			detailsLabel.isHidden = true
		}
	}
}

// MARK: - HomeItemViewable

struct HomeItemViewable: CollectionViewable {
	typealias ViewType = HomeItemView

	let model: HomeItem

	func makeView() -> HomeItemView {
		HomeItemView(model)
	}
}
