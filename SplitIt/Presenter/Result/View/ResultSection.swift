//
//  ResultSection.swift
//  SplitIt
//
//  Created by 홍승완 on 2023/10/20.
//

import RxDataSources

struct Result {
    var name: [String]
    var payment: Int
    var exclItems: [String]
}

struct ResultSection {
    var header: CSInfo
    var items: [Result]
    // MARK: 기본으로 접혀있고 나중에 탭해서 열어줌
    var isFold: Bool = true
    
    init(header: CSInfo, items: [Result]) {
        self.header = header
        self.items = items
    }
}

extension ResultSection: SectionModelType {
    
    init(original: ResultSection, items: [Result]) {
        self = original
        self.items = items
    }
}
