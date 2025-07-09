//
//  Page.swift
//  Goldfish
//
//  Created by 王叶庆 on 2020/5/14.
//  Copyright © 2020 王叶庆. All rights reserved.
//

import Foundation

public protocol Pagable {
    
    var start: Int {get}
    var index: Int {get}
    var size: Int {get}
    
    var isFirst: Bool {get}
    
    func previous() -> Pagable
    func next() -> Pagable
    func first() -> Pagable
    
    func convertToParameters(withIndexKey indexKey: String, sizeKey: String) -> [String : Any]
    
}

public extension Pagable {
    var isFirst: Bool {
        return start == index
    }
    
}

public struct Page {
    
    public let start: Int
    
    public let index: Int
    public let size: Int
    
    public init(index: Int = 0, size: Int = 1 /*设为1可以允许访问接口时不传size，这样如果接口返回的数据为空时就是没有更多了*/, start: Int = 0) {
        assert(start <= index, "当前页码应该小于起始页码")
        self.index = index
        self.size = size
        self.start = start
    }
    
    public func convertToParameters(withIndexKey indexKey: String = "page", sizeKey: String = "pageSize") -> [String : Any] {
        return [
            indexKey: index,
            sizeKey: size
        ]
    }
    
    public func previous() -> Pagable {
        return Page(index: max(index - 1, start), size: size, start: start)
    }
    
    public func next() -> Pagable {
        return Page(index: index + 1, size: size, start: start)
    }
        
    public func first() -> Pagable {
        return Page(index: start, size: size, start: start)
    }
}

extension Page: Pagable {}
