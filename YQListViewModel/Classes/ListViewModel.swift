//
//  ListViewModel.swift
//  YQListViewModel_Example
//
//  Created by 王叶庆 on 2020/10/29.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import RxDataSources
import RxRelay
import RxSwift

public protocol FetchCancellable {
    var isCancelled: Bool { get }
    func cancel()
}

public protocol AsFetchCancellable {
    func asFetchCancellable() -> FetchCancellable
}

public enum FetchResult<Model> {
    case success([Model], Int)
    case failure(Error?)
}

public typealias ListViewModelDataFetcher<Model> = ([Model], DataAction, Pagable, @escaping ((FetchResult<Model>) -> Void)) throws -> FetchCancellable

open class ListViewModel<SectionData> where SectionData: SectionModelType {
    public let data: Observable<[SectionData]>
    public var page: Pagable = Page()
    public let dataState: Observable<DataState>

    private let _data = BehaviorRelay<[SectionData]>(value: [])
    private let _dataState = BehaviorRelay<DataState>(value: .none)
    private var cancellable: FetchCancellable?

    public required init() {
        data = _data.asObservable()
        dataState = _dataState.asObservable()
    }

    public var dataFetcher: ListViewModelDataFetcher<SectionData>?

    public func loadData(_ action: DataAction = .refresh) {
        DispatchQueue.main.async { [self] in
            let state = _dataState.value
            if action == .refresh { // 刷新
                // 如果此时正在刷新就啥都不做
                guard state != .loading else {
                    return
                }
                // 如果此时正在加载更多应该停掉加载更多
                if state == .loadingMore {
                    _dataState.accept(.loadedMore(nil))
                    cancellable?.cancel()
                }
                page = page.first()
                _dataState.accept(.loading)
            } else { // 加载更多
                // 如果此时正在加载更多什么也不做
                guard state != .loadingMore else {
                    return
                }
                // 如果此时正在刷新 要停止当前的动作
                guard state != .loading else {
                    _dataState.accept(.loadedMore(nil))
                    _dataState.accept(.loading)
                    return
                }
                page = page.next()
                _dataState.accept(.loadingMore)
            }
            guard let fetcher = dataFetcher else { fatalError("请先设置dataFetcher") }
            do {
                cancellable = try fetcher(_data.value, action, page, { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case let .success(values, count):
                            if action == .refresh {
                                self._data.accept(values)
                                self._dataState.accept(.loaded(nil))
                                if count < self.page.size {
                                    self._dataState.accept(.noMore)
                                }
                            } else {
                                if count < self.page.size {
                                    if count > 0 {
                                        self._data.accept(values)
                                    }
                                    self._dataState.accept(.noMore)
                                } else {
                                    self._data.accept(values)
                                    self._dataState.accept(.loadedMore(nil))
                                }
                            }
                        case let .failure(error):
                            let state = self._dataState.value.next(with: error) ?? .none
                            self._dataState.accept(state)
                        }
                    }
                })
            } catch let error {
                let state = _dataState.value.next(with: error) ?? .none
                _dataState.accept(state)
            }
        }
    }

    public func updateData(_ block: (ListViewModel<SectionData>, [SectionData]) -> [SectionData]) {
        let data = block(self, _data.value)
        _data.accept(data)
    }

    public func updateSection(at index: Int, section: SectionData) {
        var data = _data.value
        data[index] = section
        _data.accept(data)
    }

    public func updateItem(at indexPath: IndexPath, item: SectionData.Item) {
        var data = _data.value
        let section = data[indexPath.section]
        var items = section.items
        items[indexPath[1]] = item
        data[indexPath.section] = SectionData(original: section, items: items)
        _data.accept(data)
    }

    public func section(_ number: Int) -> SectionData? {
        guard _data.value.count > number else {
            return nil
        }
        return _data.value[number]
    }

    public var sectionCount: Int {
        _data.value.count
    }

    public var isListDataEmpty: Bool {
        guard sectionCount > 0 else {
            return true
        }
        return section(0)?.items.isEmpty ?? true
    }
}

// 懒惰的ListViewModel,需自主触发TableView重新加载
open class LazyListViewModel<SectionData> where SectionData: SectionModelType {
//    public let data: Observable<[SectionData]>
    public var page: Pagable = Page()
    public let dataState: Observable<DataState>

//    private let _data = BehaviorRelay<[SectionData]>(value: [])
    private let _dataState = BehaviorRelay<DataState>(value: .none)
    private var cancellable: FetchCancellable?
    private var sections: [SectionData] = []

    public required init() {
//        data = _data.asObservable()
        dataState = _dataState.asObservable()
    }

    public var dataFetcher: ListViewModelDataFetcher<SectionData>?

    public func loadData(_ action: DataAction = .refresh) {
        DispatchQueue.main.async { [self] in
            let state = _dataState.value
            if action == .refresh { // 刷新
                // 如果此时正在刷新就啥都不做
                guard state != .loading else {
                    return
                }
                // 如果此时正在加载更多应该停掉加载更多
                if state == .loadingMore {
                    _dataState.accept(.loadedMore(nil))
                    cancellable?.cancel()
                }
                page = page.first()
                _dataState.accept(.loading)
            } else { // 加载更多
                // 如果此时正在加载更多什么也不做
                guard state != .loadingMore else {
                    return
                }
                // 如果此时正在刷新 要停止当前的动作
                guard state != .loading else {
                    _dataState.accept(.loadedMore(nil))
                    _dataState.accept(.loading)
                    return
                }
                page = page.next()
                _dataState.accept(.loadingMore)
            }
            guard let fetcher = dataFetcher else { fatalError("请先设置dataFetcher") }
            do {
                cancellable = try fetcher(sections, action, page, { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(values, count):
                        if action == .refresh {
                            self.sections = values
//                                self._data.accept(values)
                            self._dataState.accept(.loaded(nil))
                            if count < self.page.size {
                                self._dataState.accept(.noMore)
                            }
                        } else {
                            if count < self.page.size {
                                if count > 0 {
                                    self.sections = values
//                                        self._data.accept(values)
                                }
                                self._dataState.accept(.noMore)
                            } else {
                                self.sections = values
//                                    self._data.accept(values)
                                self._dataState.accept(.loadedMore(nil))
                            }
                        }
                    case let .failure(error):
                        let state = self._dataState.value.next(with: error) ?? .none
                        self._dataState.accept(state)
                    }
                })
            } catch let error {
                let state = _dataState.value.next(with: error) ?? .none
                _dataState.accept(state)
            }
        }
    }

    public func updateData(_ block: (LazyListViewModel<SectionData>, [SectionData]) -> [SectionData]) {
        let data = block(self, sections)
        sections = data
//        _data.accept(data)
    }

    public func updateSection(at index: Int, section: SectionData) {
        sections[index] = section
    }

    public func updateItem(at indexPath: IndexPath, item: SectionData.Item) {
        let section = sections[indexPath.section]
        var items = section.items
        items[indexPath[1]] = item
        sections[indexPath.section] = SectionData(original: section, items: items)
    }

    public func section(_ number: Int) -> SectionData? {
        guard sections.count > number else {
            return nil
        }
        return sections[number]
    }

    public var sectionCount: Int {
        sections.count
    }

    public var isListDataEmpty: Bool {
        guard sectionCount > 0 else {
            return true
        }
        return section(0)?.items.isEmpty ?? true
    }

    public func itemsCount(for section: Int = 0) -> Int {
        guard section < sections.count else {
            return 0
        }
        return sections[section].items.count
    }

    public subscript(section: Int) -> SectionData {
        sections[section]
    }

    public subscript(indexPath: IndexPath) -> SectionData.Item {
        sections[indexPath.section].items[indexPath.item]
    }
}
