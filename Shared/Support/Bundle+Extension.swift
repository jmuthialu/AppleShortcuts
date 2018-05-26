/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility for determining the current bundle.
*/

import Foundation

extension Bundle {
    public static var soupKitBundle: Bundle {
        // The bundle will change depending if the framework is for iOS or watchOS.
        return Bundle(for: VoiceShortcutDataManager.self)
    }
}
