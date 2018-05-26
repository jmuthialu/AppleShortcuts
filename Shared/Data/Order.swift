/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This type encapsulates the attributes of a soup order.
*/

import Foundation
import Intents

public struct Order: Codable {
    
    public enum MenuItemOption: String, Codable, LocalizableString {
        case cheese = "CHEESE"
        case redPepper = "RED_PEPPER"
        case croutons = "CROUTONS"

        public static let all: [MenuItemOption] = [.cheese, .redPepper, .croutons]

        public var localizedString: String {
            let usageComment = "UI representation for MenuItemOption value: \(self.rawValue)"
            return NSLocalizedString(self.rawValue, bundle: Bundle.soupKitBundle, comment: usageComment)
        }
    }

    public let date: Date
    public let identifier: UUID
    public let menuItem: MenuItem
    public var quantity: Int
    public var menuItemOptions: Set<MenuItemOption>
    public var total: Decimal {
        return Decimal(quantity) * menuItem.price
    }
    
    public init(date: Date = Date(), identifier: UUID = UUID(), quantity: Int, menuItem: MenuItem, menuItemOptions: Set<MenuItemOption>) {
        self.date = date
        self.identifier = identifier
        self.quantity = quantity
        self.menuItem = menuItem
        self.menuItemOptions = menuItemOptions
    }
}

extension Order: Equatable {
    
    ///  SoupChef considers orders with the same contents (menuItem, quantity, menuItemOptions) to be identical.
    /// The data and idenfier properties are unique to an instance of an order (regardless of contents) and are not
    /// considered when determining equality.
    public static func ==(lhs: Order, rhs: Order) -> Bool {
        return lhs.menuItem == rhs.menuItem &&
            rhs.quantity == lhs.quantity &&
            rhs.menuItemOptions == lhs.menuItemOptions
    }
}

extension Order: LocalizableCurrency {

    public var localizedCurrencyValue: String {
        return NumberFormatter.currencyFormatter.string(from: total as NSDecimalNumber) ?? ""
    }
    
    public var localizedOptionsArray: [String] {
        var localizedArray = menuItemOptions.map { $0.localizedString }
        
        // Sort in a locale sensitive way.
        localizedArray.sort { (string1, string2) -> Bool in
            return string1.localizedCaseInsensitiveCompare(string2) == ComparisonResult.orderedAscending
        }
        
        return localizedArray
    }

    public var localizedOptionString: String {
        return localizedOptionsArray.joined(separator: ", ")
    }
}

extension Order {
    public var intent: OrderSoupIntent {
        let orderSoupIntent = OrderSoupIntent()
        orderSoupIntent.quantity = quantity as NSNumber
        orderSoupIntent.soup = INObject(identifier: menuItem.itemNameKey, display: menuItem.localizedString)
        
        if let image = UIImage(named: menuItem.iconImageName),
            let data = image.pngData() {
            orderSoupIntent.setImage(INImage(imageData: data), forParameterNamed: "soup")
        }
        
        orderSoupIntent.options = menuItemOptions.map { (option) -> INObject in
            return INObject(identifier: option.rawValue, display: option.localizedString)
        }
        
        let comment = "Suggested phrase for ordering a specific soup"
        let phrase = NSLocalizedString("ORDER_SOUP_SUGGESTED_PHRASE", bundle: Bundle.soupKitBundle, comment: comment)
        orderSoupIntent.suggestedInvocationPhrase = String(format: phrase, menuItem.localizedString)
        
        return orderSoupIntent
    }
    
    public init?(from intent: OrderSoupIntent) {
        let menuManager = SoupMenuManager()
        guard let soupID = intent.soup?.identifier,
            let menuItem = menuManager.findItem(identifier: soupID),
            let quantity = intent.quantity
        else { return nil }

        let rawOptions = intent.options?.compactMap { (option) -> MenuItemOption? in
            guard let optionID = option.identifier else { return nil }
            return MenuItemOption(rawValue: optionID)
        } ?? [MenuItemOption]() // If the result of the map is nil (because `intent.options` is nil), provide an empty array.
        
        self.init(quantity: quantity.intValue, menuItem: menuItem, menuItemOptions: Set(rawOptions))
    }
}
