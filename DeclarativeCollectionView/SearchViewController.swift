//
//  SearchViewController.swift
//  DeclarativeCollectionView
//

import UIKit

protocol SearchDisplayLogic: AnyObject {
	@MainActor func displayLoading()
	@MainActor func displayItems(_ viewModel: Search.Load.ViewModel)
	@MainActor func didTapCarouselItem(_ item: SearchItem, inSection sectionID: SectionID)
}

final class SearchViewController: UIViewController, SearchDisplayLogic {

	var interactor: SearchBusinessLogic?

	private let sectionsSource = SectionsSource()
	private lazy var declarativeCollectionView = DeclarativeCollectionView(source: sectionsSource)

	private let spinner: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.hidesWhenStopped = true
		indicator.translatesAutoresizingMaskIntoConstraints = false
		return indicator
	}()

	// MARK: - Lifecycle

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		title = "Search"

		setupNavigationBar()
		setupSubviews()
		setupCollectionHandler()

		interactor?.loadItems(Search.Load.Request())
		displayLoading()
	}

	// MARK: - VIP Setup

	private func setup() {
		let interactor = SearchInteractor()
		let presenter = SearchPresenter()
		self.interactor = interactor
		interactor.presenter = presenter
		presenter.viewController = self
	}

	// MARK: - UI Setup

	private func setupNavigationBar() {
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .add,
			target: self,
			action: #selector(addSectionTapped)
		)
	}

	private func setupSubviews() {
		declarativeCollectionView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(declarativeCollectionView)
		view.addSubview(spinner)

		NSLayoutConstraint.activate([
			declarativeCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			declarativeCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			declarativeCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			declarativeCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private func setupCollectionHandler() {
		declarativeCollectionView.onItemTap = { [weak self] sectionID, itemID, _ in
			self?.interactor?.removeItem(Search.RemoveItem.Request(sectionID: sectionID, itemID: itemID))
		}
	}

	// MARK: - Actions

	@objc private func addSectionTapped() {
		interactor?.addSection(Search.AddSection.Request())
	}

	// MARK: - SearchDisplayLogic

	func displayLoading() {
		declarativeCollectionView.isHidden = true
		spinner.startAnimating()
	}

	func displayItems(_ viewModel: Search.Load.ViewModel) {
		spinner.stopAnimating()
		declarativeCollectionView.isHidden = false
		sectionsSource.send(viewModel.sections)
	}

	func didTapCarouselItem(_ item: SearchItem, inSection sectionID: SectionID) {
		interactor?.removeItem(Search.RemoveItem.Request(
			sectionID: sectionID,
			itemID: StableItemID(item.id)
		))
	}
}
