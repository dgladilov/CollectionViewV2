//
//  SearchPresenter.swift
//  DeclarativeCollectionView
//

import UIKit

protocol SearchPresentationLogic {
	@MainActor func presentItems(_ response: Search.Load.Response)
	@MainActor func presentLoading()
}

final class SearchPresenter: SearchPresentationLogic {

	weak var viewController: SearchDisplayLogic?

	@MainActor
	func presentLoading() {
		viewController?.displayLoading()
	}

	@MainActor
	func presentItems(_ response: Search.Load.Response) {
		var sections: [CollectionSection] = []

		for block in response.blocks {
			switch block {
			case .standalone(let entry):
				let sectionID = SectionID(entry.item.id)
				let item = makeItem(entry.item, sectionID: sectionID)
				let section = CollectionSection(id: entry.item.id, layout: .plain, items: [item])
				sections.append(section)

			case .module(let entry):
				let sectionIDString = "module-\(entry.item.id)"
				let sectionID = SectionID(sectionIDString)
				let item = makeItem(entry.item, sectionID: sectionID)
				let section = CollectionSection(id: sectionIDString, layout: .insetGrouped, items: [item])
					.header(SectionHeaderViewable(model: .init(id: sectionIDString, title: entry.title.uppercased())))
				sections.append(section)

			case .groupedModule(let entry):
				let sectionIDString = "group-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				let sectionID = SectionID(sectionIDString)
				let items = entry.items.map { makeItem($0, sectionID: sectionID) }
				let section = CollectionSection(id: sectionIDString, layout: .insetGrouped, items: items)
					.header(SectionHeaderViewable(model: .init(id: sectionIDString, title: entry.title.uppercased())))
				sections.append(section)

			case .expandable(let entry):
				let section = CollectionSection(id: entry.id, layout: .plain) {
					ExpandableModel(
						id: entry.id,
						title: entry.title,
						color: entry.color,
						isExpanded: entry.isExpanded
					)
				}
				sections.append(section)

			case .composite(let entry):
				let baseID = "composite-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				let sectionID = SectionID(baseID)
				let sideInset: CGFloat = 16
				let interItemSpacing: CGFloat = 8
				let topCount = entry.topGridItems.count
				let hasCarousel = !entry.carouselItems.isEmpty
				let bottomCount = entry.bottomGridItems.count
				let carouselHeight: CGFloat = 120

				let topItems = entry.topGridItems.map { makeItem($0, sectionID: sectionID) }
				let bottomItems = entry.bottomGridItems.map { makeItem($0, sectionID: sectionID) }

				var allItems: [AnyCollectionItem] = topItems
				if !entry.carouselItems.isEmpty {
					let carouselItem = AnyCollectionItem(CarouselModel(
						id: "\(baseID)-carousel",
						items: entry.carouselItems,
						onItemTap: { [weak self] item in
							self?.viewController?.didTapCarouselItem(item, inSection: sectionID)
						}
					))
					allItems.append(carouselItem)
				}
				allItems.append(contentsOf: bottomItems)

				let section = CollectionSection(
					id: baseID,
					layout: .custom({ environment in
						let availableWidth = environment.container.contentSize.width - sideInset * 2
						let cellWidth = (availableWidth - interItemSpacing) / 2.0
						let cellHeight = cellWidth * 1.5

						var verticalSubgroups: [NSCollectionLayoutGroup] = []

						// Top grid rows (2 items per row)
						let topRowCount = (topCount + 1) / 2
						if topRowCount > 0 {
							let gridItemSize = NSCollectionLayoutSize(
								widthDimension: .absolute(cellWidth),
								heightDimension: .absolute(cellHeight)
							)
							let gridItem = NSCollectionLayoutItem(layoutSize: gridItemSize)

							let rowSize = NSCollectionLayoutSize(
								widthDimension: .fractionalWidth(1.0),
								heightDimension: .absolute(cellHeight)
							)
							let row = NSCollectionLayoutGroup.horizontal(layoutSize: rowSize, subitems: [gridItem, gridItem])
							row.interItemSpacing = .fixed(interItemSpacing)

							for _ in 0..<topRowCount {
								verticalSubgroups.append(row)
							}
						}

						// Carousel row — full width, no extra insets
						if hasCarousel {
							let carouselItemSize = NSCollectionLayoutSize(
								widthDimension: .fractionalWidth(1.0),
								heightDimension: .absolute(carouselHeight)
							)
							let carouselItem = NSCollectionLayoutItem(layoutSize: carouselItemSize)
							let carouselRow = NSCollectionLayoutGroup.horizontal(
								layoutSize: carouselItemSize,
								subitems: [carouselItem]
							)
							verticalSubgroups.append(carouselRow)
						}

						// Bottom grid rows (2 items per row)
						let bottomRowCount = (bottomCount + 1) / 2
						if bottomRowCount > 0 {
							let gridItemSize = NSCollectionLayoutSize(
								widthDimension: .absolute(cellWidth),
								heightDimension: .absolute(cellHeight)
							)
							let gridItem = NSCollectionLayoutItem(layoutSize: gridItemSize)

							let rowSize = NSCollectionLayoutSize(
								widthDimension: .fractionalWidth(1.0),
								heightDimension: .absolute(cellHeight)
							)
							let row = NSCollectionLayoutGroup.horizontal(layoutSize: rowSize, subitems: [gridItem, gridItem])
							row.interItemSpacing = .fixed(interItemSpacing)

							for _ in 0..<bottomRowCount {
								verticalSubgroups.append(row)
							}
						}

						let totalHeight = CGFloat(topRowCount) * cellHeight
							+ CGFloat(max(0, topRowCount - 1)) * interItemSpacing
							+ (hasCarousel ? carouselHeight + interItemSpacing : 0)
							+ CGFloat(bottomRowCount) * cellHeight
							+ CGFloat(max(0, bottomRowCount - 1)) * interItemSpacing
							+ (bottomRowCount > 0 && (hasCarousel || topRowCount > 0) ? interItemSpacing : 0)

						let outerGroupSize = NSCollectionLayoutSize(
							widthDimension: .fractionalWidth(1.0),
							heightDimension: .absolute(totalHeight)
						)
						let outerGroup = NSCollectionLayoutGroup.vertical(
							layoutSize: outerGroupSize,
							subitems: verticalSubgroups
						)
						outerGroup.interItemSpacing = .fixed(interItemSpacing)

						let layoutSection = NSCollectionLayoutSection(group: outerGroup)
						layoutSection.contentInsets = NSDirectionalEdgeInsets(
							top: 8, leading: sideInset, bottom: 8, trailing: sideInset
						)
						return layoutSection
					}),
					decoration: .custom {
					let view = UIView()
					view.backgroundColor = .secondarySystemBackground
					view.layer.cornerRadius = 12
					view.layer.masksToBounds = true
					return view
				},
					items: allItems
				)
				.header(SectionHeaderViewable(model: .init(id: baseID, title: entry.title.uppercased())))
				sections.append(section)
			}
		}

		viewController?.displayItems(Search.Load.ViewModel(sections: sections))
	}

	// MARK: - Private

	@MainActor
	private func makeItem(_ searchItem: SearchItem, sectionID: SectionID) -> AnyCollectionItem {
		let itemID = ItemID(searchItem.id)
		return AnyCollectionItem(searchItem).onTap { [weak self] in
			self?.viewController?.didTapItem(sectionID: sectionID, itemID: itemID)
		}
	}
}
