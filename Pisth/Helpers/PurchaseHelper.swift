// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import SwiftyStoreKit
import StoreKit

/// Products ID registered in iTunes Connect for Pisth.
enum ProductsID: String {
    
    /// Terminal themes.
    case themes = "ch.marcela.ada.Pisth.themes"
}

/// Helper to implement in app purchases.
class Product {
    
    /// If the product ID is valid.
    private var isValid_ = true
    
    /// If the product ID is valid.
    var isValid: Bool {
        return isValid_
    }
    
    /// Error retrieving product.
    private var error_: Error?
    
    /// Error retrieving product.
    var error: Error? {
        return error_
    }
    
    /// Store kit product.
    private var skProduct_: SKProduct?
    
    /// Store kit product.
    var skProduct: SKProduct? {
        return skProduct_
    }
    
    /// Product ID.
    private var productID: String
    
    /// Product's price.
    private var price_: String?
    
    /// Product's price.
    var price: String? {
        return price_
    }
    
    /// Init class with given product id.
    ///
    /// - Parameters:
    ///     - productID: Product ID registered in iTunes Connect.
    init(productID: String) {
        self.productID = productID
        
        SwiftyStoreKit.retrieveProductsInfo([productID]) { (result) in
            if let error = result.error {
                self.error_ = error
            } else if !result.invalidProductIDs.isEmpty {
                self.isValid_ = false
            } else if let product = result.retrievedProducts.first {
                self.skProduct_ = product
                self.price_ = product.localizedPrice
            } else {
                self.isValid_ = false
            }
        }
    }
    
    /// Purchase product.
    ///
    /// - Parameters:
    ///     - completion: Code to execute after purchasing product with given result.
    func purchase(completion: ((PurchaseResult) -> Void)?) {
        if let product = skProduct {
            SwiftyStoreKit.purchaseProduct(product, completion: { (result) in
                completion?(result)
            })
        }
    }
    
    // MARK: - Static
    
    /// Returns alert for given result.
    ///
    /// - Parameters:
    ///     - result: Given result. If product needs to finish the transaction, the transaction will be finished.
    ///     - completion: Code to execute after pressing the "Ok" button if the purchase was made. Use this block to enable the feature.
    static func alert(withPurchaseResult result: PurchaseResult, completion: (() -> Void)?) -> UIAlertController? {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        var success = false
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
            if success {
                completion?()
            }
        }))
        
        switch result {
        case .error(let error):
            alert.title = "Error purchasing product!"
            alert.message = error.localizedDescription
            
            if error.code == .paymentCancelled {
                return nil
            }
        case .success(let product):
            
            success = true
            
            if product.needsFinishTransaction {
                SwiftyStoreKit.finishTransaction(product.transaction)
            }
            
            alert.title = "Product purchased!"
            alert.message = "Thanks for purchasing."
        }
        
        return alert
    }
    
    /// Restore purchases and complete transactions if needed.
    ///
    /// - Parameters:
    ///     - completion: Code called after restoring purchases with given results. Use this block to enable features.
    static func restorePurchases(completion: ((RestoreResults) -> Void)?) {
        SwiftyStoreKit.restorePurchases { (results) in
            
            for purchase in results.restoredPurchases {
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            
            completion?(results)
        }
    }
    
    // MARK: - Registered products
    
    /// Initialize registered products.
    static func initProducts() {
        let _ = terminalThemes
    }
    
    /// Terminal themes product.
    static let terminalThemes = Product(productID: ProductsID.themes.rawValue)
}
