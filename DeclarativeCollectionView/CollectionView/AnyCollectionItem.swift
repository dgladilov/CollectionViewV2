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

// MARK: - StableItemID

/// A Sendable, Hashable identifier for collection items.
/// Built from the model's `Identifiable.id` via string representation.
struct StableItemID: Hashable, Sendable {
	private let value: String

	init<ID: Hashable>(_ id: ID) {
		self.value = "\(id)"
	}
}

// MARK: - CollectionViewable

/// A Viewable whose Model is Identifiable — required for collection view items
/// so that DiffableDataSource can track identity across updates.
protocol CollectionViewable: Viewable where ViewType: ModelableView, ViewType.Model: Identifiable {}

// MARK: - AnyCollectionItem

/// Type-erased wrapper for any CollectionViewable.
struct AnyCollectionItem {

	let stableID: StableItemID
	let preferredSize: CGSize
	let viewTypeId: ObjectIdentifier

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void

	@MainActor
	init<V: CollectionViewable>(_ viewable: V) {
		let view = viewable.makeView()
		self.stableID = StableItemID(view.model.id)
		self.preferredSize = viewable.preferredSize
		self.viewTypeId = ObjectIdentifier(V.ViewType.self)

		let viewableCopy = viewable
		self._makeView = {
			viewableCopy.makeView()
		}
		self._updateView = { existingView in
			guard let typedView = existingView as? V.ViewType else { return }
			let newView = viewableCopy.makeView()
			typedView.model = newView.model
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
}

// MARK: - AnySupplementaryItem

/// Type-erased supplementary view descriptor (header, footer, etc.)
struct AnySupplementaryItem {

	let elementKind: String
	let preferredSize: CGSize

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void

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
	}

	@MainActor
	func makeView() -> UIView {
		_makeView()
	}

	@MainActor
	func updateView(_ view: UIView) {
		_updateView(view)
	}
}
