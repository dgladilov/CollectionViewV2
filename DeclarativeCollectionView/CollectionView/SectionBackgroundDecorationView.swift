//
//  SectionBackgroundDecorationView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Декоративная вью фона секции.
///
/// Размещает внутри себя произвольную пользовательскую вью, создаваемую через `DecorationStyle.custom`.
/// Получает стиль декорации от `DecorationProvider` (реализуемого `CollectionView`).
final class SectionBackgroundDecorationView: UICollectionReusableView {

	/// Строковый идентификатор типа декорации для регистрации в layout-е.
	static let elementKind = "section-background-decoration"

	private var hostedView: UIView?
	private var configuredSectionIndex: Int?

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)

		let sectionIndex = layoutAttributes.indexPath.section

		// Skip reconfiguration if already set up for this section
		if configuredSectionIndex == sectionIndex, hostedView != nil {
			return
		}

		guard let provider = findDecorationProvider() else { return }
		let style = provider.decorationStyle(forSection: sectionIndex)
		configure(with: style)
		configuredSectionIndex = sectionIndex
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		hostedView?.removeFromSuperview()
		hostedView = nil
		configuredSectionIndex = nil
		backgroundColor = .clear
	}

	private func configure(with style: DecorationStyle) {
		hostedView?.removeFromSuperview()
		hostedView = nil
		backgroundColor = .clear

		switch style {
		case .none:
			break

		case .custom(let factory):
			let view = factory()
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
	}

	private func findDecorationProvider() -> DecorationProvider? {
		superview as? DecorationProvider
	}
}
