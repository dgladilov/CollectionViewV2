//
//  SectionsSource.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import Foundation

/// A reactive data source for collection sections backed by AsyncStream.
///
/// Supports both full replacement and granular operations (append, insert, remove, update).
/// Every mutation automatically pushes the updated state to the collection view.
@MainActor
final class SectionsSource {

	private var continuation: AsyncStream<[CollectionSection]>.Continuation?
	private(set) var current: [CollectionSection] = []

	/// The async stream of section updates. Consume this in a `for await` loop.
	let stream: AsyncStream<[CollectionSection]>

	init() {
		let (stream, continuation) = AsyncStream<[CollectionSection]>.makeStream()
		self.stream = stream
		self.continuation = continuation
	}

	// MARK: - Full Replacement

	/// Replace all sections at once.
	func send(_ sections: [CollectionSection]) {
		current = sections
		continuation?.yield(current)
	}

	/// Replace all sections using the declarative builder.
	func send(@CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		send(builder())
	}

	// MARK: - Append

	/// Append a section to the end.
	func append(_ section: CollectionSection) {
		current.append(section)
		continuation?.yield(current)
	}

	/// Append multiple sections to the end.
	func append(contentsOf sections: [CollectionSection]) {
		current.append(contentsOf: sections)
		continuation?.yield(current)
	}

	// MARK: - Insert

	/// Insert a section at the given index.
	func insert(_ section: CollectionSection, at index: Int) {
		current.insert(section, at: index)
		continuation?.yield(current)
	}

	/// Insert a section after the section with the given id.
	func insert(_ section: CollectionSection, after sectionID: String) {
		guard let idx = indexForID(sectionID) else { return }
		current.insert(section, at: idx + 1)
		continuation?.yield(current)
	}

	/// Insert a section before the section with the given id.
	func insert(_ section: CollectionSection, before sectionID: String) {
		guard let idx = indexForID(sectionID) else { return }
		current.insert(section, at: idx)
		continuation?.yield(current)
	}

	// MARK: - Remove

	/// Remove the section with the given id.
	@discardableResult
	func remove(sectionID: String) -> CollectionSection? {
		guard let idx = indexForID(sectionID) else { return nil }
		let removed = current.remove(at: idx)
		continuation?.yield(current)
		return removed
	}

	/// Remove the section at the given index.
	@discardableResult
	func remove(at index: Int) -> CollectionSection {
		let removed = current.remove(at: index)
		continuation?.yield(current)
		return removed
	}

	/// Remove all sections.
	func removeAll() {
		current.removeAll()
		continuation?.yield(current)
	}

	// MARK: - Update

	/// Replace the section with the matching id.
	func update(_ section: CollectionSection) {
		guard let idx = indexForID(section.id.rawValue) else { return }
		current[idx] = section
		continuation?.yield(current)
	}

	/// Mutate the section with the given id in-place.
	func update(sectionID: String, _ transform: (inout CollectionSection) -> Void) {
		guard let idx = indexForID(sectionID) else { return }
		transform(&current[idx])
		continuation?.yield(current)
	}

	// MARK: - Batch

	/// Perform multiple mutations in a batch, emitting only one update at the end.
	func batch(_ mutations: (SectionsSource) -> Void) {
		let saved = continuation
		continuation = nil   // suppress intermediate yields
		mutations(self)
		continuation = saved
		continuation?.yield(current)
	}

	// MARK: - Query

	/// Returns the section with the given id, or nil.
	func section(id: String) -> CollectionSection? {
		current.first { $0.id.rawValue == id }
	}

	/// Returns the index of the section with the given id, or nil.
	func index(of sectionID: String) -> Int? {
		indexForID(sectionID)
	}

	// MARK: - Private

	private func indexForID(_ id: String) -> Int? {
		current.firstIndex { $0.id.rawValue == id }
	}

	deinit {
		continuation?.finish()
	}
}

