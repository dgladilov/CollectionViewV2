//
//  VIewable.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

protocol Viewable {

	associatedtype ViewType: ModelableView

	@MainActor var preferredSize: CGSize { get }

	@MainActor func makeView() -> ViewType
}

extension Viewable {
	
	@MainActor var preferredSize: CGSize { .init(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric) }
}

protocol Updatable {
}

protocol ModelableView: UIView {

	associatedtype Model

	var model: Model { get set }

	var updatable: Updatable? { get set }

	init(_ model: Model)
}
