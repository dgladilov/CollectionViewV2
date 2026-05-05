//
//  AnyCollectionItem.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - SectionID

/// A Sendable, Hashable identifier for collection sections.
struct SectionID: Hashable, Sendable {
	let rawValue: String

	init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}

// MARK: - ItemID

/// A Sendable, Hashable identifier for collection items.
/// Built from the model's `Identifiable.id` via string representation.
struct ItemID: Hashable, Sendable {
	private let value: String

	init<ID: Hashable>(_ id: ID) {
		self.value = "\(id)"
	}
}

// MARK: - AnyCollectionItem

/// Type-erased wrapper for any CollectionItemable.
struct AnyCollectionItem {

	let stableID: ItemID
	let preferredSize: CGSize
	let viewTypeId: ObjectIdentifier

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void
	private let _setUpdatable: @MainActor (UIView, Updatable?) -> Void

	/// Called when the item is tapped.
	let onTap: (@MainActor () -> Void)?
	/// Called when the cell becomes visible on screen.
	let onDisplay: (@MainActor () -> Void)?

	@MainActor
	init<V: CollectionItemable>(_ model: V) {
		self.stableID = ItemID(model.id)
		self.preferredSize = model.preferredSize
		self.viewTypeId = ObjectIdentifier(V.ViewType.self)

		let viewableCopy = model
		self._makeView = {
			viewableCopy.makeView()
		}
		self._updateView = { existingView in
			guard let typedView = existingView as? V.ViewType else { return }
			let newView = viewableCopy.makeView()
			typedView.model = newView.model
		}
		self._setUpdatable = { existingView, updatable in
			guard let typedView = existingView as? V.ViewType else { return }
			typedView.updatable = updatable
		}
		
		self.onTap = model.onTap
		self.onDisplay = model.onDisplay
	}

	@MainActor
	func makeView() -> UIView {
		_makeView()
	}

	@MainActor
	func updateView(_ view: UIView) {
		_updateView(view)
	}

	@MainActor
	func setUpdatable(_ view: UIView, updatable: Updatable?) {
		_setUpdatable(view, updatable)
	}
}

// MARK: - AnySupplementaryItem

/// Type-erased supplementary view descriptor (header, footer, etc.)
struct AnySupplementaryItem {

	let elementKind: String
	let preferredSize: CGSize

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void
	private let _setUpdatable: @MainActor (UIView, Updatable?) -> Void

	@MainActor
	init<V: Viewable>(elementKind: String, viewable: V) where V.ViewType: ModelableView {
		self.elementKind = elementKind
		self.preferredSize = viewable.preferredSize

		let viewableCopy = viewable
		self._makeView = {
			viewableCopy.makeView()
		}
		self._updateView = { view in
			guard let typedView = view as? V.ViewType else { return }
			let newView = viewableCopy.makeView()
			typedView.model = newView.model
		}
		self._setUpdatable = { view, updatable in
			guard let typedView = view as? V.ViewType else { return }
			typedView.updatable = updatable
		}
	}

	@MainActor
	func makeView() -> UIView {
		_makeView()
	}

	@MainActor
	func updateView(_ view: UIView) {
		_updateView(view)
	}

	@MainActor
	func setUpdatable(_ view: UIView, updatable: Updatable?) {
		_setUpdatable(view, updatable)
	}
}
