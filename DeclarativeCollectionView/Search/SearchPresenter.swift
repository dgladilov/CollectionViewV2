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
				// Standalone: vertical section, no decoration
				let section = CollectionSection(id: entry.item.id, layout: .vertical) {
					SearchItemViewable(model: entry.item)
				}
				sections.append(section)

			case .module(let entry):
				// Single item wrapped in a module with decoration
				let sectionID = "module-\(entry.item.id)"
				let section = CollectionSection(id: sectionID, layout: .insetGrouped) {
					SearchItemViewable(model: entry.item)
				}
				.header(SectionHeaderViewable(model: .init(id: sectionID, title: entry.title.uppercased())))
				sections.append(section)

			case .groupedModule(let entry):
				// Multiple items in one module with shared decoration
				let sectionID = "group-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				let section = CollectionSection(id: sectionID, layout: .insetGrouped) {
					for item in entry.items {
						SearchItemViewable(model: item)
					}
				}
				.header(SectionHeaderViewable(model: .init(id: sectionID, title: entry.title.uppercased())))
				sections.append(section)

			case .composite(let entry):
				let baseID = "composite-\(entry.title.lowercased().replacingOccurrences(of: " ", with: "-"))"
				let sideInset: CGFloat = 16
				let interItemSpacing: CGFloat = 8
				let topCount = entry.topGridItems.count
				let hasCarousel = !entry.carouselItems.isEmpty
				let bottomCount = entry.bottomGridItems.count
				let carouselHeight: CGFloat = 120

				let section = CollectionSection(
					id: baseID,
					layout: SectionLayout({ environment in
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
					decoration: .background(color: .secondarySystemBackground, cornerRadius: 12)
				) {
					for item in entry.topGridItems {
						SearchCardViewable(model: item)
					}
					if !entry.carouselItems.isEmpty {
						let sectionID = SectionID(baseID)
						CarouselViewable(model: CarouselModel(
							id: "\(baseID)-carousel",
							items: entry.carouselItems,
							onItemTap: { [weak self] item in
								self?.viewController?.didTapCarouselItem(item, inSection: sectionID)
							}
						))
					}
					for item in entry.bottomGridItems {
						SearchCardViewable(model: item)
					}
				}
				.header(SectionHeaderViewable(model: .init(id: baseID, title: entry.title.uppercased())))
				sections.append(section)
			}
		}

		viewController?.displayItems(Search.Load.ViewModel(sections: sections))
	}
}
