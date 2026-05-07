//
//  CollectionItemCell.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Ячейка-контейнер, которая размещает внутри себя произвольную `ModelableView`.
///
/// При повторном вызове `configure(with:)` с тем же типом вью — обновляет модель
/// существующей вью. При смене типа — удаляет старую и создаёт новую.
final class CollectionItemCell: UICollectionViewCell {

	private var hostedView: UIView?
	private var currentViewTypeId: ObjectIdentifier?

	/// Конфигурирует ячейку элементом коллекции.
	///
	/// Если тип вью совпадает с текущим — обновляет модель через `updateView`.
	/// Иначе создаёт вью заново через `makeView` и размещает в `contentView`.
	/// - Parameter item: Type-erased описание элемента.
	func configure(with item: AnyCollectionItem) {
		// If the hosted view type matches, just update the model
		if let existing = hostedView, currentViewTypeId == item.viewTypeId {
			item.updateView(existing)
			return
		}

		// Otherwise, create a new view
		hostedView?.removeFromSuperview()

		let view = item.makeView()
		view.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(view)

		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: contentView.topAnchor),
			view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])

		hostedView = view
		currentViewTypeId = item.viewTypeId
	}
}
