//
//  AnyCollectionItem.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - UniqueID

/// Универсальный идентификатор для секций и элементов коллекции.
///
/// Оборачивает произвольный `Hashable`-тип в строковое представление,
/// обеспечивая единый тип идентификатора для `DiffableDataSource`.
struct UniqueID: Hashable, Sendable {

	/// Строковое представление исходного идентификатора.
	let rawValue: String

	/// Создаёт идентификатор из произвольного `Hashable`-значения.
	/// - Parameter id: Исходный идентификатор (например `String`, `Int`, `UUID`).
	init<ID: Hashable>(_ id: ID) {
		self.rawValue = "\(id)"
	}
}

/// Псевдоним для идентификатора секции.
typealias SectionID = UniqueID

/// Псевдоним для идентификатора элемента.
typealias ItemID = UniqueID

// MARK: - AnyCollectionItem

/// Type-erased обёртка над любым `CollectionItemable`.
///
/// Стирает конкретный тип модели и вью, сохраняя возможность создавать,
/// обновлять вью и обрабатывать пользовательские события.
/// Используется как единица данных в `DiffableDataSource`.
struct AnyCollectionItem {

	/// Уникальный идентификатор элемента для `DiffableDataSource`.
	let itemID: ItemID

	/// Предпочтительный размер ячейки, заданный моделью.
	/// Значение `UIView.noIntrinsicMetric` по соответствующей оси означает автоматический расчёт.
	let preferredSize: CGSize

	/// Идентификатор типа вью (`ObjectIdentifier(ViewType.self)`).
	/// Используется для переиспользования ячеек: если тип совпадает — обновляем модель,
	/// иначе — создаём вью заново.
	let viewTypeId: ObjectIdentifier

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void

	/// Идентификатор секции, к которой принадлежит элемент.
	/// Устанавливается автоматически при добавлении в `CollectionSection`.
	private(set) var sectionID: SectionID?

	/// Замыкание, вызываемое при нажатии на ячейку.
	private(set) var onTap: (@MainActor () -> Void)?

	/// Замыкание, вызываемое при появлении ячейки на экране.
	private(set) var onDisplay: (@MainActor () -> Void)?

	/// Создаёт type-erased обёртку из конкретного `CollectionItemable`.
	/// - Parameter model: Модель элемента, реализующая `CollectionItemable`.
	@MainActor
	init<V: CollectionItemable>(_ model: V) where V.ViewType: ModelableView {
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
		self.onTap = model.onTap
		self.onDisplay = model.onDisplay
	}

	/// Создаёт новый экземпляр вью для этого элемента.
	@MainActor
	func makeView() -> UIView {
		_makeView()
	}

	/// Обновляет модель существующей вью без пересоздания.
	/// - Parameter view: Ранее созданная вью того же типа.
	@MainActor
	func updateView(_ view: UIView) {
		_updateView(view)
	}

	// MARK: - Fluent API

	/// Возвращает копию элемента с привязкой к указанной секции.
	/// - Parameter id: Идентификатор секции.
	func sectionID(_ id: SectionID) -> AnyCollectionItem {
		var copy = self
		copy.sectionID = id
		return copy
	}

	/// Возвращает копию элемента с обработчиком нажатия.
	/// - Parameter handler: Замыкание, вызываемое при нажатии.
	func onTap(_ handler: @escaping @MainActor () -> Void) -> AnyCollectionItem {
		var copy = self
		copy.onTap = handler
		return copy
	}

	/// Возвращает копию элемента с обработчиком появления на экране.
	/// - Parameter handler: Замыкание, вызываемое при появлении.
	func onDisplay(_ handler: @escaping @MainActor () -> Void) -> AnyCollectionItem {
		var copy = self
		copy.onDisplay = handler
		return copy
	}
}

// MARK: - AnySupplementaryItem

/// Type-erased обёртка для supplementary-вью (хедер, футер и пр.).
///
/// Аналогична `AnyCollectionItem`, но для дополнительных элементов секции.
struct AnySupplementaryItem {

	/// Тип supplementary-элемента (например `UICollectionView.elementKindSectionHeader`).
	let elementKind: String

	/// Предпочтительный размер supplementary-вью.
	let preferredSize: CGSize

	private let _makeView: @MainActor () -> UIView
	private let _updateView: @MainActor (UIView) -> Void

	/// Создаёт type-erased обёртку для supplementary-элемента.
	/// - Parameters:
	///   - elementKind: Тип supplementary (`elementKindSectionHeader`, `elementKindSectionFooter` и пр.).
	///   - viewable: Модель, реализующая `Viewable`.
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

	/// Создаёт новый экземпляр supplementary-вью.
	@MainActor
	func makeView() -> UIView {
		_makeView()
	}

	/// Обновляет модель существующей supplementary-вью без пересоздания.
	/// - Parameter view: Ранее созданная вью того же типа.
	@MainActor
	func updateView(_ view: UIView) {
		_updateView(view)
	}

}
