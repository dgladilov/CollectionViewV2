//
//  HomeViewController.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

final class HomeViewController: UIViewController {

	private let viewModel = HomeViewModel()
	private lazy var collectionView = DeclarativeCollectionView(source: viewModel.sectionsSource)
	private let toolbar = UIToolbar()

	// MARK: - Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		title = "Home"

		setupToolbar()
		setupCollectionView()
	}

	// MARK: - Setup

	private func setupCollectionView() {
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(collectionView)

		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
		])

		collectionView.onItemTap = { [weak self] sectionID, itemID, _ in
			self?.viewModel.removeItem(sectionID: sectionID, itemID: itemID)
		}
	}

	private func setupToolbar() {
		toolbar.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(toolbar)

		NSLayoutConstraint.activate([
			toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
		])

		let addItem = UIBarButtonItem(
			image: UIImage(systemName: "plus.circle"),
			primaryAction: UIAction { [weak self] _ in self?.addItemToRandomSection() }
		)

		let editItem = UIBarButtonItem(
			image: UIImage(systemName: "pencil.circle"),
			primaryAction: UIAction { [weak self] _ in self?.editRandomItem() }
		)

		let addSection = UIBarButtonItem(
			image: UIImage(systemName: "rectangle.stack.badge.plus"),
			primaryAction: UIAction { [weak self] _ in self?.viewModel.addSection() }
		)

		let removeSection = UIBarButtonItem(
			image: UIImage(systemName: "rectangle.stack.badge.minus"),
			primaryAction: UIAction { [weak self] _ in self?.removeLastSection() }
		)

		let spacer = UIBarButtonItem(systemItem: .flexibleSpace)

		toolbar.items = [addItem, spacer, editItem, spacer, addSection, spacer, removeSection]
	}

	// MARK: - Actions

	private func addItemToRandomSection() {
		guard viewModel.sectionCount > 0 else { return }
		let idx = Int.random(in: 0..<viewModel.sectionCount)
		viewModel.addItem(inSection: idx)
	}

	private func editRandomItem() {
		guard viewModel.sectionCount > 0 else { return }
		let idx = Int.random(in: 0..<viewModel.sectionCount)
		viewModel.editRandomItem(inSection: idx)
	}

	private func removeLastSection() {
		guard viewModel.sectionCount > 0 else { return }
		viewModel.removeSection(at: viewModel.sectionCount - 1)
	}
}
