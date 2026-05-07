//
//  SectionsSource.swift
//  DeclarativeCollectionView
//
//  Created by Дмитрий on 30.04.2026.
//

import Foundation

/// Реактивный источник данных секций, основанный на `AsyncStream`.
///
/// Хранит текущий массив секций и уведомляет подписчиков о каждом изменении.
/// Поддерживает как полную замену секций, так и гранулярные операции
/// (добавление, вставка, удаление, обновление).
///
/// Каждая мутация автоматически публикует обновлённое состояние в `stream`.
@MainActor
final class SectionsSource {

	private var continuation: AsyncStream<[CollectionSection]>.Continuation?

	/// Текущий массив секций.
	private(set) var current: [CollectionSection] = []

	/// Асинхронный поток обновлений секций.
	/// Подпишитесь через `for await` для получения уведомлений об изменениях.
	let stream: AsyncStream<[CollectionSection]>

	init() {
		let (stream, continuation) = AsyncStream<[CollectionSection]>.makeStream()
		self.stream = stream
		self.continuation = continuation
	}

	// MARK: - Полная замена

	/// Заменяет все секции переданным массивом.
	/// - Parameter sections: Новый массив секций.
	func send(_ sections: [CollectionSection]) {
		current = sections
		continuation?.yield(current)
	}

	/// Заменяет все секции с помощью декларативного билдера.
	/// - Parameter builder: Билдер секций (`@CollectionSectionBuilder`).
	func send(@CollectionSectionBuilder _ builder: () -> [CollectionSection]) {
		send(builder())
	}

	// MARK: - Добавление

	/// Добавляет секцию в конец списка.
	/// - Parameter section: Секция для добавления.
	func append(_ section: CollectionSection) {
		current.append(section)
		continuation?.yield(current)
	}

	/// Добавляет несколько секций в конец списка.
	/// - Parameter sections: Массив секций для добавления.
	func append(contentsOf sections: [CollectionSection]) {
		current.append(contentsOf: sections)
		continuation?.yield(current)
	}

	// MARK: - Вставка

	/// Вставляет секцию по указанному индексу.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - index: Позиция вставки.
	func insert(_ section: CollectionSection, at index: Int) {
		current.insert(section, at: index)
		continuation?.yield(current)
	}

	/// Вставляет секцию после секции с указанным идентификатором.
	/// Если секция с таким `id` не найдена — вызов игнорируется.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - sectionID: Идентификатор секции, после которой вставлять.
	func insert(_ section: CollectionSection, after sectionID: String) {
		guard let idx = indexForID(sectionID) else { return }
		current.insert(section, at: idx + 1)
		continuation?.yield(current)
	}

	/// Вставляет секцию перед секцией с указанным идентификатором.
	/// Если секция с таким `id` не найдена — вызов игнорируется.
	/// - Parameters:
	///   - section: Секция для вставки.
	///   - sectionID: Идентификатор секции, перед которой вставлять.
	func insert(_ section: CollectionSection, before sectionID: String) {
		guard let idx = indexForID(sectionID) else { return }
		current.insert(section, at: idx)
		continuation?.yield(current)
	}

	// MARK: - Удаление

	/// Удаляет секцию с указанным идентификатором.
	/// - Parameter sectionID: Строковый идентификатор секции.
	/// - Returns: Удалённая секция, или `nil` если секция не найдена.
	@discardableResult
	func remove(sectionID: String) -> CollectionSection? {
		guard let idx = indexForID(sectionID) else { return nil }
		let removed = current.remove(at: idx)
		continuation?.yield(current)
		return removed
	}

	/// Удаляет секцию по индексу.
	/// - Parameter index: Индекс удаляемой секции.
	/// - Returns: Удалённая секция.
	@discardableResult
	func remove(at index: Int) -> CollectionSection {
		let removed = current.remove(at: index)
		continuation?.yield(current)
		return removed
	}

	/// Удаляет все секции.
	func removeAll() {
		current.removeAll()
		continuation?.yield(current)
	}

	// MARK: - Обновление

	/// Заменяет секцию с совпадающим `id`.
	/// Если секция с таким `id` не найдена — вызов игнорируется.
	/// - Parameter section: Новая секция (должна иметь тот же `id`).
	func update(_ section: CollectionSection) {
		guard let idx = indexForID(section.id.rawValue) else { return }
		current[idx] = section
		continuation?.yield(current)
	}

	/// Мутирует секцию с указанным `id` через замыкание.
	/// Если секция с таким `id` не найдена — вызов игнорируется.
	/// - Parameters:
	///   - sectionID: Строковый идентификатор секции.
	///   - transform: Замыкание для мутации секции.
	func update(sectionID: String, _ transform: (inout CollectionSection) -> Void) {
		guard let idx = indexForID(sectionID) else { return }
		transform(&current[idx])
		continuation?.yield(current)
	}

	// MARK: - Батчинг

	/// Выполняет несколько мутаций в одном батче, публикуя только одно обновление в конце.
	///
	/// Промежуточные `yield` подавляются на время выполнения замыкания.
	/// - Parameter mutations: Замыкание с мутациями.
	func batch(_ mutations: (SectionsSource) -> Void) {
		let saved = continuation
		continuation = nil   // suppress intermediate yields
		mutations(self)
		continuation = saved
		continuation?.yield(current)
	}

	// MARK: - Запросы

	/// Возвращает секцию с указанным идентификатором, или `nil`.
	/// - Parameter id: Строковый идентификатор секции.
	func section(id: String) -> CollectionSection? {
		current.first { $0.id.rawValue == id }
	}

	/// Возвращает индекс секции с указанным идентификатором, или `nil`.
	/// - Parameter sectionID: Строковый идентификатор секции.
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
