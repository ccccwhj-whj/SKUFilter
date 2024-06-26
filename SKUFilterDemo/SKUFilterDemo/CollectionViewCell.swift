//
//  CollectionViewCell.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel! {
        didSet {
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 2
            label.layer.borderWidth = 1
        }
    }
    
    @IBOutlet weak var outOfStockLabel: UILabel!
    
    // 设置文本
      func set(text: String) {
          label.text = text
      }
      
    func set(selected: Bool) {
//        backgroundColor = selected ? .blue : .white
        label.layer.borderWidth = selected ? 1 : 0
        label.layer.borderColor = selected ? UIColor.red.cgColor : UIColor.white.cgColor
        label.textColor = selected ? .red : .black
        setOutOfStockSeleted(selected)
    }
    
    func setOutOfStock(_ isOutOfStock: Bool) {
        outOfStockLabel.isHidden = !isOutOfStock
    }
      
    func setOutOfStockSeleted(_ selected: Bool) {
        outOfStockLabel.backgroundColor = selected ? .red : .gray
        outOfStockLabel.textColor = selected ? .white : .black
    }
    
    func set(text: String?) {
        label.text = text
    }
    
    func set(enabled: Bool) {
        label.textColor = enabled ? #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1) : #colorLiteral(red: 0.7098039216, green: 0.7098039216, blue: 0.7098039216, alpha: 1)
        label.backgroundColor = #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
        label.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        setOutOfStock(enabled)
    }
    
//    func set(selected: Bool) {
//        label.textColor = selected ? #colorLiteral(red: 1, green: 0.3137254902, blue: 0, alpha: 1) : label.textColor
//        label.backgroundColor = selected ? #colorLiteral(red: 1, green: 0.9725490196, blue: 0.9764705882, alpha: 1) : #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
//        label.layer.borderColor = selected ? #colorLiteral(red: 1, green: 0.3137254902, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
//    }
}
