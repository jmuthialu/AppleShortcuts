/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import SoupKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// - Tag: handle_in_app_delegate
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let intent = userActivity.interaction?.intent as? OrderSoupIntent {
            handle(intent)
            return true
        } else if userActivity.activityType == NSUserActivity.viewMenuActivityType {
            handleUserActivity()
            return true
        }
        return false
    }
    
    private func handle(_ intent: OrderSoupIntent) {
        let handler = OrderSoupIntentHandler()
        handler.handle(intent: intent) { (response) in
            if response.code != .success {
                os_log("Quantity must be greater than 0 to add to order")
            }
        }
    }
    
    private func handleUserActivity() {
        guard let window = window,
            let rootViewController = window.rootViewController as? UINavigationController,
            let orderHistoryViewController = rootViewController.viewControllers.first as? OrderHistoryTableViewController else {
                os_log("Failed to access OrderHistoryTableViewController.")
                return
        }
        let segue = OrderHistoryTableViewController.SegueIdentifiers.soupMenu.rawValue
        orderHistoryViewController.performSegue(withIdentifier: segue, sender: nil)
    }
}
