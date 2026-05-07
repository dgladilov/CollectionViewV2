//
//  SectionInvalidatable.swift
//  DeclarativeCollectionView
//

import UIKit

/// Opt-in протокол для вью, размещённых внутри `CollectionView`.
///
/// Добавьте conformance к вашей `ModelableView`, чтобы получить доступ
/// к методу `invalidateSection(animated:)` — точечной инвалидации layout-а
/// только той секции, в которой находится данная вью.
///
/// ```swift
/// final class ExpandableView: UIView, ModelableView, SectionInvalidatable {
///     @objc private func handleTap() {
///         model.isExpanded.toggle()
///         invalidateSection(animated: true)
///     }
/// }
/// ```
///
/// Вью, не объявившие conformance к `SectionInvalidatable`, не имеют доступа к этому методу.
@MainActor
protocol SectionInvalidatable: UIView {}

extension SectionInvalidatable {

	/// Инвалидирует layout секции, в которой находится данная вью.
	///
	/// Обходит цепочку `UIResponder.next` от текущей вью вверх, находит
	/// ячейку (`UICollectionViewCell`) и `CollectionView`, после чего вызывает
	/// точечную инвалидацию layout-а только для этой секции.
	///
	/// Если вью не находится внутри `CollectionView` — вызов игнорируется.
	/// - Parameter animated: Анимировать ли изменение layout-а (по умолчанию `true`).
	func invalidateSection(animated: Bool = true) {
		var cell: UICollectionViewCell?
		var responder: UIResponder? = self

		while let current = responder {
			if cell == nil, let c = current as? UICollectionViewCell {
				cell = c
			} else if let cv = current as? CollectionView,
					  let cell,
					  let indexPath = cv.indexPath(for: cell) {
				cv.updateSection(at: indexPath.section, animated: animated)
				return
			}
			responder = current.next
		}
	}
}
