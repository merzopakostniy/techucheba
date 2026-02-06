//
//  techuchebaApp.swift
//  techucheba
//
//  Created by Vitalii Bliudenov on 02.06.2025.
//


import SwiftUI
import YandexMobileAds


@main
struct techuchebaApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Инициализация Yandex Mobile Ads SDK
        YMAMobileAds.initializeSDK()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
