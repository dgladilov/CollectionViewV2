//
//  ProfileHeaderView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - ProfileHeader

struct ProfileHeader: Identifiable, Viewable, CollectionItemable {
	let id: String
	let name: String
	let email: String
	let avatarColor: UIColor

	typealias ViewType = ProfileHeaderView

	func makeView() -> ProfileHeaderView {
		ProfileHeaderView(self)
	}
}

// MARK: - ProfileHeaderView

final class ProfileHeaderView: UIView, ModelableView {

	var model: ProfileHeader {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let avatarView = UIView()
	private let initialsLabel = UILabel()
	private let nameLabel = UILabel()
	private let emailLabel = UILabel()

	required init(_ model: ProfileHeader) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
		updateUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		avatarView.layer.cornerRadius = 35
		avatarView.layer.masksToBounds = true
		avatarView.translatesAutoresizingMaskIntoConstraints = false

		initialsLabel.font = .systemFont(ofSize: 28, weight: .medium)
		initialsLabel.textColor = .white
		initialsLabel.textAlignment = .center
		initialsLabel.translatesAutoresizingMaskIntoConstraints = false
		avatarView.addSubview(initialsLabel)

		nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
		nameLabel.textAlignment = .center

		emailLabel.font = .systemFont(ofSize: 14)
		emailLabel.textColor = .secondaryLabel
		emailLabel.textAlignment = .center

		let textStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
		textStack.axis = .vertical
		textStack.spacing = 4
		textStack.alignment = .center

		let mainStack = UIStackView(arrangedSubviews: [avatarView, textStack])
		mainStack.axis = .vertical
		mainStack.spacing = 12
		mainStack.alignment = .center
		mainStack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(mainStack)

		NSLayoutConstraint.activate([
			avatarView.widthAnchor.constraint(equalToConstant: 70),
			avatarView.heightAnchor.constraint(equalToConstant: 70),

			initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
			initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

			mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
			mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
		])
	}

	private func updateUI() {
		avatarView.backgroundColor = model.avatarColor
		let initials = model.name
			.split(separator: " ")
			.prefix(2)
			.compactMap { $0.first.map(String.init) }
			.joined()
		initialsLabel.text = initials
		nameLabel.text = model.name
		emailLabel.text = model.email
	}
}
