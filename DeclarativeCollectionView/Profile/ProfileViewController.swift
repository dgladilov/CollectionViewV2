//
//  ProfileViewController.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import UIKit

final class ProfileViewController: UIViewController {

	private let viewModel = ProfileViewModel()
	private lazy var collectionView = CollectionView()

	// MARK: - Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		title = "Profile"

		setupCollectionView()
	}

	// MARK: - Setup

	private func setupCollectionView() {
		view.addSubview(collectionView)

		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		viewModel.onSectionsChanged = { [weak self] sections in
			self?.collectionView.send(sections)
		}
		viewModel.start()
	}
}
