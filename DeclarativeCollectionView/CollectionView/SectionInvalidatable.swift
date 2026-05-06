//
//  SectionInvalidatable.swift
//  DeclarativeCollectionView
//

import UIKit

/// Opt-in protocol for `ModelableView` subclasses hosted inside a `CollectionView`.
///
/// Conform your view to gain access to `invalidateSection(animated:)`,
/// which triggers a targeted layout invalidation for the section the view belongs to.
///
/// ```swift
/// final class ExpandableView: UIView, ModelableView, SectionInvalidatable {
///     @objc private func handleTap() {
///         model.isExpanded.toggle()
///         invalidateSection(animated: true)
///     }
/// }
/// ```
@MainActor
protocol SectionInvalidatable: UIView {}

extension SectionInvalidatable {

	/// Invalidates the layout of the section this view belongs to.
	/// Walks the responder chain to find the owning `CollectionView` and the cell's `IndexPath`,
	/// then performs a targeted section-only layout invalidation.
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
