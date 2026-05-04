//
//  HomeViewModel.swift
//  DeclarativeCollectionView
//

import UIKit

@MainActor
final class HomeViewModel {

	// MARK: - Reactive output

	let sectionsSource = SectionsSource()

	// MARK: - State

	private struct SectionData {
		let id: String
		let title: String
		var items: [HomeItem]
	}

	private var sections: [SectionData] = []
	private var nextItemIndex = 0
	private var nextSectionIndex = 0

	private let palette: [UIColor] = [
		.systemRed, .systemOrange, .systemYellow, .systemGreen,
		.systemTeal, .systemBlue, .systemIndigo, .systemPurple, .systemPink
	]

	// MARK: - Init

	init() {
		sections = [
			SectionData(id: "section-0", title: "First Section", items: makeItems(count: 3)),
			SectionData(id: "section-1", title: "Second Section", items: makeItems(count: 2))
		]
		nextSectionIndex = 2
		rebuildSections()
	}

	// MARK: - Actions: Items

	func addItem(inSection sectionIndex: Int) {
		guard sectionIndex < sections.count else { return }
		let item = makeItem()
		sections[sectionIndex].items.append(item)
		rebuildSections()
	}

	func removeItem(sectionID: SectionID, itemID: StableItemID) {
		guard let sIdx = sections.firstIndex(where: { SectionID($0.id) == sectionID }) else { return }
		sections[sIdx].items.removeAll { StableItemID($0.id) == itemID }
		if sections[sIdx].items.isEmpty {
			sections.remove(at: sIdx)
		}
		rebuildSections()
	}

	func editRandomItem(inSection sectionIndex: Int) {
		guard sectionIndex < sections.count,
			  !sections[sectionIndex].items.isEmpty else { return }
		let itemIdx = Int.random(in: 0..<sections[sectionIndex].items.count)
		sections[sectionIndex].items[itemIdx].title = "Edited #\(Int.random(in: 100...999))"
		sections[sectionIndex].items[itemIdx].color = palette.randomElement()!
		// Toggle details to demonstrate height change
		if sections[sectionIndex].items[itemIdx].details == nil {
			sections[sectionIndex].items[itemIdx].details = "This cell was edited and now displays additional details that make it taller."
		} else {
			sections[sectionIndex].items[itemIdx].details = nil
		}
		rebuildSections()
	}

	// MARK: - Actions: Sections

	func addSection() {
		let sectionID = "section-\(nextSectionIndex)"
		nextSectionIndex += 1
		let items = makeItems(count: Int.random(in: 2...4))
		let section = SectionData(id: sectionID, title: "Section \(nextSectionIndex)", items: items)
		sections.append(section)
		rebuildSections()
	}

	func removeSection(at sectionIndex: Int) {
		guard sectionIndex < sections.count else { return }
		sections.remove(at: sectionIndex)
		rebuildSections()
	}

	var sectionCount: Int { sections.count }

	func sectionTitle(at index: Int) -> String? {
		guard index < sections.count else { return nil }
		return sections[index].title
	}

	// MARK: - Private

	private func makeItem() -> HomeItem {
		nextItemIndex += 1
		return HomeItem(
			id: "item-\(nextItemIndex)",
			title: "Item \(nextItemIndex)",
			subtitle: "Added dynamically",
			color: palette[nextItemIndex % palette.count]
		)
	}

	private func makeItems(count: Int) -> [HomeItem] {
		(0..<count).map { _ in makeItem() }
	}

	private func rebuildSections() {
		let collectionSections: [CollectionSection] = sections.map { sectionData in
			CollectionSection(id: sectionData.id, layout: .insetGrouped) {
				for item in sectionData.items {
					HomeItemViewable(model: item)
				}
			}
			.header(SectionHeaderViewable(model: .init(id: sectionData.id, title: sectionData.title.uppercased())))
		}
		sectionsSource.send(collectionSections)
	}
}
