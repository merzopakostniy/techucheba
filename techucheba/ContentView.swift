//
//  ContentView.swift
//  techucheba
//
//  Created by Vitalii Bliudenov on 02.06.2025.
//

import SwiftUI
import CoreData
import Foundation
import StoreKit
import YandexMobileAds

enum AppPalette {
    static let bgTop = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let bgBottom = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let accent = Color(red: 0.86, green: 0.27, blue: 0.12)
    static let accent2 = Color(red: 0.96, green: 0.57, blue: 0.12)
    static let surface = Color(red: 0.14, green: 0.15, blue: 0.18)
    static let surfaceStrong = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let stroke = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textMuted = Color.white.opacity(0.6)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [AppPalette.bgTop, AppPalette.bgBottom]), startPoint: .topLeading, endPoint: .bottomTrailing)
            AppPalette.accent.opacity(0.18)
                .blur(radius: 120)
                .offset(x: 120, y: -140)
            AppPalette.accent2.opacity(0.12)
                .blur(radius: 140)
                .offset(x: -120, y: 140)
        }
        .ignoresSafeArea()
    }
}

final class ElectroSafetyInterstitial: NSObject, ObservableObject, InterstitialAdLoaderDelegate, InterstitialAdDelegate {
    private var loader: InterstitialAdLoader?
    private var interstitialAd: InterstitialAd?
    private var isLoading = false
    private var pendingCompletion: (() -> Void)?

    func load() {
        guard !isLoading else { return }
        isLoading = true
        let loader = InterstitialAdLoader()
        loader.delegate = self
        loader.loadAd(with: AdRequestConfiguration(adUnitID: "R-M-15742337-5"))
        self.loader = loader
    }

    func show(onComplete: @escaping () -> Void) {
        if let ad = interstitialAd, let rootVC = Self.rootViewController() {
            pendingCompletion = onComplete
            ad.show(from: rootVC)
        } else {
            load()
            onComplete()
        }
    }

    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didLoad interstitialAd: InterstitialAd) {
        self.interstitialAd = interstitialAd
        interstitialAd.delegate = self
        isLoading = false
    }

    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didFailToLoadWithError error: AdRequestError) {
        isLoading = false
        interstitialAd = nil
    }

    func interstitialAdDidDismiss(_ interstitialAd: InterstitialAd) {
        self.interstitialAd = nil
        finish()
        load()
    }

    func interstitialAd(_ interstitialAd: InterstitialAd, didFailToShowWithError error: Error) {
        self.interstitialAd = nil
        finish()
        load()
    }

    private func finish() {
        let completion = pendingCompletion
        pendingCompletion = nil
        DispatchQueue.main.async {
            completion?()
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}



let depots: [Depot] = [
    Depot(name: "Братеево", qaList: qaBrateevo),
    Depot(name: "Варшавское", qaList: qaVarshavskoe),
    Depot(name: "Владыкино", qaList: qaVladykino),
    Depot(name: "Замоскворецкое", qaList: qaZamoskvoretskoe),
    Depot(name: "Измайлово", qaList: qaIzmailovo),
    Depot(name: "Калужское", qaList: qaKaluzhskoe),
    Depot(name: "Красная Пресня", qaList: qaKrasnayaPresnya),
    Depot(name: "Лихоборы", qaList: qaLikhobory),
    Depot(name: "Митино", qaList: qaMitino),
    Depot(name: "Новогиреево", qaList: qaNovogireevo),
    Depot(name: "Печатники", qaList: qaPechatniki),
    Depot(name: "Планерное", qaList: qaPlanernoe),
    Depot(name: "Свиблово", qaList: qaSviblovo),
    Depot(name: "Северное", qaList: qaSevernoe),
    Depot(name: "Сокол", qaList: qaSokol),
    Depot(name: "Черкизово", qaList: qaCherkizovo),
    Depot(name: "Южное", qaList: qaYuzhnoe),
    //  Depot(name: "Нижегородское", qaList: qaNizhegorodskoe),
    // ... добавь остальные депо ...
]

struct QA: Equatable, Hashable {
    let key: String
    let question: String
    let answer: String
}

struct Depot: Identifiable, Hashable, Equatable {
    let id = UUID()
    let name: String
    let qaList: [QA]
}


struct ContentView: View {
    @State private var selectedDepot: Depot = {
        if let savedName = UserDefaults.standard.string(forKey: "selectedDepotName"),
           let depot = depots.first(where: { $0.name == savedName }) {
            return depot
        }
        return depots[0]
    }()
    @State private var keyInput: String = ""
    @State private var foundQAs: [QA] = []
    @State private var showResult: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var showDepotSheet: Bool = false
    @State private var showInfoSheet: Bool = false // Новое состояние для инфо
    @State private var showElectroSafetySheet: Bool = false
    @StateObject private var electroSafetyInterstitial = ElectroSafetyInterstitial()
    
    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 28) {
                HStack {
                    Button(action: { showDepotSheet = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(AppPalette.accent2)
                            .padding(12)
                            .background(AppPalette.surface)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppPalette.accent2.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: AppPalette.accent2.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            electroSafetyInterstitial.show {
                                showElectroSafetySheet = true
                            }
                        }) {
                            Text("Электробезопасность")
                                .font(.caption.bold())
                                .foregroundColor(AppPalette.accent2)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppPalette.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppPalette.accent2.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: AppPalette.accent2.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(AppPalette.accent2)
                                .padding(12)
                                .background(AppPalette.surface)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppPalette.accent2.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: AppPalette.accent2.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                // Поле ввода ключа
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.surface)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppPalette.accent2.opacity(0.4), lineWidth: 1)
                        TextField("Введите номер вопроса или ключевое слово", text: $keyInput)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .foregroundColor(AppPalette.textPrimary)
                            .font(.body)
                            .focused($isTextFieldFocused)
                            .accentColor(AppPalette.accent2)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                    .frame(height: 42)
                    .shadow(color: AppPalette.accent2.opacity(0.3), radius: 8, x: 0, y: 4)
                    Button(action: {
                        searchQA()
                        isTextFieldFocused = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [AppPalette.accent, AppPalette.accent2]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 42, height: 42)
                                .shadow(color: AppPalette.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                            Image(systemName: "magnifyingglass")
                                .font(.body.bold())
                                .foregroundColor(AppPalette.textPrimary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isTextFieldFocused ? 1.1 : 1.0)
                    .animation(.spring(), value: isTextFieldFocused)
                }
                .padding(.horizontal)
                // Карточка результата
                if showResult {
                    Group {
                        if !foundQAs.isEmpty {
                            ScrollView {
                                VStack(spacing: 24) {
                                    ForEach(foundQAs, id: \ .self) { qa in
                                        QAResultCard(qa: qa)
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            EmptyResultCard()
                                .transition(.opacity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: foundQAs)
                } else {
                    Spacer()
                }
                
                BannerAdView(adUnitID: "R-M-15742337-1")
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.surfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppPalette.stroke, lineWidth: 1.2)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 6)
                    .padding(.horizontal, 16)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            electroSafetyInterstitial.load()
            requestReviewIfNeeded()
        }
        .sheet(isPresented: $showDepotSheet) {
            DepotSheet(selectedDepot: $selectedDepot, showDepotSheet: $showDepotSheet, onDepotChange: {
                showResult = false
                keyInput = ""
                UserDefaults.standard.set(selectedDepot.name, forKey: "selectedDepotName")
            })
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(showInfoSheet: $showInfoSheet)
        }
        .sheet(isPresented: $showElectroSafetySheet) {
            ElectroSafetySheet(showElectroSafetySheet: $showElectroSafetySheet)
        }
    }
    
    private func searchQA() {
        let search = keyInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isKeyOnly = selectedDepot.qaList.contains { $0.key.lowercased() == search }
        if isKeyOnly {
            foundQAs = selectedDepot.qaList.filter { $0.key.lowercased() == search }
        } else {
            foundQAs = selectedDepot.qaList.filter {
            search.isEmpty ||
            $0.key.lowercased().contains(search) ||
            $0.question.lowercased().contains(search) ||
            $0.answer.lowercased().contains(search)
            }
        }
        withAnimation {
            showResult = true
        }
    }

    private func requestReviewIfNeeded() {
        let defaults = UserDefaults.standard
        var launches = defaults.integer(forKey: "appLaunchCount")
        launches += 1
        defaults.set(launches, forKey: "appLaunchCount")

        guard launches == 2 else { return }

        let lastRequested = defaults.double(forKey: "lastReviewRequestDate")
        let now = Date().timeIntervalSince1970
        let sixtyDays: TimeInterval = 60 * 24 * 60 * 60

        guard lastRequested == 0 || (now - lastRequested) >= sixtyDays else { return }

        defaults.set(now, forKey: "lastReviewRequestDate")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> AdView {
        let adSize = BannerAdSize.fixedSize(withWidth: 350, height: 50)
        let adView = AdView(adUnitID: adUnitID, adSize: adSize)
        adView.delegate = context.coordinator
        adView.loadAd()
        return adView
    }

    func updateUIView(_ uiView: AdView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, AdViewDelegate {
        func adViewDidLoad(_ adView: AdView) {
            print("✅ Yandex Ad loaded successfully")
        }
        
        func adViewDidFailLoading(_ adView: AdView, error: Error) {
            print("❌ Yandex Ad failed: \(error.localizedDescription)")
        }
        
        func adViewDidClick(_ adView: AdView) {
            print("👆 Ad clicked")
        }
        
        func adView(_ adView: AdView, willPresentScreen viewController: UIViewController?) {
            print("📱 Ad will present screen")
        }
    }
}

struct ElectroSafetySheet: View {
    @Binding var showElectroSafetySheet: Bool
    @State private var keyInput: String = ""
    @State private var foundQAs: [QA] = []
    @State private var showResult: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 24) {
                HStack {
                    Text("Электробезопасность")
                        .font(.title2.bold())
                        .foregroundColor(AppPalette.textPrimary)
                    Spacer()
                    Button(action: { showElectroSafetySheet = false }) {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(AppPalette.textPrimary)
                            .padding(10)
                            .background(AppPalette.surface)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppPalette.surface)
                            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                        TextField("Введите номер вопроса или ключевое слово", text: $keyInput)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .foregroundColor(AppPalette.textPrimary)
                            .font(.title3)
                            .focused($isTextFieldFocused)
                            .accentColor(AppPalette.accent2)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                    .frame(height: 52)
                    Button(action: {
                        searchQA()
                        isTextFieldFocused = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [AppPalette.accent, AppPalette.accent2]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 52, height: 52)
                                .shadow(color: AppPalette.accent.opacity(0.35), radius: 10, x: 0, y: 6)
                            Image(systemName: "magnifyingglass")
                                .font(.title2.bold())
                                .foregroundColor(AppPalette.textPrimary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isTextFieldFocused ? 1.1 : 1.0)
                    .animation(.spring(), value: isTextFieldFocused)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 1)
                if showResult {
                    Group {
                        if !foundQAs.isEmpty {
                            ScrollView {
                                VStack(spacing: 24) {
                                    ForEach(foundQAs, id: \.self) { qa in
                                        QAResultCard(qa: qa)
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            EmptyResultCard()
                                .transition(.opacity)
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: foundQAs)
                }
                
                BannerAdView(adUnitID: "R-M-15742337-6")
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.surfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppPalette.stroke, lineWidth: 1.2)
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 6)
                    .padding(.horizontal, 16)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func searchQA() {
        let search = keyInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isKeyOnly = qaElectroSafety.contains { $0.key.lowercased() == search }
        if isKeyOnly {
            foundQAs = qaElectroSafety.filter { $0.key.lowercased() == search }
        } else {
            foundQAs = qaElectroSafety.filter {
                search.isEmpty ||
                $0.key.lowercased().contains(search) ||
                $0.question.lowercased().contains(search) ||
                $0.answer.lowercased().contains(search)
            }
        }
        withAnimation {
            showResult = true
        }
    }
}

struct QAResultCard: View {
    let qa: QA
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Вопрос")
                    .font(.subheadline)
                    .foregroundColor(AppPalette.textMuted)
                Text(qa.question)
                    .font(.body)
                    .foregroundColor(AppPalette.textPrimary)
                    .padding(.bottom, 6)
                Divider().background(AppPalette.stroke)
                Text("Ответ")
                    .font(.subheadline)
                    .foregroundColor(AppPalette.accent2)
                Text(qa.answer)
                    .font(.body)
                    .foregroundColor(AppPalette.textPrimary)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppPalette.stroke, lineWidth: 1.5)
            )
            .shadow(color: AppPalette.accent.opacity(0.2), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 24)
            .padding(.top, 2)
        }
    }
}

struct EmptyResultCard: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(AppPalette.accent2)
            Text("Вопрос по ключу не найден")
                .font(.title3.bold())
                .foregroundColor(AppPalette.textPrimary)
            Text("Проверьте правильность ключа или выберите другое депо.")
                .font(.body)
                .foregroundColor(AppPalette.textSecondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppPalette.stroke, lineWidth: 1.5)
        )
        .shadow(color: AppPalette.accent.opacity(0.2), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 24)
        .padding(.top, 2)
    }
}

struct DepotSheet: View {
    @Binding var selectedDepot: Depot
    @Binding var showDepotSheet: Bool
    var onDepotChange: () -> Void
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // УБРАН HStack с крестиком
                VStack(spacing: 0) {
                    Text("Выберите депо")
                        .font(.title2.bold())
                        .foregroundColor(AppPalette.textPrimary)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                    Divider().background(AppPalette.stroke)
                    ScrollView {
                        VStack(spacing: 0) {
                ForEach(depots) { depot in
                    Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedDepot = depot
                        showDepotSheet = false
                        onDepotChange()
                                    }
                    }) {
                        HStack {
                                        Image(systemName: selectedDepot == depot ? "building.2.crop.circle.fill" : "building.2.crop.circle")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundColor(selectedDepot == depot ? AppPalette.accent2 : AppPalette.textMuted)
                                            .scaleEffect(selectedDepot == depot ? 1.15 : 1.0)
                                            .animation(.spring(), value: selectedDepot == depot)
                            Text(depot.name)
                                            .font(.title3.weight(selectedDepot == depot ? .bold : .regular))
                                            .foregroundColor(selectedDepot == depot ? AppPalette.textPrimary : AppPalette.textSecondary)
                                            .padding(.leading, 8)
                                Spacer()
                                        if selectedDepot == depot {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppPalette.accent2)
                                                .font(.system(size: 22, weight: .bold))
                                                .transition(.scale)
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(selectedDepot == depot ? AppPalette.surface : Color.clear)
                                            .shadow(color: selectedDepot == depot ? Color.black.opacity(0.35) : Color.clear, radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(), value: selectedDepot == depot)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(AppPalette.surfaceStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 10)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 18)
            }
        }
    }
}

// Новая вкладка Инфо
struct InfoSheet: View {
    @Binding var showInfoSheet: Bool
    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Информация о приложении")
                            .font(.title2.bold())
                            .foregroundColor(AppPalette.textPrimary)
                        Spacer()
                        Button(action: { showInfoSheet = false }) {
                            Image(systemName: "xmark")
                                .font(.title3.bold())
                                .foregroundColor(AppPalette.textPrimary)
                                .padding(10)
                                .background(AppPalette.surface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
                    Divider().background(AppPalette.stroke)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Как пользоваться:")
                                .font(.headline)
                                .foregroundColor(AppPalette.textPrimary)
                            Text("1. Выберите депо (слева сверху).\n2. Введите номер вопроса (например, П1, М10) или ключевое слово.\n3. Получите ответ.\n\nМожно искать по номеру, части вопроса или ключевому слову.")
                                .font(.body)
                                .foregroundColor(AppPalette.textSecondary)
                            Divider().background(AppPalette.stroke)
                            Text("Электробезопасность:")
                                .font(.headline)
                                .foregroundColor(AppPalette.textPrimary)
                            Text("Кнопка ⚡ открывает раздел «Электробезопасность». В этом разделе поиск выполняется по тексту вопроса и ответу.")
                                .font(.body)
                                .foregroundColor(AppPalette.textSecondary)
                            Divider().background(AppPalette.stroke)
                            Text("Наименования ключей:")
                                .font(.headline)
                                .foregroundColor(AppPalette.textPrimary)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("П — ПТЭ, Пн — Пневматика, М — Механика, У — Управление, А - АТЗ, Э — Электрика, Т — ТРА, ОТ - Охрана Труда, УР")
                                    .font(.body)
                                    .foregroundColor(AppPalette.textSecondary)
                                Text("Пример: П1 — ПТЭ, М10 — Механика, У5 — Управление и т.д.")
                                    .font(.body)
                                    .foregroundColor(AppPalette.textSecondary)
                            }
                            Divider().background(AppPalette.stroke)
                            Text("Совет: если не знаете точный номер, попробуйте ввести часть вопроса или ключевое слово.")
                                .font(.footnote)
                                .foregroundColor(AppPalette.accent2)
                            Divider().background(AppPalette.stroke)
                               HStack {
                                   Image(systemName: "lock.shield")
                                       .foregroundColor(AppPalette.textSecondary)
                                   Link("Политика конфиденциальности", destination: URL(string: "https://github.com/merzopakostniy/Metrotest/issues/1")!)
                                       .font(.footnote.bold())
                                       .foregroundColor(AppPalette.accent2)
                               }
                               .padding(.top, 8)
                           }
                        }
                        .padding(24)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(AppPalette.surfaceStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 10)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 18)
        }
    }
}



#Preview {
    ContentView()
}
