//
//  CollectionView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - DecorationProvider

/// Протокол для получения стиля декоративного фона секции.
///
/// Реализуется `CollectionView`, чтобы `SectionBackgroundDecorationView`
/// мог запросить стиль декорации без глобального состояния.
@MainActor
protocol DecorationProvider: AnyObject {

	/// Возвращает стиль декорации для секции по индексу.
	/// - Parameter index: Индекс секции.
	func decorationStyle(forSection index: Int) -> DecorationStyle
}

/// Декларативная коллекция на основе `UICollectionViewCompositionalLayout` и `DiffableDataSource`.
///
/// Управляет секциями через внутренний `SectionsSource`. Для изменения содержимого
/// используйте методы `send`, `append`, `insert`, `remove`, `update` и другие.
/// Коллекция автоматически обновляется при каждом изменении.
///
/// ```swift
/// let collectionView = CollectionView {
///     CollectionSection(id: "main", layout: .plain) {
///         ItemModel(id: "1", title: "Привет")
///     }
/// }
/// ```
final class CollectionView: UICollectionView, Updatable {

	// MARK: - Properties

	private let sectionsSource = SectionsSource()
	private var diffableDataSource: UICollectionViewDiffableDataSource<SectionID, ItemID>?
	private var itemLookup: [ItemID: AnyCollectionItem] = [:]
	private var streamTask: Task<Void, Never>?
	private var animateUpdates = true
	/// Tracks currently visible items per section to detect appearance/disappearance transitions.
	private var visibleItemsBySection: [Int: Set<Int>] = [:]

	// MARK: - Initializers

	override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
		super.init(frame: frame, collectionViewLayout: layout)
		commonInit()
	}

	/// Создаёт коллекцию с пустым содержимым.
	init() {
		let layout = Self.makeInitialLayout()
		super.init(frame: .zero, collectionViewLayout: layout)
		commonInit()
	}

	/// Создаёт коллекцию с начальным набором секций, заданных через декларативный билдер.
	/// - Parameter builder: Билдер секций (`@CollectionSectionBuilder`).
	convenience init(@CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		self.init()
		send(builder())
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}

	deinit {
		streamTask?.cancel()
	}

	// MARK: - Common Init

	private func commonInit() {
		translatesAutoresizingMaskIntoConstraints = false
		backgroundColor = .systemBackground
		delegate = self

		setupDataSource()
		installSectionProviderLayout()

		streamTask = Task { [weak self, stream = sectionsSource.stream] in
			for await _ in stream {
				guard let self else { return }
				self.apply(sections: self.sectionsSource.current, animated: self.animateUpdates)
			}
		}
	}

	// MARK: - Публичный API (секции)

	/// Текущий массив секций.
	var sections: [CollectionSection] { sectionsSource.current }

	/// Заменяет все секции переданным массивом.
	/// - Parameter sections: Новый массив секций.
	func send(_ sections: [CollectionSection]) {
		sectionsSource.send(sections)
	}

	/// Заменяет все секции с помощью декларативного билдера.
	/// - Parameter builder: Билдер секций.
	func send(@CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		sectionsSource.send(builder)
	}

	/// Добавляет секцию в конец.
	/// - Parameter section: Секция для добавления.
	func append(_ section: CollectionSection) {
		sectionsSource.append(section)
	}

	/// Добавляет несколько секций в конец.
	/// - Parameter sections: Массив секций.
	func append(contentsOf sections: [CollectionSection]) {
		sectionsSource.append(contentsOf: sections)
	}

	/// Вставляет секцию по индексу.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - index: Позиция вставки.
	func insert(_ section: CollectionSection, at index: Int) {
		sectionsSource.insert(section, at: index)
	}

	/// Вставляет секцию после секции с указанным `id`.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - sectionID: Идентификатор секции, после которой вставлять.
	func insert(_ section: CollectionSection, after sectionID: String) {
		sectionsSource.insert(section, after: sectionID)
	}

	/// Вставляет секцию перед секцией с указанным `id`.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - sectionID: Идентификатор секции, перед которой вставлять.
	func insert(_ section: CollectionSection, before sectionID: String) {
		sectionsSource.insert(section, before: sectionID)
	}

	/// Удаляет секцию с указанным `id`.
	/// - Parameter sectionID: Строковый идентификатор секции.
	/// - Returns: Удалённая секция, или `nil` если не найдена.
	@discardableResult
	func remove(sectionID: String) -> CollectionSection? {
		sectionsSource.remove(sectionID: sectionID)
	}

	/// Удаляет секцию по индексу.
	/// - Parameter index: Индекс секции.
	/// - Returns: Удалённая секция.
	@discardableResult
	func remove(at index: Int) -> CollectionSection {
		sectionsSource.remove(at: index)
	}

	/// Удаляет все секции.
	func removeAll() {
		sectionsSource.removeAll()
	}

	/// Заменяет секцию с совпадающим `id`.
	/// - Parameter section: Новая секция.
	func update(_ section: CollectionSection) {
		sectionsSource.update(section)
	}

	/// Мутирует секцию с указанным `id` через замыкание.
	/// - Parameters:
	///   - sectionID: Строковый идентификатор секции.
	///   - transform: Замыкание для мутации секции.
	func update(sectionID: String, _ transform: (inout CollectionSection) -> Void) {
		sectionsSource.update(sectionID: sectionID, transform)
	}

	/// Выполняет несколько мутаций в одном батче.
	/// Промежуточные обновления подавляются, публикуется только одно в конце.
	/// - Parameter mutations: Замыкание с мутациями.
	func batch(_ mutations: (CollectionView) -> Void) {
		sectionsSource.batch { _ in
			mutations(self)
		}
	}

	/// Возвращает секцию с указанным `id`, или `nil`.
	/// - Parameter id: Строковый идентификатор секции.
	func section(id: String) -> CollectionSection? {
		sectionsSource.section(id: id)
	}

	/// Возвращает индекс секции с указанным `id`, или `nil`.
	/// - Parameter sectionID: Строковый идентификатор секции.
	func index(of sectionID: String) -> Int? {
		sectionsSource.index(of: sectionID)
	}

	/// Полностью перезагружает коллекцию с новым набором секций.
	/// - Parameters:
	///   - animated: Анимировать ли обновление (по умолчанию `true`).
	///   - builder: Билдер секций.
	func reload(animated: Bool = true, @CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		animateUpdates = animated
		send(builder())
		animateUpdates = true
	}

	/// Инвалидирует layout всей коллекции целиком.
	///
	/// Реализация `Updatable`. Используется как fallback, когда нужен полный пересчёт.
	/// Для точечной инвалидации одной секции используйте `updateSection(at:animated:)`.
	/// - Parameter animated: Анимировать ли обновление.
	func update(animated: Bool) {
		if animated {
			performBatchUpdates(nil)
		} else {
			collectionViewLayout.invalidateLayout()
		}
	}

	/// Инвалидирует layout только указанной секции.
	///
	/// Пересчитывает размеры ячеек только в одной секции, не затрагивая остальные.
	/// Если индекс выходит за границы — выполняется полная инвалидация через `update(animated:)`.
	/// - Parameters:
	///   - sectionIndex: Индекс секции.
	///   - animated: Анимировать ли обновление.
	func updateSection(at sectionIndex: Int, animated: Bool) {
		guard sectionIndex < numberOfSections else {
			update(animated: animated)
			return
		}

		let itemCount = numberOfItems(inSection: sectionIndex)
		let indexPaths = (0..<itemCount).map { IndexPath(item: $0, section: sectionIndex) }
		let context = UICollectionViewLayoutInvalidationContext()
		context.invalidateItems(at: indexPaths)

		if animated {
			performBatchUpdates {
				self.collectionViewLayout.invalidateLayout(with: context)
			}
		} else {
			collectionViewLayout.invalidateLayout(with: context)
		}
	}

	// MARK: - Data Source Setup

	private func setupDataSource() {
		let cellRegistration = UICollectionView.CellRegistration<CollectionItemCell, ItemID> { [weak self] cell, _, itemID in
			guard let self, let item = self.itemLookup[itemID] else { return }
			cell.configure(with: item)
		}

		diffableDataSource = UICollectionViewDiffableDataSource<SectionID, ItemID>(
			collectionView: self
		) { collectionView, indexPath, itemID in
			collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemID)
		}

		let headerRegistration = UICollectionView.SupplementaryRegistration<SupplementaryHostView>(
			elementKind: UICollectionView.elementKindSectionHeader
		) { [weak self] supplementaryView, _, indexPath in
			guard let self,
				  indexPath.section < self.sectionsSource.current.count,
				  let header = self.sectionsSource.current[indexPath.section].header else { return }
			supplementaryView.configure(with: header)
		}

		let footerRegistration = UICollectionView.SupplementaryRegistration<SupplementaryHostView>(
			elementKind: UICollectionView.elementKindSectionFooter
		) { [weak self] supplementaryView, _, indexPath in
			guard let self,
				  indexPath.section < self.sectionsSource.current.count,
				  let footer = self.sectionsSource.current[indexPath.section].footer else { return }
			supplementaryView.configure(with: footer)
		}

		diffableDataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case UICollectionView.elementKindSectionHeader:
				return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
			case UICollectionView.elementKindSectionFooter:
				return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
			default:
				return nil
			}
		}
	}

	// MARK: - Layout

	private static func makeInitialLayout() -> UICollectionViewCompositionalLayout {
		let layout = UICollectionViewCompositionalLayout { _, _ in
			makeDefaultSection()
		}
		layout.register(
			SectionBackgroundDecorationView.self,
			forDecorationViewOfKind: SectionBackgroundDecorationView.elementKind
		)
		return layout
	}

	/// Installs the real section-provider layout that reads from `sectionsSource.current`.
	/// Called once after init. The layout persists for the view's lifetime.
	private func installSectionProviderLayout() {
		let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
			guard let self, sectionIndex < self.sectionsSource.current.count else {
				return Self.makeDefaultSection()
			}
			let section = self.sectionsSource.current[sectionIndex]
			return self.makeLayoutSection(for: section, environment: environment)
		}
		layout.register(
			SectionBackgroundDecorationView.self,
			forDecorationViewOfKind: SectionBackgroundDecorationView.elementKind
		)
		setCollectionViewLayout(layout, animated: false)
	}

	private func makeLayoutSection(
		for section: CollectionSection,
		environment: NSCollectionLayoutEnvironment
	) -> NSCollectionLayoutSection {
		let layoutSection = section.layout.makeLayoutSection(environment: environment)

		// Content insets
		if section.contentInsets != .zero {
			layoutSection.contentInsets = section.contentInsets
		}

		// Supplementary items
		var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

		if let header = section.header {
			let headerSize: NSCollectionLayoutSize
			if header.preferredSize.height != UIView.noIntrinsicMetric {
				headerSize = NSCollectionLayoutSize(
					widthDimension: .fractionalWidth(1.0),
					heightDimension: .absolute(header.preferredSize.height)
				)
			} else {
				headerSize = NSCollectionLayoutSize(
					widthDimension: .fractionalWidth(1.0),
					heightDimension: .estimated(44)
				)
			}
			let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: headerSize,
				elementKind: UICollectionView.elementKindSectionHeader,
				alignment: .top
			)
			boundaryItems.append(headerItem)
		}

		if let footer = section.footer {
			let footerSize: NSCollectionLayoutSize
			if footer.preferredSize.height != UIView.noIntrinsicMetric {
				footerSize = NSCollectionLayoutSize(
					widthDimension: .fractionalWidth(1.0),
					heightDimension: .absolute(footer.preferredSize.height)
				)
			} else {
				footerSize = NSCollectionLayoutSize(
					widthDimension: .fractionalWidth(1.0),
					heightDimension: .estimated(44)
				)
			}
			let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
				layoutSize: footerSize,
				elementKind: UICollectionView.elementKindSectionFooter,
				alignment: .bottom
			)
			boundaryItems.append(footerItem)
		}

		if !boundaryItems.isEmpty {
			layoutSection.boundarySupplementaryItems = boundaryItems
		}

		// Decoration
		switch section.decoration {
		case .none:
			break
		case .custom:
			let backgroundItem = NSCollectionLayoutDecorationItem.background(
				elementKind: SectionBackgroundDecorationView.elementKind
			)
			backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
			layoutSection.decorationItems = [backgroundItem]
		}

		// onDisplay via visibleItemsInvalidationHandler (works for both vertical and orthogonal scroll)
		let sectionItems = section.items
		let hasOnDisplay = sectionItems.contains { $0.onDisplay != nil }
		if hasOnDisplay {
			let sectionIndex = sectionsSource.current.firstIndex(where: { $0.id == section.id }) ?? 0
			layoutSection.visibleItemsInvalidationHandler = { [weak self] visibleItems, _, _ in
				guard let self else { return }
				let currentlyVisible = Set(
					visibleItems
						.filter { $0.representedElementCategory == .cell }
						.map(\.indexPath.item)
				)
				let previouslyVisible = self.visibleItemsBySection[sectionIndex] ?? []
				let newlyAppeared = currentlyVisible.subtracting(previouslyVisible)
				self.visibleItemsBySection[sectionIndex] = currentlyVisible

				for idx in newlyAppeared {
					guard idx < sectionItems.count else { continue }
					sectionItems[idx].onDisplay?()
				}
			}
		}

		return layoutSection
	}

	private static func makeDefaultSection() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(44)
		)
		let item = NSCollectionLayoutItem(layoutSize: itemSize)
		let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
		return NSCollectionLayoutSection(group: group)
	}

	// MARK: - Snapshot

	private func apply(sections: [CollectionSection], animated: Bool) {
		// Detect if the section structure changed (added/removed/reordered sections)
		let previousSectionIDs = diffableDataSource?.snapshot().sectionIdentifiers ?? []
		let newSectionIDs = sections.map(\.id)
		let sectionsStructureChanged = previousSectionIDs != newSectionIDs

		visibleItemsBySection.removeAll()

		// Rebuild item lookup from model identity
		var lookup: [ItemID: AnyCollectionItem] = [:]
		for section in sections {
			for item in section.items {
				lookup[item.itemID] = item
			}
		}
		itemLookup = lookup

		// Build snapshot using stable model IDs
		var snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>()

		for section in sections {
			snapshot.appendSections([section.id])
			let itemIDs = section.items.map(\.itemID)
			snapshot.appendItems(itemIDs, toSection: section.id)
		}

		// Mark all existing items for reconfiguration so cells pick up updated models and resize
		let previousItems = Set(diffableDataSource?.snapshot().itemIdentifiers ?? [])
		let itemsToReconfigure = snapshot.itemIdentifiers.filter { previousItems.contains($0) }
		if !itemsToReconfigure.isEmpty {
			snapshot.reconfigureItems(itemsToReconfigure)
		}

		diffableDataSource?.apply(snapshot, animatingDifferences: animated)

		// Invalidate layout only when section structure changed,
		// so the section provider re-evaluates layouts for new/reordered sections
		if sectionsStructureChanged {
			collectionViewLayout.invalidateLayout()
		}
	}
}

// MARK: - UICollectionViewDelegate

extension CollectionView: UICollectionViewDelegate {

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		guard indexPath.section < sectionsSource.current.count else { return }
		let section = sectionsSource.current[indexPath.section]
		guard indexPath.item < section.items.count else { return }
		let item = section.items[indexPath.item]
		item.onTap?()
	}
}

// MARK: - DecorationProvider

extension CollectionView: DecorationProvider {

	func decorationStyle(forSection index: Int) -> DecorationStyle {
		guard index < sectionsSource.current.count else { return .none }
		return sectionsSource.current[index].decoration
	}
}
