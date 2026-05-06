//
//  CollectionItemable.swift
//  DeclarativeCollectionView
//

import UIKit

/// A Viewable whose Model is Identifiable — required for collection view items
/// so that DiffableDataSource can track identity across updates.
protocol CollectionItemable: Identifiable, Viewable {

	var onTap: (@MainActor @Sendable () -> Void)? { get }

	var onDisplay: (@MainActor @Sendable () -> Void)? { get }
	
	@MainActor func makeItem() -> AnyCollectionItem
}

extension CollectionItemable {

	var onTap: (@MainActor @Sendable () -> Void)? { nil }

	var onDisplay: (@MainActor @Sendable () -> Void)? { nil }
	
	@MainActor func makeItem() -> AnyCollectionItem {
		AnyCollectionItem(self)
	}
}
