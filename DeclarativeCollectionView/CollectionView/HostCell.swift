//
//  HostCell.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// A generic UICollectionViewCell that hosts any ModelableView created by a Viewable.
/// The hosted view is created on first configure and reused (updated) on subsequent calls.
final class HostCell: UICollectionViewCell {

	private var hostedView: UIView?
	private var currentViewTypeId: ObjectIdentifier?

	override func prepareForReuse() {
		super.prepareForReuse()
		// Keep the hosted view for potential reuse — it will be updated in configure()
	}

	func configure(with item: AnyCollectionItem, updatable: Updatable?) {
		// If the hosted view type matches, just update the model
		if let existing = hostedView, currentViewTypeId == item.viewTypeId {
			item.updateView(existing)
			item.setUpdatable(existing, updatable: updatable)
			return
		}

		// Otherwise, create a new view
		hostedView?.removeFromSuperview()

		let view = item.makeView()
		view.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(view)

		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: contentView.topAnchor),
			view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])

		item.setUpdatable(view, updatable: updatable)
		hostedView = view
		currentViewTypeId = item.viewTypeId
	}
}
