//
//  ViewController.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let list = [Attr("尺寸", [Item("S"), Item("M"), Item("L")]),
                Attr("颜色", [Item("白"), Item("米兰色"), Item("灰"), Item("绿")]),
                Attr("接口", [Item("Type-C"), Item("USB-A")])]
    
    let skus = [
        PackModel(condition: ["S", "白", "USB-A"], price: 300, store: 98),
        PackModel(condition: ["S", "白", "Type-C"], price: 310, store: 50),
        PackModel(condition: ["S", "米兰色", "USB-A"], price: 320, store: 45),
        PackModel(condition: ["S", "米兰色", "Type-C"], price: 330, store: 60),
        PackModel(condition: ["S", "灰", "USB-A"], price: 340, store: 70),
        PackModel(condition: ["S", "灰", "Type-C"], price: 350, store: 30),
        PackModel(condition: ["S", "绿", "USB-A"], price: 360, store: 20),
        PackModel(condition: ["S", "绿", "Type-C"], price: 370, store: 10),

        PackModel(condition: ["M", "白", "USB-A"], price: 380, store: 88),
        PackModel(condition: ["M", "白", "Type-C"], price: 390, store: 40),
        PackModel(condition: ["M", "米兰色", "USB-A"], price: 400, store: 0),
        PackModel(condition: ["M", "米兰色", "Type-C"], price: 388, store: 12),
        PackModel(condition: ["M", "灰", "USB-A"], price: 410, store: 55),
        PackModel(condition: ["M", "灰", "Type-C"], price: 420, store: 25),
        PackModel(condition: ["M", "绿", "USB-A"], price: 430, store: 15),
        PackModel(condition: ["M", "绿", "Type-C"], price: 440, store: 5),

        PackModel(condition: ["L", "白", "USB-A"], price: 199, store: 8),
        PackModel(condition: ["L", "白", "Type-C"], price: 210, store: 18),
        PackModel(condition: ["L", "米兰色", "USB-A"], price: 220, store: 28),
        PackModel(condition: ["L", "米兰色", "Type-C"], price: 230, store: 38),
        PackModel(condition: ["L", "灰", "USB-A"], price: 112, store: 9),
        PackModel(condition: ["L", "灰", "Type-C"], price: 333, store: 99),
        PackModel(condition: ["L", "绿", "USB-A"], price: 250, store: 48),
        PackModel(condition: ["L", "绿", "Type-C"], price: 377, store: 10)
    ]
    
    private lazy var filter = SKUFilter(self)
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private func update(result: Pack?) {
        doneButton.isEnabled = result != nil
        priceLabel.text = "价格: \(result?.price ?? 0)"
        storeLabel.text = "库存: \(result?.store ?? 0)"
    }
}

extension ViewController: SKUFilterDelegate {
    func filter(_ filter: SKUFilter, selectedCondition param: Pack?) {
        debugPrint("价格: \(param?.price)")
    }
    
    func numberOfArrtibutes(_ filter: SKUFilter) -> Int {
        return list.count
    }
    
    func arrtibutes(_ filter: SKUFilter, for index: Int) -> [AnyHashable] {
        return list[index].items.map { $0.title }
    }
    
    func numberOfConditions(_ filter: SKUFilter) -> Int {
        return skus.count
    }
    
    func conditions(_ filter: SKUFilter, for index: Int) -> [AnyHashable] {
        return skus[index].condition
    }
    
    func resultOfCondition(_ filter: SKUFilter, for index: Int) -> Pack? {
        return skus[index]
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) as! CollectionViewCell
        
        let title = list[indexPath.section].items[indexPath.item].title
        cell.set(text: title)
        cell.set(enabled: filter.available.contains(indexPath))
        cell.set(selected: filter.selecteds.contains(indexPath))
        cell.setOutOfStock(filter.outOfStocks.contains(indexPath))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "header",
            for: indexPath
        ) as! CollectionReusableView
        
        let title = list[indexPath.section].title
        view.set(text: title)
        return view
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = list[indexPath.section].items[indexPath.item].width
        return CGSize(width: max(width + 20, 50), height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        filter.selected(indexPath)
        collectionView.reloadData()
        update(result: filter.result as? Pack)
    }
}

extension ViewController {
    
    struct Attr {
        let title: String
        let items: [Item]
        
        init(_ title: String, _ items: [Item]) {
            self.title = title
            self.items = items
        }
    }
    
    struct Item {
        let title: String
        let width: Double
        
        init(_ title: String) {
            self.title = title
            self.width = Double(NSString(string: title)
                .boundingRect(
                    with: CGSize(width: 300, height: 50),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 17)],
                    context: nil
                ).width
            )
        }
    }
    

}

struct PackModel: Pack {
    var condition: [String]
    var price: Int
    var store: Int
}
