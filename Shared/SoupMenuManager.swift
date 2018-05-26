/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A DataManager subclass that persists the active menu items.
*/

import Foundation
import Intents
import os.log

public typealias SoupMenu = Set<MenuItem>

public class SoupMenuManager: DataManager<Set<MenuItem>> {
    
    private static let defaultMenu: SoupMenu = [
        MenuItem(itemNameKey: "CHICKEN_NOODLE_SOUP", price: 4.55, iconImageName: "chicken_noodle_soup", isAvailable: false, isDailySpecial: true),
        MenuItem(itemNameKey: "CLAM_CHOWDER", price: 3.75, iconImageName: "new_england_clam_chowder", isAvailable: true, isDailySpecial: false),
        MenuItem(itemNameKey: "TOMATO_SOUP", price: 2.95, iconImageName: "tomato_soup", isAvailable: true, isDailySpecial: false)
    ]
    
    public var orderManager: SoupOrderDataManager?
    
    public convenience init() {
        let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.StorageKeys.soupMenu.rawValue,
                                                        keyPath: \UserDefaults.menu)
        self.init(storageDescriptor: storageInfo)
    }
    
    override func createInitialData() -> Set<MenuItem>! {
        return SoupMenuManager.defaultMenu
    }
}

/// Public API for clients of `SoupMenuManager`
extension SoupMenuManager {
    
    public var dailySpecialItems: [MenuItem] {
        var specials: [MenuItem] = []
        dataAccessQueue.sync {
            specials = managedDataBackingInstance.filter { $0.isDailySpecial == true }
        }
        return specials
    }
    
    public var allRegularItems: [MenuItem] {
        var specials: [MenuItem] = []
        dataAccessQueue.sync {
            specials = managedDataBackingInstance.filter { $0.isDailySpecial == false }
        }
        return specials
    }
    
    public var availableRegularItems: [MenuItem] {
        return allRegularItems.filter { $0.isAvailable == true }
    }
    
    public func replaceMenuItem(_ previousMenuItem: MenuItem, with menuItem: MenuItem) {
        dataAccessQueue.sync {
            managedDataBackingInstance.remove(previousMenuItem)
            managedDataBackingInstance.insert(menuItem)
        }
        
        //  Access to UserDefaults is gated behind a seperate access queue.
        writeData()
        
        // Inform Siri of changes to the menu.
        removeDonation(for: menuItem)
        suggest(menuItem)
    }
    
    public func findItem(identifier: String) -> MenuItem? {
        var matchedItems: [MenuItem] = []
        dataAccessQueue.sync {
            matchedItems = managedDataBackingInstance.filter { $0.itemNameKey == identifier }
        }
        
        return matchedItems.first
    }
}

/// This extension contains supporting methods for using the Intents framework.
extension SoupMenuManager {
    
    /// Each time an order is placed we instantiate an INInteraction object and donate it to the system (see SoupOrderDataManager extension).
    /// After instantiating the INInteraction, it's identifier property is set to the same value as the identifier
    /// property for the corresponding order. Compile a list of all the order identifiers to pass to the INInteraction delete method.
    private func removeDonation(for menuItem: MenuItem) {
        if menuItem.isAvailable == false {
            guard let orderHistory = orderManager?.orderHistory else { return }
            let ordersAssociatedWithRemovedMenuItem = orderHistory.filter { $0.menuItem.itemNameKey == menuItem.itemNameKey }
            let orderIdentifiersToRemove = ordersAssociatedWithRemovedMenuItem.map { $0.identifier.uuidString }
            
            INInteraction.delete(with: orderIdentifiersToRemove) { (error) in
                if error != nil {
                    if let error = error as NSError? {
                        os_log("Failed to delete interactions with error: %@", log: OSLog.default, type: .error, error)
                    }
                } else {
                    os_log("Successfully deleted interactions")
                }
            }
        }
    }
    
    // - CodeListing: relevant_shortcut
    
    /// Configures a daily soup special to be made available as a relevant shortcut. This item
    /// is not available on the regular menu to demonstrate how relevant shortcuts are able to
    /// suggest tasks the user may want to start, but hasn't used in the app before.
    private func suggest(_ menuItem: MenuItem) {
        if menuItem.isDailySpecial && menuItem.isAvailable {
            let order = Order(quantity: 1, menuItem: menuItem, menuItemOptions: [])
            let orderIntent = order.intent
            
            guard let shortcut = INShortcut(intent: orderIntent) else { return }
            let suggestedShortcut = INRelevantShortcut(shortcut: shortcut)
            
            let localizedTitle = NSLocalizedString("ORDER_LUNCH_TITLE", bundle: Bundle.soupKitBundle, comment: "Relevant shortcut title")
            let template = INDefaultCardTemplate(title: localizedTitle)
            template.subtitle = menuItem.itemNameKey
            
            if let image = UIImage(named: menuItem.iconImageName),
                let data = image.pngData() {
                template.image = INImage(imageData: data)
            }
            
            suggestedShortcut.watchTemplate = template
                        
            // Make a lunch suggestion when arriving to work.
            let routineRelevanceProvider = INDailyRoutineRelevanceProvider(situation: .work)

            // This sample uses a single relevance provider, but using multiple relevance providers is supported.
            suggestedShortcut.relevanceProviders = [routineRelevanceProvider]
            INRelevantShortcutStore.default.setRelevantShortcuts([suggestedShortcut]) { (error) in
                if let error = error as NSError? {
                    os_log("Providing relevant shortcut failed. \n%@", log: OSLog.default, type: .error, error)
                } else {
                    os_log("Prvoding relevant shortcut succeeded.")
                }
            }
        }
    }
}

/// Enables observation of `UserDefaults` for the `soupMenuStorage` key.
private extension UserDefaults {
    
    @objc var menu: Data? {
        return data(forKey: StorageKeys.soupMenu.rawValue)
    }
}
