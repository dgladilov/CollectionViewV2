//
//  CollectionItemBuilder.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - CollectionItemConvertible

protocol CollectionItemConvertible {
	func erasedToAnyItem() -> [AnyCollectionItem]
}

extension AnyCollectionItem: CollectionItemConvertible {
	func erasedToAnyItem() -> [AnyCollectionItem] { [self] }
}

extension Array: CollectionItemConvertible where Element == AnyCollectionItem {
	func erasedToAnyItem() -> [AnyCollectionItem] { self }
}

// MARK: - CollectionItemBuilder

@MainActor
@resultBuilder
struct CollectionItemBuilder {

	static func buildBlock(_ components: CollectionItemConvertible...) -> [AnyCollectionItem] {
		components.flatMap { $0.erasedToAnyItem() }
	}

	static func buildOptional(_ component: [AnyCollectionItem]?) -> [AnyCollectionItem] {
		component ?? []
	}

	static func buildEither(first component: [AnyCollectionItem]) -> [AnyCollectionItem] {
		component
	}

	static func buildEither(second component: [AnyCollectionItem]) -> [AnyCollectionItem] {
		component
	}

	static func buildArray(_ components: [[AnyCollectionItem]]) -> [AnyCollectionItem] {
		components.flatMap { $0 }
	}

	static func buildExpression<V: CollectionViewable>(_ expression: V) -> [AnyCollectionItem] {
		[AnyCollectionItem(expression)]
	}

	static func buildExpression(_ expression: AnyCollectionItem) -> [AnyCollectionItem] {
		[expression]
	}

	static func buildExpression(_ expression: [AnyCollectionItem]) -> [AnyCollectionItem] {
		expression
	}
}
