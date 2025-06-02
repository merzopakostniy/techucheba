//
//  techuchebaApp.swift
//  techucheba
//
//  Created by Vitalii Bliudenov on 02.06.2025.
//

import SwiftUI

@main
struct techuchebaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
