//
//  SectionBackgroundDecorationView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Decoration view that provides a configurable background for collection view sections.
/// Supports simple color+cornerRadius styling or hosting an arbitrary custom UIView.
final class SectionBackgroundDecorationView: UICollectionReusableView {

	static let elementKind = "section-background-decoration"

	private var hostedView: UIView?

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	func configure(with style: DecorationStyle) {
		// Clean up previous state
		hostedView?.removeFromSuperview()
		hostedView = nil
		backgroundColor = .clear
		layer.cornerRadius = 0
		layer.masksToBounds = false

		switch style {
		case .none:
			break

		case .custom(let factory):
			let view = factory()
			view.translatesAutoresizingMaskIntoConstraints = false
			addSubview(view)
			NSLayoutConstraint.activate([
				view.topAnchor.constraint(equalTo: topAnchor),
				view.leadingAnchor.constraint(equalTo: leadingAnchor),
				view.trailingAnchor.constraint(equalTo: trailingAnchor),
				view.bottomAnchor.constraint(equalTo: bottomAnchor)
			])
			hostedView = view
		}
	}

	override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)

		// Look up decoration config from the shared store
		guard let collectionView = findCollectionView() else { return }
		let sectionIndex = layoutAttributes.indexPath.section
		if let style = DecorationConfigStore.shared.config(for: collectionView, section: sectionIndex) {
			configure(with: style)
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		hostedView?.removeFromSuperview()
		hostedView = nil
		backgroundColor = .clear
		layer.cornerRadius = 0
		layer.masksToBounds = false
	}

	private func findCollectionView() -> UICollectionView? {
		var current: UIView? = superview
		while let view = current {
			if let cv = view as? UICollectionView {
				return cv
			}
			current = view.superview
		}
		return nil
	}
}
