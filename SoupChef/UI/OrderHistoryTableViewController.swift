/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class displays a list of previously placed orders.
*/

import UIKit
import IntentsUI
import SoupKit
import os.log

class SoupOrderDetailCell: UITableViewCell {
    static let reuseIdentifier = "SoupOrderDetailCell"
    @IBOutlet weak var detailView: MenuItemView!
}

class OrderHistoryTableViewController: UITableViewController {

    public enum SegueIdentifiers: String {
        case orderDetails = "Order Details"
        case soupMenu = "Soup Menu"
        case configureMenu = "Configure Menu"
    }
    
    let soupMenuManager = SoupMenuManager()
    let soupOrderDateManager = SoupOrderDataManager()
    let voiceShortcutManager = VoiceShortcutDataManager()
    var notificationToken: NSObjectProtocol?
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        return formatter
    }()
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationToken = NotificationCenter.default.addObserver(forName: dataChangedNotificationKey,
                                                                   object: soupOrderDateManager,
                                                                   queue: OperationQueue.main) {  [weak self] (notification) in
                                                                    self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: - Target Action

    // This IBAction exposes a segue in the storyboard to unwind to this VC.
    @IBAction func unwindToOrderHistory(segue: UIStoryboardSegue) {}

    @IBAction func placeNewOrder(segue: UIStoryboardSegue) {
        if let source = segue.source as? OrderDetailViewController {
            soupOrderDateManager.placeOrder(order: source.order)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.orderDetails.rawValue {
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows,
                let selectedIndexPath = selectedIndexPaths.first,
                let destination = segue.destination as? OrderDetailViewController {
                destination.configure(tableConfiguration: OrderDetailTableConfiguration(orderType: .historical),
                                      order: soupOrderDateManager.orderHistory[selectedIndexPath.row],
                                      voiceShortcutDateManager: voiceShortcutManager)
            }
        } else if segue.identifier == SegueIdentifiers.configureMenu.rawValue {
            if let navCon = segue.destination as? UINavigationController,
                let configureMenuTableViewController = navCon.viewControllers.first as? ConfigureMenuTableViewController {
                configureMenuTableViewController.soupMenuManager = soupMenuManager
                configureMenuTableViewController.soupOrderDataManager = soupOrderDateManager
            }
        }
    }
}

extension OrderHistoryTableViewController {

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soupOrderDateManager.orderHistory.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SoupOrderDetailCell.reuseIdentifier,
                                                       for: indexPath) as? SoupOrderDetailCell else {
                                                        os_log("Failed to downcast UITableViewCell as SoupOrderDetailCell. Check Main.storyboard.")
                                                        return UITableViewCell()
        }
        let order = soupOrderDateManager.orderHistory[indexPath.row]
        cell.detailView.imageView.image = UIImage(named: order.menuItem.iconImageName)
        cell.detailView.titleLabel.text = "\(order.quantity) \(order.menuItem.localizedString)"
        cell.detailView.subTitleLabel.text = dateFormatter.string(from: order.date)
        return cell
    }
}
