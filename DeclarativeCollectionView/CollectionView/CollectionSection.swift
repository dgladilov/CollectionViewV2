//
//  CollectionSection.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - SectionLayout

/// A generic layout descriptor for a collection section.
/// Wraps a closure that produces an `NSCollectionLayoutSection` from the layout environment.
/// Use the static factories (`.vertical`, `.horizontal(...)`, `.insetGrouped`, etc.) or provide
/// a fully custom closure via `init`.
struct SectionLayout {

	let provider: (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection

	init(_ provider: @escaping (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection) {
		self.provider = provider
	}

	// MARK: - Static Factories

	/// Vertical list — one item per row, full width, estimated height.
	static var vertical: SectionLayout {
		SectionLayout { _ in
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
	}

	/// Horizontal carousel with orthogonal scrolling.
	static func horizontal(itemWidth: CGFloat, itemHeight: CGFloat, spacing: CGFloat = 8) -> SectionLayout {
		SectionLayout { _ in
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
			section.interGroupSpacing = spacing
			return section
		}
	}

	/// Inset grouped style (like UITableView .insetGrouped) with decoration background.
	static var insetGrouped: SectionLayout {
		SectionLayout { _ in
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

			let section = NSCollectionLayoutSection(group: group)
			section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

			let backgroundItem = NSCollectionLayoutDecorationItem.background(
				elementKind: SectionBackgroundDecorationView.elementKind
			)
			backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
			section.decorationItems = [backgroundItem]

			return section
		}
	}

	/// Vertical grid — items arranged in columns with a given count and aspect ratio.
	static func grid(columns: Int, aspectRatio: CGFloat, spacing: CGFloat = 8, sideInset: CGFloat = 16) -> SectionLayout {
		SectionLayout { environment in
			let availableWidth = environment.container.contentSize.width - sideInset * 2
			let totalSpacing = CGFloat(columns - 1) * spacing
			let itemWidth = (availableWidth - totalSpacing) / CGFloat(columns)
			let itemHeight = itemWidth * aspectRatio

			let itemSize = NSCollectionLayoutSize(
				widthDimension: .absolute(itemWidth),
				heightDimension: .absolute(itemHeight)
			)
			let item = NSCollectionLayoutItem(layoutSize: itemSize)

			let groupSize = NSCollectionLayoutSize(
				widthDimension: .fractionalWidth(1.0),
				heightDimension: .absolute(itemHeight)
			)
			let subitems = Array(repeating: item, count: columns)
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: subitems)
			group.interItemSpacing = .fixed(spacing)

			let section = NSCollectionLayoutSection(group: group)
			section.interGroupSpacing = spacing
			section.contentInsets = NSDirectionalEdgeInsets(
				top: 0, leading: sideInset, bottom: 0, trailing: sideInset
			)
			return section
		}
	}
}

// MARK: - DecorationStyle

enum DecorationStyle: Hashable {
	case none
	case background(color: UIColor, cornerRadius: CGFloat)

	static func == (lhs: DecorationStyle, rhs: DecorationStyle) -> Bool {
		switch (lhs, rhs) {
		case (.none, .none):
			return true
		case let (.background(lc, lr), .background(rc, rr)):
			return lc == rc && lr == rr
		default:
			return false
		}
	}

	func hash(into hasher: inout Hasher) {
		switch self {
		case .none:
			hasher.combine(0)
		case let .background(color, radius):
			hasher.combine(1)
			hasher.combine(color)
			hasher.combine(radius)
		}
	}
}

// MARK: - CollectionSection

struct CollectionSection {

	let id: SectionID
	let layout: SectionLayout
	let items: [AnyCollectionItem]
	var header: AnySupplementaryItem?
	var footer: AnySupplementaryItem?
	var supplementaries: [AnySupplementaryItem]
	var decoration: DecorationStyle
	var contentInsets: NSDirectionalEdgeInsets

	@MainActor
	init(
		id: String,
		layout: SectionLayout,
		decoration: DecorationStyle = .none,
		contentInsets: NSDirectionalEdgeInsets = .zero,
		@CollectionItemBuilder items: () -> [AnyCollectionItem]
	) {
		self.id = SectionID(id)
		self.layout = layout
		self.items = items()
		self.header = nil
		self.footer = nil
		self.supplementaries = []
		self.decoration = decoration
		self.contentInsets = contentInsets
	}

	// MARK: - Fluent API

	@MainActor
	func header<V: Viewable>(_ viewable: V) -> CollectionSection where V.ViewType: ModelableView {
		var copy = self
		copy.header = AnySupplementaryItem(
			elementKind: UICollectionView.elementKindSectionHeader,
			viewable: viewable
		)
		return copy
	}

	@MainActor
	func footer<V: Viewable>(_ viewable: V) -> CollectionSection where V.ViewType: ModelableView {
		var copy = self
		copy.footer = AnySupplementaryItem(
			elementKind: UICollectionView.elementKindSectionFooter,
			viewable: viewable
		)
		return copy
	}

	@MainActor
	func supplementary<V: Viewable>(kind: String, _ viewable: V) -> CollectionSection where V.ViewType: ModelableView {
		var copy = self
		copy.supplementaries.append(
			AnySupplementaryItem(elementKind: kind, viewable: viewable)
		)
		return copy
	}

	func decoration(_ style: DecorationStyle) -> CollectionSection {
		var copy = self
		copy.decoration = style
		return copy
	}

	func insets(_ insets: NSDirectionalEdgeInsets) -> CollectionSection {
		var copy = self
		copy.contentInsets = insets
		return copy
	}
}
