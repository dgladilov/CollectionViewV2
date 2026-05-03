//
//  CollectionSectionBuilder.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import Foundation

// MARK: - CollectionSectionConvertible

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
