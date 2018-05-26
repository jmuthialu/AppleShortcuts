/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility for requesting localized strings for the user interface.
*/

import Foundation

/// A type with a localized string that is appropiate to display in UI.
protocol LocalizableString {
    var localizedString: String { get }
}

/// A type with a localized currency string that is appropiate to display in UI.
protocol LocalizableCurrency {
    var localizedCurrencyValue: String { get }
}
