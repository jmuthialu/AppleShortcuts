/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class shows soup order details. It can be configured for two possible order types.
 When configured with a 'new' order type, the view controller collects details of a new order.
 When configured with a 'historical' order type, the view controller displays details of a previously placed order.
*/

import UIKit
import SoupKit
import os.log
import IntentsUI

class QuantityCell: UITableViewCell {
    static let reuseIdentifier = "Quantity Cell"
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
}

class OrderDetailViewController: UITableViewController {
    
    private(set) var order: Order!
    
    private var tableConfiguration: OrderDetailTableConfiguration = OrderDetailTableConfiguration(orderType: .new)
    
    private weak var quantityLabel: UILabel?
    
    private weak var totalLabel: UILabel?
    
    private var optionMap: [String: String] = [:]
    
    private var voiceShortcutDataManager: VoiceShortcutDataManager?
    
    @IBOutlet var tableViewHeader: UIView!
    
    @IBOutlet weak var soupDetailView: MenuItemView!
    
    // MARK: - Setup Order Detail View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if tableConfiguration.orderType == .historical {
            navigationItem.rightBarButtonItem = nil
        }
        configureTableViewHeader()
    }
    
    private func configureTableViewHeader() {
        soupDetailView.imageView.image = UIImage(named: order.menuItem.iconImageName)
        soupDetailView.titleLabel.text = order.menuItem.localizedString
        tableView.tableHeaderView = tableViewHeader
    }
    
    public func configure(tableConfiguration: OrderDetailTableConfiguration, order: Order, voiceShortcutDateManager: VoiceShortcutDataManager?) {
        self.tableConfiguration = tableConfiguration
        self.order = order
        self.voiceShortcutDataManager = voiceShortcutDateManager
    }
    
    // MARK: - Target Action
    
    @IBAction func placeOrder(_ sender: UIBarButtonItem) {
        if order.quantity == 0 {
            os_log("Quantity must be greater than 0 to add to order")
            return
        }
        performSegue(withIdentifier: "Place Order Segue", sender: self)
    }
    
    @IBAction func stepperDidChange(_ sender: UIStepper) {
        order.quantity = Int(sender.value)
        quantityLabel?.text = "\(order.quantity)"
        updateTotalLabel()
    }
    
    private func updateTotalLabel() {
        totalLabel?.text = NumberFormatter.currencyFormatter.string(from: (order.total as NSDecimalNumber))
    }
    
    func updateVoiceShortcuts() {
        voiceShortcutDataManager?.updateVoiceShortcuts { [weak self] in
            let indexPath = IndexPath(row: 0, section: 3)
            DispatchQueue.main.async {
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension OrderDetailViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableConfiguration.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableConfiguration.sections[section].rowCount
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableConfiguration.sections[section].type.rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionModel = tableConfiguration.sections[indexPath.section]
        let reuseIdentifier = sectionModel.cellReuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configure(cell: cell, at: indexPath, with: sectionModel)
        return cell
    }
    
    private func configure(cell: UITableViewCell, at indexPath: IndexPath, with sectionModel: OrderDetailTableConfiguration.SectionModel) {
        switch sectionModel.type {
        case .price:
            cell.textLabel?.text = NumberFormatter.currencyFormatter.string(from: (order.menuItem.price as NSDecimalNumber))
        case .quantity:
            if let cell = cell as? QuantityCell {
                if tableConfiguration.orderType == .new {
                    // Save a weak reference to the quantityLabel for quick udpates, later.
                    quantityLabel = cell.quantityLabel
                    cell.stepper.addTarget(self, action: #selector(OrderDetailViewController.stepperDidChange(_:)), for: .valueChanged)
                } else {
                    cell.quantityLabel.text = "\(order.quantity)"
                    cell.stepper.isHidden = true
                }
            }
        case .options:
            /*
             Maintain a mapping of [rawValue: localizedValue] in order to help instanitate Order.MenuItemOption enum
             later when an option is selected in the table view.
             */
            let option = Order.MenuItemOption.all[indexPath.row]
            let localizedValue = option.localizedString.capitalized
            optionMap[localizedValue] = option.rawValue
            
            cell.textLabel?.text = localizedValue
            
            if tableConfiguration.orderType == .historical {
                cell.accessoryType = order.menuItemOptions.contains(option) ? .checkmark : .none
            }
        case .total:
            //  Save a weak reference to the totalLabel for making quick updates later.
            totalLabel = cell.textLabel
            
            updateTotalLabel()
        case .voiceShortcut:
            cell.textLabel?.textColor = tableView.tintColor
            if let shortcut = voiceShortcutDataManager?.voiceShortcut(for: order) {
                cell.textLabel?.text = "“\(shortcut.invocationPhrase)”"
            } else {
                cell.textLabel?.text = "Add to Siri"
            }
        }
    }
}

extension OrderDetailViewController {
    
    // MARK: - Table view delegate

    /// - Tag: add_edit_phrases
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableConfiguration.sections[indexPath.section].type == .options && tableConfiguration.orderType == .new {
            
            guard let cell = tableView.cellForRow(at: indexPath),
                let cellText = cell.textLabel?.text,
                let optionRawValue = optionMap[cellText],
                let option = Order.MenuItemOption(rawValue: optionRawValue) else { return }
            
            if order.menuItemOptions.contains(option) {
                order.menuItemOptions.remove(option)
                cell.accessoryType = .none
            } else {
                order.menuItemOptions.insert(option)
                cell.accessoryType = .checkmark
            }
        } else if tableConfiguration.sections[indexPath.section].type == .voiceShortcut {
            if let shortcut = voiceShortcutDataManager?.voiceShortcut(for: order) {
                let editVoiceShortcutViewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)
                
                editVoiceShortcutViewController.delegate = self
                present(editVoiceShortcutViewController, animated: true, completion: nil)
            } else {
                // Since the app isn't yet managing a voice shortcut for this order, present the add view controller.
                if let shortcut = INShortcut(intent: order.intent) {
                    let addVoiceShortcutVC = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                    addVoiceShortcutVC.delegate = self
                    present(addVoiceShortcutVC, animated: true, completion: nil)
                }
            }
        }
    }
}

extension OrderDetailViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    // MARK: - INUIAddVoiceShortcutViewControllerDelegate
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            os_log("error adding voice shortcut: %@", log: OSLog.default, type: .error, error)
            return
        }
        updateVoiceShortcuts()
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    // MARK: - INUIEditVoiceShortcutViewControllerDelegate
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            os_log("error adding voice shortcut: %@", log: OSLog.default, type: .error, error)
            return
        }
        updateVoiceShortcuts()
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        updateVoiceShortcuts()
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
}
