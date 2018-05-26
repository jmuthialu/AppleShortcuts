/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A reusable view for displaying menu item details.
*/

import UIKit

@IBDesignable
public class MenuItemView: UIView {
    
    enum SubView: Int {
        case imageView = 777
        case titleLabel = 888
        case subTitleLabel = 999
    }
    
    public var imageView = UIImageView(frame: .zero)
    public var titleLabel: UILabel = UILabel(frame: .zero)
    public var subTitleLabel: UILabel = UILabel(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        setupView()
    }
    
    private func setupView() {
        let bundle = Bundle(for: MenuItemView.self)
        let nib = UINib(nibName: "MenuItemView", bundle: bundle)
        
        guard let stackView = nib.instantiate(withOwner: self, options: nil).first as? UIStackView,
            let imageView = stackView.viewWithTag(SubView.imageView.rawValue) as? UIImageView,
            let titleLabel = stackView.viewWithTag(SubView.titleLabel.rawValue) as? UILabel,
            let subTitleLabel = stackView.viewWithTag(SubView.subTitleLabel.rawValue) as? UILabel else { return }
        
        addSubview(stackView)
        self.imageView = imageView
        self.titleLabel = titleLabel
        self.subTitleLabel = subTitleLabel
        
        self.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 8
    }
}
