/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller displays the list of active menu items to the user.
*/

import UIKit
import SoupKit
import os.log

class SoupMenuItemDetailCell: UITableViewCell {
    static let reuseIdentifier = "SoupMenuItemDetailCell"
    @IBOutlet weak var detailView: MenuItemView!
}

class SoupMenuViewController: UITableViewController {
    
    public var menuItems: [MenuItem] = SoupMenuManager().availableRegularItems

    override func viewDidLoad() {
        super.viewDidLoad()
        userActivity = NSUserActivity.viewMenuActivity
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        let userInfo: [String: Any] =  [NSUserActivity.ActivityKeys.menuItems: menuItems.map { $0.itemNameKey },
                                             NSUserActivity.ActivityKeys.segueId: "Soup Menu"]
        
        activity.addUserInfoEntries(from: userInfo)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show New Order Detail Segue" {
            guard let destination = segue.destination as? OrderDetailViewController,
                let indexPath = (tableView.indexPathForSelectedRow) else {
                    return
            }
            // Pass the represented menu item to NewOrderDetailViewController.
            let orderType = OrderDetailTableConfiguration(orderType: .new)
            let newOrder = Order(quantity: 0, menuItem: menuItems[indexPath.row], menuItemOptions: [])
            destination.configure(tableConfiguration: orderType, order: newOrder, voiceShortcutDateManager: nil)
        }
    }
}

extension SoupMenuViewController {
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SoupMenuItemDetailCell.reuseIdentifier,
                                                       for: indexPath) as? SoupMenuItemDetailCell else {
                                                        os_log("Failed to downcast UITableViewCell as SoupMenuItemDetailCell. Check Main.storyboard.")
                                                        return UITableViewCell()
        }
        let menuItem = menuItems[indexPath.row]
        cell.detailView.imageView.image = UIImage(named: menuItem.iconImageName)
        cell.detailView.titleLabel.text = menuItems[indexPath.row].localizedString
        return cell
    }
}
