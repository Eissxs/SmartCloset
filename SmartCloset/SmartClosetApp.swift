//
//  SmartClosetApp.swift
//  SmartCloset
//
//  Created by Michael Eissen San Antonio on 5/13/25.
//

import SwiftUI
import CoreData

@main
struct SmartClosetApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// Persistence Controller for CoreData
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "SmartCloset")
        
        // Configure store description
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Error loading persistent store: \(error), \(error.userInfo)")
                
                // Handle store loading error by removing the store and trying again
                if error.domain == NSCocoaErrorDomain && error.code == NSPersistentStoreIncompatibleVersionHashError {
                    self.recreateStore()
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable constraint validation
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }
    
    private func recreateStore() {
        // Get the store URL
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return
        }
        
        // Remove the store from the coordinator
        guard let store = container.persistentStoreCoordinator.persistentStore(for: storeURL) else {
            return
        }
        
        do {
            // Remove the store
            try container.persistentStoreCoordinator.remove(store)
            
            // Delete the store file
            try FileManager.default.removeItem(at: storeURL)
            
            // Try loading the store again
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                      configurationName: nil,
                                                                      at: storeURL,
                                                                      options: nil)
        } catch {
            print("Error recreating store: \(error)")
        }
    }
    
    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let controller = PersistenceController()
        
        // Create 10 example items
        for _ in 0..<10 {
            let item = ClosetItem(context: controller.container.viewContext)
            item.id_ = UUID()
            item.category_ = "Tops"
            item.color_ = "Pink"
            item.lastWornDate_ = Date()
            item.timesWorn_ = 0
            item.setValue(false, forKey: "favorite_")
            // Add dummy image data
            item.imageData_ = UIImage(systemName: "tshirt.fill")?.pngData() ?? Data()
        }
        
        return controller
    }()
}
