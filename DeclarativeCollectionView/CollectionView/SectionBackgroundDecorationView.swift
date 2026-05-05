//
//  SectionBackgroundDecorationView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Decoration view that provides a configurable background for collection view sections.
/// Hosts an arbitrary custom UIView provided via a factory closure.
/// Queries its `DecorationProvider` (the owning CollectionView) to get the style.
final class SectionBackgroundDecorationView: UICollectionReusableView {

	static let elementKind = "section-background-decoration"

	private var hostedView: UIView?
	private var configuredSectionIndex: Int?

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)

		let sectionIndex = layoutAttributes.indexPath.section

		// Skip reconfiguration if already set up for this section
		if configuredSectionIndex == sectionIndex, hostedView != nil {
			return
		}

		guard let provider = findDecorationProvider() else { return }
		let style = provider.decorationStyle(forSection: sectionIndex)
		configure(with: style)
		configuredSectionIndex = sectionIndex
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		hostedView?.removeFromSuperview()
		hostedView = nil
		configuredSectionIndex = nil
		backgroundColor = .clear
	}

	private func configure(with style: DecorationStyle) {
		hostedView?.removeFromSuperview()
		hostedView = nil
		backgroundColor = .clear

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

	private func findDecorationProvider() -> DecorationProvider? {
		var current: UIView? = superview
		while let view = current {
			if let provider = view.superview as? DecorationProvider {
				return provider
			}
			current = view.superview
		}
		return nil
	}
}
