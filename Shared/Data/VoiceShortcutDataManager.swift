/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data manager that surfaces INVoiceShortcuts managed by INVoiceShortcutCenter.
*/

import Foundation
import Intents
import os.log

public class VoiceShortcutDataManager {
    
    private var voiceShortcuts: [INVoiceShortcut] = []
    
    public init() {
        updateVoiceShortcuts(completion: nil)
    }
    
    public func voiceShortcut(for order: Order) -> INVoiceShortcut? {
        let voiceShorcut = voiceShortcuts.first { (voiceShortcut) -> Bool in
            guard let intent = voiceShortcut.__shortcut.intent as? OrderSoupIntent,
                let orderFromIntent = Order(from: intent)else {
                return false
            }
            return order == orderFromIntent
        }
        return voiceShorcut
    }
    
    public func updateVoiceShortcuts(completion: (() -> Void)?) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcutsFromCenter, error) in
            guard let voiceShortcutsFromCenter = voiceShortcutsFromCenter else {
                if let error = error as NSError? {
                    os_log("Failed to fetch voice shortcuts with error: %@", log: OSLog.default, type: .error, error)
                }
                return
            }
            self.voiceShortcuts = voiceShortcutsFromCenter
            if let completion = completion {
                completion()
            }
        }
    }
}
