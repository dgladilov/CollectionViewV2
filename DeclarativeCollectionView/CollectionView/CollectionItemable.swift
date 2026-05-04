//
//  CollectionItemable.swift
//  DeclarativeCollectionView
//

import UIKit

/// A Viewable whose Model is Identifiable — required for collection view items
/// so that DiffableDataSource can track identity across updates.
protocol CollectionItemable: Identifiable, Viewable {
	
	var onTap: (@MainActor () -> Void)? { get }
	
	var onDisplay: (@MainActor () -> Void)? { get }
}

extension CollectionItemable {
	
	var onTap: (@MainActor () -> Void)? { nil }
	
	var onDisplay: (@MainActor () -> Void)? { nil }
}
