//
//  CollectionItemBuilder.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - CollectionItemConvertible

/// Внутренний протокол для приведения различных типов к массиву `AnyCollectionItem`.
///
/// Используется `CollectionItemBuilder`-ом для поддержки как одиночных элементов,
/// так и массивов в декларативном DSL.
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

/// Result builder для декларативного описания элементов секции.
///
/// Позволяет описывать содержимое секции в DSL-стиле:
/// ```swift
/// CollectionSection(id: "main", layout: .plain) {
///     ItemModel(id: "1", title: "Первый")
///     ItemModel(id: "2", title: "Второй")
///     if showThird {
///         ItemModel(id: "3", title: "Третий")
///     }
/// }
/// ```
///
/// Поддерживает `if/else`, `Optional`, `for...in` и вложенные массивы.
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

	static func buildExpression<V: CollectionItemable>(_ expression: V) -> [AnyCollectionItem] where V.ViewType: ModelableView {
		[AnyCollectionItem(expression)]
	}

	static func buildExpression<V: CollectionItemable>(_ expression: [V]) -> [AnyCollectionItem] where V.ViewType: ModelableView {
		expression.map { AnyCollectionItem($0) }
	}

	static func buildExpression(_ expression: AnyCollectionItem) -> [AnyCollectionItem] {
		[expression]
	}

	static func buildExpression(_ expression: [AnyCollectionItem]) -> [AnyCollectionItem] {
		expression
	}
}
