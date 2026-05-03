//
//  DeclarativeCollectionView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// A declarative wrapper around UICollectionView with CompositionalLayout and DiffableDataSource.
///
/// Supports two modes:
/// - **Reactive**: pass an `Observable<[CollectionSection]>` — the collection auto-updates on changes.
/// - **Manual**: call `reload { ... }` with a section builder when data changes.
final class DeclarativeCollectionView: UIView, Updatable {

	// MARK: - Properties

	private(set) var collectionView: UICollectionView
	private var dataSource: UICollectionViewDiffableDataSource<SectionID, StableItemID>
	private var currentSections: [CollectionSection] = []
	private var itemLookup: [StableItemID: AnyCollectionItem] = [:]
	private var streamTask: Task<Void, Never>?
	private var animateUpdates = true

	/// Called when an item is tapped. Provides section ID, item stable ID, and index path.
	var onItemTap: ((SectionID, StableItemID, IndexPath) -> Void)?

	// MARK: - Initializers

	/// Reactive mode: the collection view auto-updates when sections are pushed to the source.
	init(source: SectionsSource) {
		let (cv, ds) = Self.makeCollectionViewAndDataSource()
		self.collectionView = cv
		self.dataSource = ds
		super.init(frame: .zero)
		embedCollectionView()
		setupCellAndSupplementaryProviders()

		// Apply current sections immediately if the source already has data
		if !source.current.isEmpty {
			apply(sections: source.current, animated: false)
		}

		streamTask = Task { [weak self, stream = source.stream] in
			for await sections in stream {
				self?.apply(sections: sections, animated: self?.animateUpdates ?? true)
			}
		}
	}

	/// Manual mode: use `reload { ... }` to push new sections.
	override init(frame: CGRect) {
		let (cv, ds) = Self.makeCollectionViewAndDataSource()
		self.collectionView = cv
		self.dataSource = ds
		super.init(frame: frame)
		embedCollectionView()
		setupCellAndSupplementaryProviders()
	}

	/// Convenience: create with an initial set of sections.
	convenience init(@CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		self.init(frame: .zero)
		apply(sections: builder(), animated: false)
	}

	required init?(coder: NSCoder) {
		let (cv, ds) = Self.makeCollectionViewAndDataSource()
		self.collectionView = cv
		self.dataSource = ds
		super.init(coder: coder)
		embedCollectionView()
		setupCellAndSupplementaryProviders()
	}

	deinit {
		streamTask?.cancel()
	}

	// MARK: - Public API

	/// Manual reload with a declarative section builder.
	func reload(animated: Bool = true, @CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		apply(sections: builder(), animated: animated)
	}

	/// Updatable conformance.
	func update(animated: Bool) {
		apply(sections: currentSections, animated: animated)
	}

	// MARK: - Factory

	private static func makeCollectionViewAndDataSource()
		-> (UICollectionView, UICollectionViewDiffableDataSource<SectionID, StableItemID>)
	{
		let layout = makeCompositionalLayout()
		layout.register(
			SectionBackgroundDecorationView.self,
			forDecorationViewOfKind: SectionBackgroundDecorationView.elementKind
		)

		let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
		cv.translatesAutoresizingMaskIntoConstraints = false
		cv.backgroundColor = .systemBackground

		// Placeholder cell registration — replaced in setupCellAndSupplementaryProviders()
		let cellRegistration = UICollectionView.CellRegistration<HostCell, StableItemID> { _, _, _ in }

		let ds = UICollectionViewDiffableDataSource<SectionID, StableItemID>(
			collectionView: cv
		) { collectionView, indexPath, itemID in
			collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemID)
		}

		return (cv, ds)
	}

	// MARK: - Setup

	private func embedCollectionView() {
		addSubview(collectionView)
		collectionView.delegate = self
		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])
	}

	private func setupCellAndSupplementaryProviders() {
		let cellRegistration = UICollectionView.CellRegistration<HostCell, StableItemID> { [weak self] cell, _, itemID in
			guard let self, let item = self.itemLookup[itemID] else { return }
			cell.configure(with: item)
		}

		dataSource = UICollectionViewDiffableDataSource<SectionID, StableItemID>(
			collectionView: collectionView
		) { collectionView, indexPath, itemID in
			collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemID)
		}

		let headerRegistration = UICollectionView.SupplementaryRegistration<SupplementaryHostView>(
			elementKind: UICollectionView.elementKindSectionHeader
		) { [weak self] supplementaryView, _, indexPath in
			guard let self,
				  indexPath.section < self.currentSections.count,
				  let header = self.currentSections[indexPath.section].header else { return }
			supplementaryView.configure(with: header)
		}

		let footerRegistration = UICollectionView.SupplementaryRegistration<SupplementaryHostView>(
			elementKind: UICollectionView.elementKindSectionFooter
		) { [weak self] supplementaryView, _, indexPath in
			guard let self,
				  indexPath.section < self.currentSections.count,
				  let footer = self.currentSections[indexPath.section].footer else { return }
			supplementaryView.configure(with: footer)
		}

		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
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

	private static func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { _, _ in
			makeDefaultSection()
		}
	}

	private func createSectionProvider() -> UICollectionViewCompositionalLayoutSectionProvider {
		{ [weak self] sectionIndex, environment in
			guard let self, sectionIndex < self.currentSections.count else {
				return Self.makeDefaultSection()
			}
			let section = self.currentSections[sectionIndex]
			return self.makeLayoutSection(for: section, environment: environment)
		}
	}

	private func makeLayoutSection(
		for section: CollectionSection,
		environment: NSCollectionLayoutEnvironment
	) -> NSCollectionLayoutSection {
		let layoutSection: NSCollectionLayoutSection

		switch section.layout {
		case .vertical:
			layoutSection = makeVerticalSection()

		case let .horizontal(itemWidth, itemHeight):
			layoutSection = makeHorizontalSection(itemWidth: itemWidth, itemHeight: itemHeight)

		case .insetGrouped:
			layoutSection = makeInsetGroupedSection(environment: environment)

		case let .custom(provider):
			layoutSection = provider(environment)
		}

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
		case .background:
			let backgroundItem = NSCollectionLayoutDecorationItem.background(
				elementKind: SectionBackgroundDecorationView.elementKind
			)
			backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
			layoutSection.decorationItems = [backgroundItem]
		}

		return layoutSection
	}

	// MARK: - Section Layout Factories

	private func makeVerticalSection() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(44)
		)
		let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(44)
		)
		let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

		return NSCollectionLayoutSection(group: group)
	}

	private func makeHorizontalSection(itemWidth: CGFloat, itemHeight: CGFloat) -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .absolute(itemWidth),
			heightDimension: .absolute(itemHeight)
		)
		let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .absolute(itemWidth),
			heightDimension: .absolute(itemHeight)
		)
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.orthogonalScrollingBehavior = .continuous
		section.interGroupSpacing = 8
		return section
	}

	private func makeInsetGroupedSection(
		environment: NSCollectionLayoutEnvironment
	) -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(44)
		)
		let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .estimated(44)
		)
		let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

		let layoutSection = NSCollectionLayoutSection(group: group)
		layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

		let backgroundItem = NSCollectionLayoutDecorationItem.background(
			elementKind: SectionBackgroundDecorationView.elementKind
		)
		backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
		layoutSection.decorationItems = [backgroundItem]

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
		currentSections = sections

		// Rebuild item lookup from model identity
		var lookup: [StableItemID: AnyCollectionItem] = [:]
		for section in sections {
			for item in section.items {
				lookup[item.stableID] = item
			}
		}
		itemLookup = lookup

		// Recreate layout with current sections
		let newLayout = UICollectionViewCompositionalLayout(sectionProvider: createSectionProvider())
		newLayout.register(
			SectionBackgroundDecorationView.self,
			forDecorationViewOfKind: SectionBackgroundDecorationView.elementKind
		)
		collectionView.setCollectionViewLayout(newLayout, animated: animated)

		// Build and apply snapshot using stable model IDs
		var snapshot = NSDiffableDataSourceSnapshot<SectionID, StableItemID>()

		for section in sections {
			snapshot.appendSections([section.id])
			let itemIDs = section.items.map(\.stableID)
			snapshot.appendItems(itemIDs, toSection: section.id)
		}

		dataSource.apply(snapshot, animatingDifferences: animated)
	}
}
// MARK: - UICollectionViewDelegate

extension DeclarativeCollectionView: UICollectionViewDelegate {

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		guard indexPath.section < currentSections.count else { return }
		let section = currentSections[indexPath.section]
		guard indexPath.item < section.items.count else { return }
		let item = section.items[indexPath.item]
		onItemTap?(section.id, item.stableID, indexPath)
	}
}
