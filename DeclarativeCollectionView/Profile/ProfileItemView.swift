//
//  ProfileItemView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - ProfileItem

struct ProfileItem: Identifiable, Viewable, CollectionItemable {
	let id: String
	let icon: String
	let iconColor: UIColor
	let title: String
	let subtitle: String?
	let hasChevron: Bool

	typealias ViewType = ProfileItemView

	func makeView() -> ProfileItemView {
		ProfileItemView(self)
	}
}

// MARK: - ProfileItemView

final class ProfileItemView: UIView, ModelableView {

	var model: ProfileItem {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let iconContainer = UIView()
	private let iconImageView = UIImageView()
	private let titleLabel = UILabel()
	private let subtitleLabel = UILabel()
	private let chevronImageView = UIImageView()

	required init(_ model: ProfileItem) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
		updateUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		iconContainer.layer.cornerRadius = 6
		iconContainer.layer.masksToBounds = true
		iconContainer.translatesAutoresizingMaskIntoConstraints = false

		iconImageView.contentMode = .scaleAspectFit
		iconImageView.tintColor = .white
		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconContainer.addSubview(iconImageView)

		titleLabel.font = .systemFont(ofSize: 16)

		subtitleLabel.font = .systemFont(ofSize: 14)
		subtitleLabel.textColor = .secondaryLabel

		chevronImageView.image = UIImage(systemName: "chevron.right")
		chevronImageView.tintColor = .tertiaryLabel
		chevronImageView.contentMode = .scaleAspectFit
		chevronImageView.translatesAutoresizingMaskIntoConstraints = false
		chevronImageView.setContentHuggingPriority(.required, for: .horizontal)

		let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
		textStack.axis = .vertical
		textStack.spacing = 2

		let mainStack = UIStackView(arrangedSubviews: [iconContainer, textStack, chevronImageView])
		mainStack.axis = .horizontal
		mainStack.spacing = 12
		mainStack.alignment = .center
		mainStack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(mainStack)

		NSLayoutConstraint.activate([
			iconContainer.widthAnchor.constraint(equalToConstant: 30),
			iconContainer.heightAnchor.constraint(equalToConstant: 30),

			iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
			iconImageView.widthAnchor.constraint(equalToConstant: 18),
			iconImageView.heightAnchor.constraint(equalToConstant: 18),

			chevronImageView.widthAnchor.constraint(equalToConstant: 12),
			chevronImageView.heightAnchor.constraint(equalToConstant: 16),

			mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
			mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
		])
	}

	private func updateUI() {
		iconContainer.backgroundColor = model.iconColor
		iconImageView.image = UIImage(systemName: model.icon)
		titleLabel.text = model.title
		if let subtitle = model.subtitle {
			subtitleLabel.text = subtitle
			subtitleLabel.isHidden = false
		} else {
			subtitleLabel.isHidden = true
		}
		chevronImageView.isHidden = !model.hasChevron
	}
}
