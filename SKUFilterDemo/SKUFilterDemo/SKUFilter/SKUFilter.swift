//
//  SKUFilter.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import Foundation

protocol SKUFilterDelegate: NSObjectProtocol {
    /// 属性集合个数
    func numberOfArrtibutes(_ filter: SKUFilter) -> Int
    /// 属性集合
    func arrtibutes(_ filter: SKUFilter, for index: Int) -> [AnyHashable]
    /// 条件集合个数
    func numberOfConditions(_ filter: SKUFilter) -> Int
    /// 条件集合
    func conditions(_ filter: SKUFilter, for index: Int) -> [AnyHashable]
    /// 询问每一个item的结果
    func resultOfCondition(_ filter: SKUFilter, for index: Int) -> Pack?
    /// 选中结果
    func filter(_ filter: SKUFilter, selectedCondition param: Pack?)
}

class SKUFilter {
    
    weak var delegate: SKUFilterDelegate? {
        didSet { reloadData() }
    }
    /// 是否需要默认选中一组sku
    public var needDefaultValue: Bool = true
    /// 再次点击是否取消选中
    public var clickAginCancel: Bool = false
    /// 缺货的indexPath
    public var outOfStocks: Set<IndexPath> = []
    
    /// 已选择集合 (默认顺序为选择顺序)
    private(set) var selecteds: [IndexPath] = []
    /// 可选择集合
    private(set) var available: Set<IndexPath> = []
    /// 最终结果 (全部选择完毕后即可获取到)
    private(set) var result: Any?
    
    private var allAvailable: Set<IndexPath> = []
    private var conditions: Set<Condition> = []
    /// 默认sku
    private var defaultSku: Condition?
    
   
    
    init(_ delegate: SKUFilterDelegate) {
        self.delegate = delegate
        reloadData()
    }
    
    /// 刷新数据
    func reloadData() {
        guard let delegate = delegate else {
            // 清理
            selecteds = []
            available = []
            result = nil
            allAvailable = []
            conditions = []
            outOfStocks = []
            return
        }
        
        // 清空
        selecteds = []
        available = []
        outOfStocks = []
        // 条件集合
        var temps = Set<Condition>()
        (0 ..< delegate.numberOfConditions(self)).forEach {
            let conditions = delegate.conditions(self, for: $0)
            
            let arrtibutes: [Attribute] = conditions.enumerated().compactMap {
                guard
                    delegate.numberOfArrtibutes(self) > $0,
                    let index = delegate.arrtibutes(self, for: $0).firstIndex(of: $1) else {
                    return nil
                }
                let indexPath = IndexPath(item: index, section: $0)
                return Attribute(indexPath, $1)
            }
            
            if arrtibutes.count == conditions.count {
                let condition = Condition(
                    arrtibutes: arrtibutes,
                    indexs: arrtibutes.map { $0.indexPath.item },
                    result: delegate.resultOfCondition(self, for: $0)
                )
                if (selecteds.count == 0 && needDefaultValue && (defaultSku == nil)) {
                    defaultSku = condition
                }
                temps.insert(condition)
            }
        }
        conditions = temps
        
        // 可选集合
        available = Set<IndexPath>(temps.flatMap {
            $0.indexs.enumerated().map {
                IndexPath(item: $1, section: $0)
            }
        })
        
        allAvailable = available
        
        selectDefaultProperties()
    }
    
    // 选择默认属性
    func selectDefaultProperties() {
        guard let defaultSku = defaultSku else { return }
        for property in defaultSku.arrtibutes {
            selected(property.indexPath)
        }
    }
    
    /// 选择
    ///
    /// - Parameter indexPath: 位置
    func selected(_ indexPath: IndexPath) {
        guard available.contains(indexPath) else {
            // 不可选
            return
        }
        guard
            let section = delegate?.numberOfArrtibutes(self),
            let item = delegate?.arrtibutes(self, for: indexPath.section).count,
            indexPath.section < section,
            indexPath.item < item else {
            // 越界
            return
        }
        if clickAginCancel {
            guard !selecteds.contains(indexPath) else {
                // 已选
                selecteds.removeAll { $0 == indexPath }
                updateAvailable()
                outOfStocksCheck(section)
                return
            }
        }
        
        if let last = selecteds.lastIndex(where: { $0.section == indexPath.section }) {
            // 切换
            selecteds.append(indexPath)
            selecteds.remove(at: last)
            outOfStocksCheck(section)
        } else {
            // 新增
            selecteds.append(indexPath)
            available.formIntersection(available(indexPath, with: selecteds))
            outOfStocksCheck(section)
        }
    }
    
    func outOfStocksCheck(_ section: Int) {
        showPossibleCombinations()
        updateResult()
    }
    
}



extension SKUFilter {
    /// 更新可选集合
    private func updateAvailable() {
        guard !selecteds.isEmpty else {
            available = allAvailable
            return
        }
        
        var temps: [IndexPath] = []
        var set: Set<IndexPath> = []
        selecteds.forEach {
            temps.append($0)
            let available = self.available($0, with: temps)
            set = set.isEmpty ? available : set.intersection(available)
        }
        available = set
    }
    
    /// 获取可选集合
    ///
    /// - Parameters:
    ///   - selected: 当前选择
    ///   - selecteds: 已选集合
    /// - Returns: 可选集合
    private func available(_ selected: IndexPath, with selecteds: [IndexPath]) -> Set<IndexPath> {
        var temps = Set<IndexPath>()
        
        conditions.forEach { (condition) in
            guard
                condition.indexs.count > selected.section,
                condition.indexs[selected.section] == selected.item else {
                return
            }
            
            condition.arrtibutes.forEach { (attribute) in
                if attribute.indexPath.section == selected.section {
                    temps.insert(attribute.indexPath)
                    
                } else {
                    let flag = !selecteds.contains {
                        (condition.indexs.count > $0.section &&
                         condition.indexs[$0.section] != $0.item) &&
                        $0.section != attribute.indexPath.section
                    }
                    
                    if flag { temps.insert(attribute.indexPath) }
                }
            }
        }
        allAvailable
            .filter { $0.section == selected.section }
            .forEach { temps.insert($0) }
        return temps
    }
    
    /// 更新结果
    private func updateResult() {
        guard selecteds.count == delegate?.numberOfArrtibutes(self) else {
            result = nil
            return
        }
        
        let items = selecteds.sorted { $0.section < $1.section }.map { $0.item }
        result = conditions.first { $0.indexs == items }?.result
        guard let delegate = delegate else { return }
        delegate.filter(self, selectedCondition: result as? Pack)
    }
    
    /// 缺货
    private func showPossibleCombinations() {
        outOfStocks = []
        guard let delegate = delegate else { return }
        let numOfAttributes = delegate.numberOfArrtibutes(self)
        
        /// 当选中最后一组
        if selecteds.count == numOfAttributes {
            let section = numOfAttributes - 1
            var selectedValues: [Int: AnyHashable] = [:]
            selecteds.forEach { indexPath in
                if let value = delegate.arrtibutes(self, for: indexPath.section).item(at: indexPath.item) {
                    selectedValues[indexPath.section] = value
                }
            }
            let attributes = delegate.arrtibutes(self, for: section)
            
            var possibleCombinations: [[AnyHashable]] = []
            
            // 生成可能的组合
            attributes.forEach { attribute in
                var combination: [AnyHashable] = Array(repeating: "", count: numOfAttributes)
                for (index, value) in selectedValues {
                    combination[index] = value
                }
                combination[section] = attribute
                possibleCombinations.append(combination)
            }
            
            // 查找组合是否缺货
            possibleCombinations.forEach { combination in
                if let matchingCondition = findMatchingCondition(for: combination),
                   let pack = matchingCondition.result as? Pack,
                   pack.store <= 0 {
                    for attribute in matchingCondition.arrtibutes where attribute.indexPath.section == section {
                        outOfStocks.insert(attribute.indexPath)
                    }
                    
                    // 检查缺货 SKU 是否在已选中的 SKU 中
                    let isCombinationSelected = selecteds.contains {
                        $0.section == section && delegate.arrtibutes(self, for: section).item(at: $0.item) == combination[section]
                    }
                    if isCombinationSelected {
                        // 将其他组的选中 SKU 也记录到缺货数组中
                        for selected in selecteds {
                            outOfStocks.insert(selected)
                        }
                    }
                }
            }
        }
        // 当少选了一组时，检查可能的组合
        else if selecteds.count == numOfAttributes - 1 {
            var selectedValues: [Int: AnyHashable] = [:]
            selecteds.forEach { indexPath in
                if let value = delegate.arrtibutes(self, for: indexPath.section).item(at: indexPath.item) {
                    selectedValues[indexPath.section] = value
                }
            }
            
            // 找到未选择的组
            let unselectedSection = (0..<numOfAttributes).first { section in
                !selecteds.contains { $0.section == section }
            }
            
            guard let section = unselectedSection else { return }
            
            let attributes = delegate.arrtibutes(self, for: section)
            var possibleCombinations: [[AnyHashable]] = []
            
            // 生成可能的组合
            attributes.forEach { attribute in
                var combination: [AnyHashable] = Array(repeating: "", count: numOfAttributes)
                
                for (index, value) in selectedValues {
                    combination[index] = value
                }
                
                combination[section] = attribute
                possibleCombinations.append(combination)
            }
            
            // 查找组合是否缺货，并仅将未选中那一组的 SKU 添加到缺货数组中
            possibleCombinations.forEach { combination in
                if let matchingCondition = findMatchingCondition(for: combination),
                   let pack = matchingCondition.result as? Pack,
                   pack.store <= 0 {
                    for attribute in matchingCondition.arrtibutes where attribute.indexPath.section == section {
                        outOfStocks.insert(attribute.indexPath)
                    }
                }
            }
        }
        
    }
    
    /// 查找与 combination 匹配的条件
    ///
    /// - Parameter combination: 要查找的组合
    /// - Returns: 匹配的条件，或者 nil 如果没有匹配的条件
    private func findMatchingCondition(for combination: [AnyHashable]) -> Condition? {
        for condition in conditions {
            let conditionValues = condition.arrtibutes.map { $0.value }
            if conditionValues.elementsEqual(combination) {
                return condition
            }
        }
        return nil
    }
    
}

/// 协议
protocol Pack {
    var condition: [String] { get }
    var price: Int { get }
    var store: Int { get }
}

extension SKUFilter {
    
    struct Condition: Hashable, Equatable {
        let arrtibutes: [Attribute]
        let indexs: [Int]
        let result: Any?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(arrtibutes)
            hasher.combine(indexs)
        }
        
        static func == (lhs: SKUFilter.Condition,
                        rhs: SKUFilter.Condition) -> Bool {
            return lhs.arrtibutes == rhs.arrtibutes
            && lhs.indexs == rhs.indexs
        }
    }
    
    struct Attribute: Hashable, Equatable {
        let indexPath: IndexPath
        let value: AnyHashable
        
        init(_ indexPath: IndexPath, _ value: AnyHashable) {
            self.indexPath = indexPath
            self.value = value
        }
    }
}


extension Array {
    /// 安全访问数组元素
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

