//
//  SearchInteractor.swift
//  DeclarativeCollectionView
//

import UIKit

@MainActor
protocol SearchBusinessLogic {
	func loadItems(_ request: Search.Load.Request)
	func removeItem(_ request: Search.RemoveItem.Request)
	func addSection(_ request: Search.AddSection.Request)
}

@MainActor
final class SearchInteractor: SearchBusinessLogic {

	var presenter: SearchPresentationLogic?
	private var blocks: [SearchResponseBlock] = []
	private var addedSectionCount = 0

	// MARK: - SearchBusinessLogic

	func loadItems(_ request: Search.Load.Request) {
		Task { @MainActor in
			// Simulate network delay 1–3 seconds
			let delay = UInt64.random(in: 1_000_000_000...3_000_000_000)
			try? await Task.sleep(nanoseconds: delay)

			blocks = Self.makeMockBlocks()
			presenter?.presentItems(Search.Load.Response(blocks: blocks))
		}
	}

	func removeItem(_ request: Search.RemoveItem.Request) {
		let sectionRaw = request.sectionID.rawValue

		for (blockIndex, block) in blocks.enumerated() {
			switch block {
			case .standalone(let entry):
				if entry.item.id == sectionRaw {
					blocks.remove(at: blockIndex)
					presenter?.presentItems(Search.Load.Response(blocks: blocks))
					return
				}

			case .module(let entry):
				let moduleID = "module-\(entry.item.id)"
				if moduleID == sectionRaw {
					blocks.remove(at: blockIndex)
					presenter?.presentItems(Search.Load.Response(blocks: blocks))
					return
				}

			case .groupedModule(var entry):
				let groupID = "group-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				if groupID == sectionRaw {
					let itemStableID = request.itemID
					entry.items.removeAll { ItemID($0.id) == itemStableID }
					if entry.items.isEmpty {
						blocks.remove(at: blockIndex)
					} else {
						blocks[blockIndex] = .groupedModule(entry)
					}
					presenter?.presentItems(Search.Load.Response(blocks: blocks))
					return
				}

			case .composite(var entry):
				let compositeID = "composite-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				if sectionRaw == compositeID {
					let itemStableID = request.itemID
					entry.topGridItems.removeAll { ItemID($0.id) == itemStableID }
					entry.carouselItems.removeAll { ItemID($0.id) == itemStableID }
					entry.bottomGridItems.removeAll { ItemID($0.id) == itemStableID }
					if entry.topGridItems.isEmpty && entry.carouselItems.isEmpty && entry.bottomGridItems.isEmpty {
						blocks.remove(at: blockIndex)
					} else {
						blocks[blockIndex] = .composite(entry)
					}
					presenter?.presentItems(Search.Load.Response(blocks: blocks))
					return
				}

			case .expandable:
				break
			}
		}
	}

	func addSection(_ request: Search.AddSection.Request) {
		addedSectionCount += 1
		let newItem = SearchItem(
			id: "added-\(addedSectionCount)",
			title: "New Item \(addedSectionCount)",
			subtitle: "Added by user",
			color: [UIColor.systemPink, .systemMint, .systemIndigo, .systemBrown].randomElement() ?? .systemPink
		)
		let entry = ModuleEntry(title: "Added Section \(addedSectionCount)", item: newItem)
		blocks.append(.module(entry))
		presenter?.presentItems(Search.Load.Response(blocks: blocks))
	}

	// MARK: - Mock Data

	private static func makeMockBlocks() -> [SearchResponseBlock] {
		[
			// Standalone items (no module wrapper)
			.standalone(StandaloneEntry(item: SearchItem(
				id: "s1", title: "Standalone A", subtitle: "No module", color: .systemBlue
			))),
			.standalone(StandaloneEntry(item: SearchItem(
				id: "s2", title: "Standalone B", subtitle: "No module", color: .systemGreen
			))),

			// Single item wrapped in a module
			.module(ModuleEntry(title: "Featured", item: SearchItem(
				id: "m1", title: "Module Item", subtitle: "Wrapped in module", color: .systemOrange
			))),

			// Multiple items grouped in one module
			.groupedModule(GroupedModuleEntry(title: "Popular", items: [
				SearchItem(id: "g1", title: "Group Item 1", subtitle: "In grouped module", color: .systemPurple),
				SearchItem(id: "g2", title: "Group Item 2", subtitle: "In grouped module", color: .systemRed),
				SearchItem(id: "g3", title: "Group Item 3", subtitle: "In grouped module", color: .systemTeal)
			])),

			// Another standalone
			.standalone(StandaloneEntry(item: SearchItem(
				id: "s3", title: "Standalone C", subtitle: "No module", color: .systemYellow
			))),

			// Another grouped module
			.groupedModule(GroupedModuleEntry(title: "Recent", items: [
				SearchItem(id: "r1", title: "Recent 1", subtitle: "In grouped module", color: .systemCyan),
				SearchItem(id: "r2", title: "Recent 2", subtitle: "In grouped module", color: .systemMint)
			])),

			// Expandable cell — toggles height on tap via Updatable
			.expandable(ExpandableEntry(
				id: "exp1",
				title: "Tap to Expand",
				color: .systemIndigo,
				isExpanded: false
			)),

			// Composite section: grid → carousel → grid, with decoration
			.composite(CompositeEntry(
				title: "Showcase",
				topGridItems: [
					SearchItem(id: "tg1", title: "Grid 1", subtitle: "Top", color: .systemBlue),
					SearchItem(id: "tg2", title: "Grid 2", subtitle: "Top", color: .systemGreen),
					SearchItem(id: "tg3", title: "Grid 3", subtitle: "Top", color: .systemOrange),
					SearchItem(id: "tg4", title: "Grid 4", subtitle: "Top", color: .systemPurple),
					SearchItem(id: "tg5", title: "Grid 5", subtitle: "Top", color: .systemRed),
					SearchItem(id: "tg6", title: "Grid 6", subtitle: "Top", color: .systemTeal)
				],
				carouselItems: [
					SearchItem(id: "c1", title: "Carousel 1", subtitle: "Swipe", color: .systemIndigo),
					SearchItem(id: "c2", title: "Carousel 2", subtitle: "Swipe", color: .systemPink),
					SearchItem(id: "c3", title: "Carousel 3", subtitle: "Swipe", color: .systemMint),
					SearchItem(id: "c4", title: "Carousel 4", subtitle: "Swipe", color: .systemCyan),
					SearchItem(id: "c5", title: "Carousel 5", subtitle: "Swipe", color: .systemBrown)
				],
				bottomGridItems: [
					SearchItem(id: "bg1", title: "Grid 1", subtitle: "Bottom", color: .systemYellow),
					SearchItem(id: "bg2", title: "Grid 2", subtitle: "Bottom", color: .systemMint),
					SearchItem(id: "bg3", title: "Grid 3", subtitle: "Bottom", color: .systemIndigo),
					SearchItem(id: "bg4", title: "Grid 4", subtitle: "Bottom", color: .systemPink),
					SearchItem(id: "bg5", title: "Grid 5", subtitle: "Bottom", color: .systemCyan),
					SearchItem(id: "bg6", title: "Grid 6", subtitle: "Bottom", color: .systemBrown)
				]
			))
		]
	}
}
