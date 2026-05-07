//
//  CollectionItemable.swift
//  DeclarativeCollectionView
//

import UIKit

/// Протокол элемента коллекции.
///
/// Расширяет `Viewable` требованием `Identifiable`, чтобы `DiffableDataSource`
/// мог отслеживать идентичность элементов при обновлениях.
///
/// Для большинства случаев достаточно реализовать только `Identifiable` и `Viewable` —
/// остальное предоставляется реализацией по умолчанию.
protocol CollectionItemable: Identifiable, Viewable {

	/// Замыкание, вызываемое при нажатии на ячейку. По умолчанию `nil`.
	var onTap: (@MainActor @Sendable () -> Void)? { get }

	/// Замыкание, вызываемое при появлении ячейки на экране. По умолчанию `nil`.
	var onDisplay: (@MainActor @Sendable () -> Void)? { get }

	/// Создаёт type-erased обёртку `AnyCollectionItem` из данной модели.
	/// По умолчанию вызывает `AnyCollectionItem(self)`.
	@MainActor func makeItem() -> AnyCollectionItem
}

extension CollectionItemable {

	var onTap: (@MainActor @Sendable () -> Void)? { nil }

	var onDisplay: (@MainActor @Sendable () -> Void)? { nil }

	@MainActor func makeItem() -> AnyCollectionItem {
		AnyCollectionItem(self)
	}
}
