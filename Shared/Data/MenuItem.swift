/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This type encapsulates the attributes of a soup menu item.
*/

import Foundation

public struct MenuItem: Codable, Hashable, LocalizableString, LocalizableCurrency {
    
    public let itemNameKey: String
    public let price: Decimal
    public let iconImageName: String
    public var isAvailable: Bool
    public let isDailySpecial: Bool
    public init(itemNameKey: String, price: Decimal, iconImageName: String, isAvailable: Bool, isDailySpecial: Bool) {
        self.itemNameKey = itemNameKey
        self.price = price
        self.iconImageName = iconImageName
        self.isAvailable = isAvailable
        self.isDailySpecial = isDailySpecial
    }
    
    public var localizedCurrencyValue: String {
        return NumberFormatter.currencyFormatter.string(from: price as NSDecimalNumber) ?? ""
    }
    
    public var localizedString: String {
        return NSLocalizedString(itemNameKey, bundle: Bundle.soupKitBundle, comment: "Menu item title")
    }
}
