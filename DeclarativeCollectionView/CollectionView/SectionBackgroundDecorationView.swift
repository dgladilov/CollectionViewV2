//
//  SectionBackgroundDecorationView.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

/// Decoration view that provides a background for collection view sections.
/// Supports configurable background color and corner radius.
final class SectionBackgroundDecorationView: UICollectionReusableView {

	static let elementKind = "section-background-decoration"

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupDefaults()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupDefaults()
	}

	private func setupDefaults() {
		backgroundColor = .secondarySystemBackground
		layer.cornerRadius = 12
		layer.masksToBounds = true
	}

	func apply(color: UIColor, cornerRadius: CGFloat) {
		backgroundColor = color
		layer.cornerRadius = cornerRadius
	}
}
