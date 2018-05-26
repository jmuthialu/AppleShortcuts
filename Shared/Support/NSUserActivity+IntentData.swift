/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience utility for working with NSUserActivity.
*/

import Foundation
#if os(iOS)
    import CoreSpotlight
    import UIKit
#endif

extension NSUserActivity {
    
    public struct ActivityKeys {
        public static let menuItems = "menuItems"
        public static let segueId = "segueID"
    }
    
    private static let searchableItemContentType = "Soup Menu"
    
    public static let viewMenuActivityType = "com.example.apple-samplecode.SoupChef.viewMenu"
    
    public static var viewMenuActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: NSUserActivity.viewMenuActivityType)
        
        // User activites should be as rich as possible, with icons and localized strings for appropiate content attributes.
        userActivity.title = NSLocalizedString("ORDER_LUNCH_TITLE", bundle: Bundle.soupKitBundle, comment: "View menu activity title")
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        
    #if os(iOS)
        let attributes = CSSearchableItemAttributeSet(itemContentType: NSUserActivity.searchableItemContentType)
        attributes.thumbnailData = #imageLiteral(resourceName: "tomato").pngData() // Used as an icon in Search.
        attributes.keywords = userActivity.viewMenuSearchableKeywords
        attributes.displayName = NSLocalizedString("ORDER_LUNCH_TITLE", bundle: Bundle.soupKitBundle, comment: "View menu activity title")
        let description = NSLocalizedString("VIEW_MENU_CONTENT_DESCRIPTION", bundle: Bundle.soupKitBundle, comment: "View menu content description")
        attributes.contentDescription = description
        
        userActivity.contentAttributeSet = attributes
    #endif
        
        let phrase = NSLocalizedString("ORDER_LUNCH_SUGGESTED_PHRASE", bundle: Bundle.soupKitBundle, comment: "Voice shortcut suggested phrase")
        userActivity.suggestedInvocationPhrase = phrase
        return userActivity
    }
    
    private var viewMenuSearchableKeywords: [String] {
        return [NSLocalizedString("ORDER", bundle: Bundle.soupKitBundle, comment: "Searchable keyword"),
                NSLocalizedString("SOUP", bundle: Bundle.soupKitBundle, comment: "Searchable keyword"),
                NSLocalizedString("MENU", bundle: Bundle.soupKitBundle, comment: "Searchable keyword")
        ]
    }
}
