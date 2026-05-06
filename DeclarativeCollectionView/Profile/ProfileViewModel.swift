//
//  ProfileViewModel.swift
//  DeclarativeCollectionView
//

import UIKit

@MainActor
final class ProfileViewModel {

	// MARK: - Output

	var onSectionsChanged: (([CollectionSection]) -> Void)?

	// MARK: - Init

	func start() {
		rebuildSections()
	}

	// MARK: - Private

	private func rebuildSections() {
		var sections: [CollectionSection] = []

		// Header section — user avatar and info
		let headerSection = CollectionSection(id: "profile-header", layout: .plain) {
			ProfileHeader(
				id: "header",
				name: "Дмитрий Иванов",
				email: "dmitrii@example.com",
				avatarColor: .systemBlue
			)
		}
		sections.append(headerSection)

		// General settings
		let generalSection = CollectionSection(
			id: "general",
			layout: .insetGrouped
		) {
			ProfileItem(
				id: "appearance",
				icon: "paintbrush.fill",
				iconColor: .systemPurple,
				title: "Appearance",
				subtitle: "System",
				hasChevron: true
			)
			ProfileItem(
				id: "notifications",
				icon: "bell.fill",
				iconColor: .systemRed,
				title: "Notifications",
				subtitle: nil,
				hasChevron: true
			)
			ProfileItem(
				id: "privacy",
				icon: "lock.fill",
				iconColor: .systemGreen,
				title: "Privacy",
				subtitle: nil,
				hasChevron: true
			)
		}
			.header(SectionHeaderViewable(model: .init(id: "general", title: "GENERAL")))
		sections.append(generalSection)

		// Data & Storage
		let dataSection = CollectionSection(
			id: "data",
			layout: .insetGrouped
		) {
			ProfileItem(
				id: "storage",
				icon: "internaldrive.fill",
				iconColor: .systemOrange,
				title: "Storage",
				subtitle: "2.4 GB used",
				hasChevron: true
			)
			ProfileItem(
				id: "data-usage",
				icon: "chart.bar.fill",
				iconColor: .systemTeal,
				title: "Data Usage",
				subtitle: nil,
				hasChevron: true
			)
		}
		.header(SectionHeaderViewable(model: .init(id: "data", title: "DATA & STORAGE")))
		sections.append(dataSection)

		// Support
		let supportSection = CollectionSection(
			id: "support",
			layout: .insetGrouped,
			items: [
				ProfileItem(
					id: "help",
					icon: "questionmark.circle.fill",
					iconColor: .systemBlue,
					title: "Help & Support",
					subtitle: nil,
					hasChevron: true
				),
				ProfileItem(
					id: "about",
					icon: "info.circle.fill",
					iconColor: .systemGray,
					title: "About",
					subtitle: "Version 1.0",
					hasChevron: true
				)
			]
		)
		.header(SectionHeaderViewable(model: .init(id: "support", title: "SUPPORT")))
		sections.append(supportSection)

		onSectionsChanged?(sections)
	}
}
