//
//  CollectionSectionBuilder.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import Foundation

// MARK: - CollectionSectionConvertible

/// Внутренний протокол для приведения различных типов к массиву `CollectionSection`.
///
/// Используется `CollectionSectionBuilder`-ом для поддержки как одиночных секций,
/// так и массивов в декларативном DSL.
protocol CollectionSectionConvertible {
	func asCollectionSections() -> [CollectionSection]
}

extension CollectionSection: CollectionSectionConvertible {
	func asCollectionSections() -> [CollectionSection] { [self] }
}

extension Array: CollectionSectionConvertible where Element == CollectionSection {
	func asCollectionSections() -> [CollectionSection] { self }
}

// MARK: - CollectionSectionBuilder

/// Result builder для декларативного описания секций коллекции.
///
/// Позволяет описывать содержимое коллекции в DSL-стиле:
/// ```swift
/// collectionView.send {
///     CollectionSection(id: "top", layout: .plain) { ... }
///     CollectionSection(id: "bottom", layout: .insetGrouped) { ... }
/// }
/// ```
///
/// Поддерживает `if/else`, `Optional`, `for...in` и вложенные массивы.
@MainActor
@resultBuilder
struct CollectionSectionBuilder {

	static func buildBlock(_ components: CollectionSectionConvertible...) -> [CollectionSection] {
		components.flatMap { $0.asCollectionSections() }
	}

	static func buildOptional(_ component: [CollectionSection]?) -> [CollectionSection] {
		component ?? []
	}

	static func buildEither(first component: [CollectionSection]) -> [CollectionSection] {
		component
	}

	static func buildEither(second component: [CollectionSection]) -> [CollectionSection] {
		component
	}

	static func buildArray(_ components: [[CollectionSection]]) -> [CollectionSection] {
		components.flatMap { $0 }
	}

	static func buildExpression(_ expression: CollectionSection) -> [CollectionSection] {
		[expression]
	}

	static func buildExpression(_ expression: [CollectionSection]) -> [CollectionSection] {
		expression
	}
}
