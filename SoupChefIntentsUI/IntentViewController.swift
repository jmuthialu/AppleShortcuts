/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Create a custom user interface that shows in the Siri interface, as well as with 3D touches on a shortcut on the Cover Sheet or in Spotlight.
*/

import IntentsUI
import SoupKit

class IntentViewController: UIViewController {
    
    private let menuManager = SoupMenuManager()
    
    @IBOutlet weak var invoiceView: InvoiceView!
    @IBOutlet weak var confirmationView: ConfirmOrderView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var unitPriceLabel: UILabel!
    @IBOutlet weak var optionsLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
}

extension IntentViewController: INUIHostedViewControlling {
    
    /// Prepare your view controller for displaying the details of the soup order.
    func configureView(for parameters: Set<INParameter>,
                       of interaction: INInteraction,
                       interactiveBehavior: INUIInteractiveBehavior,
                       context: INUIHostedViewContext,
                       completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        
        guard let intent = interaction.intent as? OrderSoupIntent,
            let order = Order(from: intent)
        else {
            completion(false, Set(), .zero)
            return
        }
        
        for view in view.subviews {
            view.removeFromSuperview()
        }
        
        // Different UIs can be displayed depending if the intent is in the confirmation phase or the handle phase.
        var desiredSize = CGSize.zero
        if interaction.intentHandlingStatus == .ready {
            desiredSize = displayInvoice(for: order, from: intent)
        } else if interaction.intentHandlingStatus == .success {
            if let response = interaction.intentResponse as? OrderSoupIntentResponse {
                desiredSize = displayOrderConfirmation(for: order, from: intent, with: response)
            }
        }
        completion(true, parameters, desiredSize)
    }
    
    /// - Returns: Desired size of the view
    private func displayInvoice(for order: Order, from intent: OrderSoupIntent) -> CGSize {
        invoiceView.itemNameLabel.text = order.menuItem.localizedString
        invoiceView.totalPriceLabel.text = order.localizedCurrencyValue
        invoiceView.unitPriceLabel.text = "\(order.quantity) @ \(order.menuItem.localizedCurrencyValue)"
        
        let intentImage = intent.image(forParameterNamed: "soup")
        intentImage?.fetchUIImage { [weak self] (image) in
            DispatchQueue.main.async {
                self?.invoiceView.imageView.image = image
            }
        }
        
        let optionText = intent.options != nil ? order.localizedOptionString : ""
        invoiceView.optionsLabel.text = optionText
        
        view.addSubview(invoiceView)
        
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        let frame = CGRect(origin: .zero, size: CGSize(width: width, height: 170))
        invoiceView.frame = frame
        
        return frame.size
    }
    
    /// - Returns: Desired size of the view
    private func displayOrderConfirmation(for order: Order, from intent: OrderSoupIntent, with response: OrderSoupIntentResponse) -> CGSize {
        confirmationView.itemNameLabel.text = order.menuItem.localizedString
        confirmationView.totalPriceLabel.text = order.localizedCurrencyValue
        confirmationView.imageView.layer.cornerRadius = 8
        if let waitTime = response.waitTime {
            confirmationView.timeLabel.text = "\(waitTime) Minutes"
        }

        let intentImage = intent.image(forParameterNamed: "soup")
        intentImage?.fetchUIImage { [weak self] (image) in
            DispatchQueue.main.async {
                self?.invoiceView.imageView.image = image
            }
        }

        view.addSubview(confirmationView)
        
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        let frame = CGRect(origin: .zero, size: CGSize(width: width, height: 170))
        confirmationView.frame = frame
        
        return frame.size
    }
}
