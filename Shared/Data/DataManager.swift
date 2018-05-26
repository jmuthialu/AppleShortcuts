/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data manager that manages data conforming to `Codable` and stores it in `UserDefaults`.
*/

import Foundation
import os.log

/// Provides storage configuration information to `DataManager`
struct UserDefaultsStorageDescriptor {
    /// A `String` value used as the key name when reading and writing to `UserDefaults`
    let key: String
    
    /// A key path to a property on `UserDefaults` for observing changes
    let keyPath: KeyPath<UserDefaults, Data?>
}

/// Clients of `DataManager` that want to know when the data changes can listen for this notification.
public let dataChangedNotificationKey = NSNotification.Name(rawValue: "DataChangedNotification")

/// `DataManager` is an abstract class manging data conforming to `Codable` that is saved to `UserDefaults`.
public class DataManager<ManagedDataType: Codable> {
    
    /// This sample uses App Groups to share a suite of data between the main app and the different extensions.
    let userDefaults = UserDefaults.dataSuite
    
    /// To prevent data races, all access to `UserDefaults` uses this queue.
    private let userDefaultsAccessQueue = DispatchQueue(label: "User Defaults Access Queue")
    
    /// Storage and observation information.
    private let storageDescriptor: UserDefaultsStorageDescriptor
    
    /// A flag to avoid receiving notifications about data this instance just wrote to `UserDefaults`.
    private var ignoreLocalUserDefaultsChanges = false
    
    /// The observer object handed back after registering to observe a property.
    private var userDefaultsObserver: NSKeyValueObservation?
    
    /// The data managed by this `DataManager`.
    var managedDataBackingInstance: ManagedDataType!
    
    /// Access to `managedDataBackingInstance` needs to occur on a dedicated queue to avoid data races.
    let dataAccessQueue = DispatchQueue(label: "Data Access Queue")
    
    /// Public access to the managed data for clients of `DataManager`
    public var managedData: ManagedDataType! {
        var data: ManagedDataType!
        dataAccessQueue.sync {
            data = managedDataBackingInstance
        }
        
        return data
    }
    
    init(storageDescriptor: UserDefaultsStorageDescriptor) {
        self.storageDescriptor = storageDescriptor
        loadData()
        
        if managedDataBackingInstance == nil {
            managedDataBackingInstance = createInitialData()
            writeData()
        }
        
        observeChangesInUserDefaults()
    }
    
    /// Creates the starter data. Subclasses are expected to implement this method and provide their own initial data.
    /// The data returned from this method is saved to `UserDefaults`.
    func createInitialData() -> ManagedDataType! {
        return nil
    }
    
    private func observeChangesInUserDefaults() {
        userDefaultsObserver = userDefaults.observe(storageDescriptor.keyPath) { [weak self] (_, _) in
            // Ignore any change notifications coming from data this instance just saved to `UserDefaults`.
            guard self?.ignoreLocalUserDefaultsChanges == false else { return }
            
            // The underlying data changed in `UserDefaults`, so update this instance with the change and notify clients of the change.
            self?.loadData()
            self?.notifyClientsDataChanged()
        }
    }
    
    /// Notifies clients the data changed by posting a `Notification` with the key `dataChangedNotificationKey`
    private func notifyClientsDataChanged() {
        NotificationCenter.default.post(Notification(name: dataChangedNotificationKey, object: self))
    }
    
    /// Loads the data from `UserDefaults`.
    private func loadData() {
        userDefaultsAccessQueue.sync {
            if let archivedData = userDefaults.data(forKey: storageDescriptor.key) {
                
                do {
                    let decoder = PropertyListDecoder()
                    managedDataBackingInstance = try decoder.decode(ManagedDataType.self, from: archivedData)
                } catch {
                    if let error = error as NSError? {
                        os_log("Error initializing NSKeyedArchiver: %@", log: OSLog.default, type: .error, error)
                    }
                }
            }
        }
    }
    
    /// Writes the data to `UserDefaults`.
    func writeData() {
        userDefaultsAccessQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let encodedData = try encoder.encode(self.managedDataBackingInstance)
                
                self.ignoreLocalUserDefaultsChanges = true
                self.userDefaults.set(encodedData, forKey: self.storageDescriptor.key)
                self.ignoreLocalUserDefaultsChanges = false
                
                self.notifyClientsDataChanged()
                
            } catch let error {
                fatalError("Could not save data. Reason: \(error)")
            }
        }
    }
}
