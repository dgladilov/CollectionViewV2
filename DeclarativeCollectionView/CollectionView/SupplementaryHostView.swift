//
//  SupplementaryHostView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// A generic UICollectionReusableView that hosts any ModelableView
/// for supplementary views (headers, footers, custom supplementaries).
final class SupplementaryHostView: UICollectionReusableView {

	private var hostedView: UIView?

	func configure(with item: AnySupplementaryItem) {
		if let existing = hostedView {
			item.updateView(existing)
			return
		}

		let view = item.makeView()
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

	override func prepareForReuse() {
		super.prepareForReuse()
	}
}
