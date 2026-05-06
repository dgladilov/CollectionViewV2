//
//  AnyCollectionItem.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - UniqueID

/// A universal Sendable, Hashable identifier used for both sections and items.
struct UniqueID: Hashable, Sendable {
	let rawValue: String

	init<ID: Hashable>(_ id: ID) {
		self.rawValue = "\(id)"
	}
}

typealias SectionID = UniqueID
typealias ItemID = UniqueID

// MARK: - AnyCollectionItem

/// Type-erased wrapper for any CollectionItemable.
struct AnyCollectionItem {

	let itemID: ItemID
	let preferredSize: CGSize
	let viewTypeId: ObjectIdentifier

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void
	private let _setUpdatable: @MainActor (UIView, Updatable?) -> Void

	/// The section this item belongs to. Set automatically by `CollectionSection`.
	private(set) var sectionID: SectionID?
	/// Called when the item is tapped.
	private(set) var onTap: (@MainActor () -> Void)?
	/// Called when the cell becomes visible on screen.
	private(set) var onDisplay: (@MainActor () -> Void)?

	@MainActor
	init<V: CollectionItemable>(_ model: V) {
		self.itemID = ItemID(model.id)
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

	// MARK: - Fluent API

	func sectionID(_ id: SectionID) -> AnyCollectionItem {
		var copy = self
		copy.sectionID = id
		return copy
	}

	func onTap(_ handler: @escaping @MainActor () -> Void) -> AnyCollectionItem {
		var copy = self
		copy.onTap = handler
		return copy
	}

	func onDisplay(_ handler: @escaping @MainActor () -> Void) -> AnyCollectionItem {
		var copy = self
		copy.onDisplay = handler
		return copy
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
