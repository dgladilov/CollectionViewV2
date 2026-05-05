//
//  SearchModels.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - Mock Data Models

struct SearchItem: Identifiable, Viewable, CollectionItemable {
	let id: String
	let title: String
	let subtitle: String
	let color: UIColor
	
	typealias ViewType = SearchCardView

	var preferredSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
	}

	func makeView() -> SearchCardView {
		SearchCardView(self)
	}
	
	var onTap: (@MainActor () -> Void)? {
		{
			print("onTap: \(id)")
		}
	}
	
	var onDisplay: (@MainActor () -> Void)? {
		{
			print("onDisplay: \(id)")
		}
	}
}

// MARK: - Response Models

/// A standalone item displayed without any module wrapper.
struct StandaloneEntry {
	let item: SearchItem
}

/// A single item wrapped in a module (decoration background).
struct ModuleEntry {
	let title: String
	let item: SearchItem
}

/// Multiple items grouped inside a single module.
struct GroupedModuleEntry {
	let title: String
	var items: [SearchItem]
}

/// A composite section with decoration containing:
/// top grid (2 columns) → horizontal carousel → bottom grid (2 columns).
struct CompositeEntry {
	let title: String
	var topGridItems: [SearchItem]
	var carouselItems: [SearchItem]
	var bottomGridItems: [SearchItem]
}

/// A single expandable cell that toggles its height on tap via Updatable.
struct ExpandableEntry {
	let id: String
	let title: String
	let color: UIColor
	var isExpanded: Bool
}

/// Top-level response element — represents one "block" in the search response.
enum SearchResponseBlock {
	case standalone(StandaloneEntry)
	case module(ModuleEntry)
	case groupedModule(GroupedModuleEntry)
	case composite(CompositeEntry)
	case expandable(ExpandableEntry)
}

// MARK: - VIP Models

enum Search {

	enum Load {
		struct Request {}

		struct Response {
			let blocks: [SearchResponseBlock]
		}

		struct ViewModel {
			let sections: [CollectionSection]
		}
	}

	enum RemoveItem {
		struct Request {
			let sectionID: SectionID
			let itemID: ItemID
		}
	}

	enum AddSection {
		struct Request {}
	}
}
