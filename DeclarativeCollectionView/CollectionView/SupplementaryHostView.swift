//
//  SupplementaryHostView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Контейнер для supplementary-вью (хедеров, футеров и пр.).
///
/// При повторном вызове `configure(with:)` обновляет модель существующей вью.
/// При первом вызове — создаёт вью и размещает в себе.
final class SupplementaryHostView: UICollectionReusableView {

	private var hostedView: UIView?

	/// Конфигурирует supplementary-вью.
	///
	/// Если вью уже создана — обновляет модель через `updateView`.
	/// Иначе создаёт новую вью через `makeView` и размещает с привязкой к краям.
	/// - Parameter item: Type-erased описание supplementary-элемента.
	func configure(with item: AnySupplementaryItem) {
		if let existing = hostedView {
			item.updateView(existing)
			return
		}

		let view = item.makeView()
		view.translatesAutoresizingMaskIntoConstraints = false
		addSubview(view)

		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: topAnchor),
			view.leadingAnchor.constraint(equalTo: leadingAnchor),
			view.trailingAnchor.constraint(equalTo: trailingAnchor),
			view.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

		hostedView = view
	}

	override func prepareForReuse() {
		super.prepareForReuse()
	}
}
