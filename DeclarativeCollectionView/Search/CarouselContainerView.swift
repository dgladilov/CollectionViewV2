//
//  CarouselContainerView.swift
//  DeclarativeCollectionView
//

import UIKit

// MARK: - CarouselModel

struct CarouselModel: Viewable, CollectionItemable {
	let id: String
	let items: [SearchItem]
	var onItemTap: ((SearchItem) -> Void)?
	
	typealias ViewType = CarouselContainerView

	var preferredSize: CGSize {
		CGSize(width: UIView.noIntrinsicMetric, height: 120)
	}

	func makeView() -> CarouselContainerView {
		CarouselContainerView(self)
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

// MARK: - CarouselContainerView

/// A cell-sized view that hosts a horizontal UICollectionView (carousel).
final class CarouselContainerView: UIView, ModelableView {

	var model: CarouselModel {
		didSet { reloadData() }
	}

	var updatable: Updatable?

	private var collectionView: UICollectionView!
	private var dataSource: UICollectionViewDiffableDataSource<Int, String>!

	required init(_ model: CarouselModel) {
		self.model = model
		super.init(frame: .zero)
		setupCollectionView()
		reloadData()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Setup

	private func setupCollectionView() {
		let itemSize = NSCollectionLayoutSize(
			widthDimension: .absolute(140),
			heightDimension: .fractionalHeight(1.0)
		)
		let item = NSCollectionLayoutItem(layoutSize: itemSize)

		let groupSize = NSCollectionLayoutSize(
			widthDimension: .absolute(140),
			heightDimension: .fractionalHeight(1.0)
		)
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

		let section = NSCollectionLayoutSection(group: group)
		section.orthogonalScrollingBehavior = .continuous
		section.interGroupSpacing = 8

		let layout = UICollectionViewCompositionalLayout(section: section)

		collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.backgroundColor = .clear
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.delegate = self
		addSubview(collectionView)

		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, itemID in
			guard let self else { return }
			guard let searchItem = self.model.items.first(where: { $0.id == itemID }) else { return }

			cell.contentView.subviews.forEach { $0.removeFromSuperview() }

			let cardView = SearchCardView(searchItem)
			cardView.translatesAutoresizingMaskIntoConstraints = false
			cell.contentView.addSubview(cardView)

			NSLayoutConstraint.activate([
				cardView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
				cardView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
				cardView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
				cardView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
			])
		}

		dataSource = UICollectionViewDiffableDataSource<Int, String>(
			collectionView: collectionView
		) { collectionView, indexPath, itemID in
			collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemID)
		}
	}

	private func reloadData() {
		guard dataSource != nil else { return }
		var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
		snapshot.appendSections([0])
		snapshot.appendItems(model.items.map(\.id), toSection: 0)
		dataSource.apply(snapshot, animatingDifferences: false)
	}
}

// MARK: - UICollectionViewDelegate

extension CarouselContainerView: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		guard indexPath.item < model.items.count else { return }
		model.onItemTap?(model.items[indexPath.item])
	}
}
