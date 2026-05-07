//
//  CollectionSection.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - SectionLayout

/// Описание layout-а секции коллекции.
///
/// Стандартные кейсы соответствуют вариантам `UICollectionLayoutListConfiguration.Appearance`.
/// Для нестандартных layout-ов используйте `.custom(...)`.
enum SectionLayout: Sendable {
	/// Плоский список (`UICollectionLayoutListConfiguration.Appearance.plain`).
	case plain
	/// Сгруппированный список с отступами (`UICollectionLayoutListConfiguration.Appearance.insetGrouped`).
	case insetGrouped
	/// Сгруппированный список (`UICollectionLayoutListConfiguration.Appearance.grouped`).
	case grouped
	/// Боковая панель (`UICollectionLayoutListConfiguration.Appearance.sidebar`).
	case sidebar
	/// Плоская боковая панель (`UICollectionLayoutListConfiguration.Appearance.sidebarPlain`).
	case sidebarPlain
	/// Произвольный layout, задаваемый замыканием.
	/// - Parameter closure: Принимает `NSCollectionLayoutEnvironment`, возвращает `NSCollectionLayoutSection`.
	case custom(@MainActor @Sendable (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)

	/// Создаёт `NSCollectionLayoutSection` на основе выбранного кейса.
	/// - Parameter environment: Контекст layout-а (размеры контейнера, trait collection).
	/// - Returns: Готовый layout секции.
	@MainActor func makeLayoutSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
		switch self {
		case .plain:
			var config = UICollectionLayoutListConfiguration(appearance: .plain)
			config.showsSeparators = false
			return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

		case .insetGrouped:
			var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
			config.showsSeparators = false
			return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

		case .grouped:
			var config = UICollectionLayoutListConfiguration(appearance: .grouped)
			config.showsSeparators = false
			return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

		case .sidebar:
			var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
			config.showsSeparators = false
			return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

		case .sidebarPlain:
			var config = UICollectionLayoutListConfiguration(appearance: .sidebarPlain)
			config.showsSeparators = false
			return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)

		case .custom(let provider):
			return provider(environment)
		}
	}
}

// MARK: - DecorationStyle

/// Стиль декоративного фона секции.
enum DecorationStyle {
	/// Без декоративного фона.
	case none
	/// Произвольная вью в качестве фона, создаваемая замыканием.
	case custom(@MainActor () -> UIView)
}

// MARK: - CollectionSection

/// Описание одной секции коллекции: layout, элементы, хедер, футер и декорация.
///
/// Секция создаётся с уникальным `id` и набором элементов.
/// Дополнительные параметры (хедер, футер, декорация, отступы) задаются через fluent API:
/// ```swift
/// CollectionSection(id: "news", layout: .plain) {
///     NewsItem(id: "1", title: "Заголовок")
/// }
/// .header(NewsHeaderModel())
/// .insets(NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
/// ```
struct CollectionSection: Sendable {

	/// Уникальный идентификатор секции.
	let id: SectionID

	/// Layout секции.
	let layout: SectionLayout

	/// Массив type-erased элементов секции.
	let items: [AnyCollectionItem]

	/// Хедер секции. Задаётся через `.header(...)`.
	var header: AnySupplementaryItem?

	/// Футер секции. Задаётся через `.footer(...)`.
	var footer: AnySupplementaryItem?

	/// Дополнительные supplementary-вью (кроме хедера и футера).
	var supplementaries: [AnySupplementaryItem]

	/// Стиль декоративного фона.
	var decoration: DecorationStyle

	/// Отступы содержимого секции.
	var contentInsets: NSDirectionalEdgeInsets

	/// Создаёт секцию с декларативным билдером элементов.
	/// - Parameters:
	///   - id: Уникальный строковый идентификатор секции.
	///   - layout: Layout секции.
	///   - decoration: Стиль декоративного фона (по умолчанию `.none`).
	///   - contentInsets: Отступы содержимого (по умолчанию `.zero`).
	///   - items: Билдер элементов (`@CollectionItemBuilder`).
	@MainActor init(
		id: String,
		layout: SectionLayout,
		decoration: DecorationStyle = .none,
		contentInsets: NSDirectionalEdgeInsets = .zero,
		@CollectionItemBuilder items: () -> [AnyCollectionItem]
	) {
		let sectionID = SectionID(id)
		self.id = sectionID
		self.layout = layout
		self.items = items().map { $0.sectionID == nil ? $0.sectionID(sectionID) : $0 }
		self.header = nil
		self.footer = nil
		self.supplementaries = []
		self.decoration = decoration
		self.contentInsets = contentInsets
	}

	/// Создаёт секцию из готового массива `AnyCollectionItem`.
	/// - Parameters:
	///   - id: Уникальный строковый идентификатор секции.
	///   - layout: Layout секции.
	///   - decoration: Стиль декоративного фона (по умолчанию `.none`).
	///   - contentInsets: Отступы содержимого (по умолчанию `.zero`).
	///   - items: Массив type-erased элементов.
	@MainActor init(
		id: String,
		layout: SectionLayout,
		decoration: DecorationStyle = .none,
		contentInsets: NSDirectionalEdgeInsets = .zero,
		items: [AnyCollectionItem]
	) {
		let sectionID = SectionID(id)
		self.id = sectionID
		self.layout = layout
		self.items = items.map { $0.sectionID == nil ? $0.sectionID(sectionID) : $0 }
		self.header = nil
		self.footer = nil
		self.supplementaries = []
		self.decoration = decoration
		self.contentInsets = contentInsets
	}

	/// Создаёт секцию из массива `CollectionItemable` без ручной обёртки в `AnyCollectionItem`.
	/// - Parameters:
	///   - id: Уникальный строковый идентификатор секции.
	///   - layout: Layout секции.
	///   - decoration: Стиль декоративного фона (по умолчанию `.none`).
	///   - contentInsets: Отступы содержимого (по умолчанию `.zero`).
	///   - items: Массив моделей, реализующих `CollectionItemable`.
	@MainActor init(
		id: String,
		layout: SectionLayout,
		decoration: DecorationStyle = .none,
		contentInsets: NSDirectionalEdgeInsets = .zero,
		items: [any CollectionItemable]
	) {
		let sectionID = SectionID(id)
		self.id = sectionID
		self.layout = layout
		self.items = items.map { $0.makeItem().sectionID(sectionID) }
		self.header = nil
		self.footer = nil
		self.supplementaries = []
		self.decoration = decoration
		self.contentInsets = contentInsets
	}

	// MARK: - Fluent API

	/// Возвращает копию секции с хедером.
	/// - Parameter viewable: Модель хедера, реализующая `Viewable`.
	@MainActor
	func header<V: Viewable>(_ viewable: V) -> CollectionSection {
		var copy = self
		copy.header = AnySupplementaryItem(
			elementKind: UICollectionView.elementKindSectionHeader,
			viewable: viewable
		)
		return copy
	}

	/// Возвращает копию секции с футером.
	/// - Parameter viewable: Модель футера, реализующая `Viewable`.
	@MainActor
	func footer<V: Viewable>(_ viewable: V) -> CollectionSection {
		var copy = self
		copy.footer = AnySupplementaryItem(
			elementKind: UICollectionView.elementKindSectionFooter,
			viewable: viewable
		)
		return copy
	}

	/// Возвращает копию секции с дополнительным supplementary-элементом.
	/// - Parameters:
	///   - kind: Строковый идентификатор типа supplementary.
	///   - viewable: Модель supplementary, реализующая `Viewable`.
	@MainActor
	func supplementary<V: Viewable>(kind: String, _ viewable: V) -> CollectionSection {
		var copy = self
		copy.supplementaries.append(
			AnySupplementaryItem(elementKind: kind, viewable: viewable)
		)
		return copy
	}

	/// Возвращает копию секции с указанным стилем декоративного фона.
	/// - Parameter style: Стиль декорации.
	func decoration(_ style: DecorationStyle) -> CollectionSection {
		var copy = self
		copy.decoration = style
		return copy
	}

	/// Возвращает копию секции с указанными отступами содержимого.
	/// - Parameter insets: Отступы.
	func insets(_ insets: NSDirectionalEdgeInsets) -> CollectionSection {
		var copy = self
		copy.contentInsets = insets
		return copy
	}
}
