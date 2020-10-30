//
//  ListDataState.swift
//  Nice
//
//  Created by 王叶庆 on 2020/10/9.
//

import Foundation

public enum DataState {
    case none
    case loading
    case loadingMore
    case loaded(Error?)
    case loadedMore(Error?)
    case noMore
}

public enum DataAction {
    case refresh
    case more
}

extension DataState: Equatable {
    public static func == (lhs: DataState, rhs: DataState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.loading, .loading), (.loadingMore, .loadingMore), (.noMore, .noMore):
            return true
        case (.loaded(_), .loaded(_)), (.loadedMore(_), .loadedMore(_)):
            return true
        default:
            return false
        }
    }
}

public extension DataState {
    func next(with error: Error? = nil) -> DataState? {
        if self == .loading {
            return .loaded(error)
        } else if self == .loadingMore {
            return .loadedMore(error)
        } else {
            return nil
        }
    }
}
