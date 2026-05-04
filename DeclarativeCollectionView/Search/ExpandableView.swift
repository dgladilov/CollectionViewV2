//
//  ExpandableView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - ExpandableView
struct ExpandableModel: Viewable, CollectionItemable {
	let id: String
	let title: String
	let color: UIColor
	var isExpanded: Bool
	
	typealias ViewType = ExpandableView

	var preferredSize: CGSize {
		let height: CGFloat = isExpanded ? 120 : 48
		return CGSize(width: UIView.noIntrinsicMetric, height: height)
	}

	func makeView() -> ExpandableView {
		ExpandableView(self)
	}
	
	var onTap: (@MainActor () -> Void)? {
		{
			print("onTap: \(id)")
		}
	}
	
	var onDisplay: (@MainActor () -> Void)? {
		{
			print("onDisplay: \(id)")
		}
	}
}

final class ExpandableView: UIView, ModelableView {


	var model: ExpandableModel {
		didSet { updateUI() }
	}

	var updatable: Updatable?

	private let titleLabel = UILabel()
	private let chevronImageView = UIImageView()
	private let colorBar = UIView()
	private let detailLabel = UILabel()
	private var heightConstraint: NSLayoutConstraint!

	required init(_ model: ExpandableModel) {
		self.model = model
		super.init(frame: .zero)
		setupUI()
		updateUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupUI() {
		colorBar.layer.cornerRadius = 6
		colorBar.layer.masksToBounds = true
		colorBar.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false

		chevronImageView.tintColor = .secondaryLabel
		chevronImageView.contentMode = .scaleAspectFit
		chevronImageView.translatesAutoresizingMaskIntoConstraints = false

		detailLabel.font = .systemFont(ofSize: 14)
		detailLabel.textColor = .secondaryLabel
		detailLabel.numberOfLines = 0
		detailLabel.text = "This is the expanded content area. It demonstrates how updatable can be used to change the cell height dynamically by toggling the expanded state from within the cell itself."
		detailLabel.translatesAutoresizingMaskIntoConstraints = false

		let headerStack = UIStackView(arrangedSubviews: [colorBar, titleLabel, chevronImageView])
		headerStack.axis = .horizontal
		headerStack.spacing = 12
		headerStack.alignment = .center
		headerStack.translatesAutoresizingMaskIntoConstraints = false

		addSubview(headerStack)
		addSubview(detailLabel)

		heightConstraint = heightAnchor.constraint(equalToConstant: 48)
		heightConstraint.priority = .defaultHigh

		NSLayoutConstraint.activate([
			headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
			headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

			colorBar.widthAnchor.constraint(equalToConstant: 12),
			colorBar.heightAnchor.constraint(equalToConstant: 12),

			chevronImageView.widthAnchor.constraint(equalToConstant: 16),
			chevronImageView.heightAnchor.constraint(equalToConstant: 16),

			detailLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
			detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
			detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

			heightConstraint
		])

		let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		addGestureRecognizer(tap)
	}

	@objc private func handleTap() {
		model.isExpanded.toggle()
		updatable?.update(animated: true)
	}

	private func updateUI() {
		colorBar.backgroundColor = model.color
		titleLabel.text = model.title

		let chevronName = model.isExpanded ? "chevron.up" : "chevron.down"
		chevronImageView.image = UIImage(systemName: chevronName)

		detailLabel.isHidden = !model.isExpanded
		heightConstraint.constant = model.isExpanded ? 120 : 48
	}
}
