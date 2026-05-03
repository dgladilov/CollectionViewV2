//
//  CollectionSection.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

// MARK: - SectionLayout

enum SectionLayout {
	/// Vertical list — one item per row, full width, estimated height.
	case vertical

	/// Horizontal carousel with orthogonal scrolling.
	case horizontal(itemWidth: CGFloat, itemHeight: CGFloat)

	/// Inset grouped style (like UITableView .insetGrouped) with decoration background.
	case insetGrouped

	/// Fully custom layout section.
	case custom((NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)
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
