//
//  ContentView.swift
//  techucheba
//
//  Created by Vitalii Bliudenov on 02.06.2025.
//

import SwiftUI
import CoreData
import YandexMobileAds
import Foundation




let depots: [Depot] = [
    Depot(name: "Владыкино", qaList: qaVladykino),
    Depot(name: "Варшавское", qaList: qaVarshavskoe),
    Depot(name: "Замоскворецкое", qaList: qaZamoskvoretskoe),
    Depot(name: "Новогиреево", qaList: qaNovogireevo),
    Depot(name: "Свиблово", qaList: qaSviblovo),
    Depot(name: "Северное", qaList: qaSevernoe),
    Depot(name: "Братеево", qaList: qaBrateevo),
    Depot(name: "Сокол", qaList: qaSokol),
    Depot(name: "Печатники", qaList: qaPechatniki),
    Depot(name: "Измайлово", qaList: qaIzmailovo),
    Depot(name: "Черкизово", qaList: qaCherkizovo),
    Depot(name: "Красная Пресня", qaList: qaKrasnayaPresnya),
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


 struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> AdView {
        let adView = AdView(adUnitID: "R-M-15742337-1", adSize: .fixedSize(withWidth: 350, height: 50))
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
            print("Ad loaded")
        }
        func adView(_ adView: AdView, didFailLoadingWithError error: Error) {
            print("Ad failed: \(error.localizedDescription)")
        }
    }
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
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Color.white.opacity(0.1)
                .ignoresSafeArea()
                .blur(radius: 40)
            VStack(spacing: 28) {
                HStack {
                    Button(action: { showDepotSheet = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    Spacer()
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                // Поле ввода ключа
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        TextField("Введите номер вопроса или ключевое слово", text: $keyInput)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .font(.title3)
                            .focused($isTextFieldFocused)
                            .accentColor(.white)
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
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 52, height: 52)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            Image(systemName: "magnifyingglass")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isTextFieldFocused ? 1.1 : 1.0)
                    .animation(.spring(), value: isTextFieldFocused)
                }
                .padding(.horizontal)
                // Карточка результата
                Spacer(minLength: 1)
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
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: foundQAs)
                }
                
                BannerAdView()
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
            }
        }
        .ignoresSafeArea(.keyboard)
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
}

struct QAResultCard: View {
    let qa: QA
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Вопрос")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                Text(qa.question)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                Divider().background(Color.white.opacity(0.3))
                Text("Ответ")
                    .font(.subheadline)
                    .foregroundColor(.green.opacity(0.8))
                Text(qa.answer)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(28)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: Color.purple.opacity(0.18), radius: 18, x: 0, y: 8)
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
                .foregroundColor(.yellow.opacity(0.8))
            Text("Вопрос по ключу не найден")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.9))
            Text("Проверьте правильность ключа или выберите другое депо.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(32)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: Color.purple.opacity(0.18), radius: 18, x: 0, y: 8)
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
            // Градиентный фон
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Color.white.opacity(0.1)
                .ignoresSafeArea()
                .blur(radius: 40)
            
            VStack(spacing: 0) {
                // УБРАН HStack с крестиком
                VStack(spacing: 0) {
                    Text("Выберите депо")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                    Divider().background(Color.white.opacity(0.18))
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
                                            .foregroundColor(selectedDepot == depot ? Color.black : Color.white.opacity(0.7))
                                            .scaleEffect(selectedDepot == depot ? 1.15 : 1.0)
                                            .animation(.spring(), value: selectedDepot == depot)
                            Text(depot.name)
                                            .font(.title3.weight(selectedDepot == depot ? .bold : .regular))
                                            .foregroundColor(selectedDepot == depot ? Color.black : Color.white.opacity(0.92))
                                            .padding(.leading, 8)
                                Spacer()
                                        if selectedDepot == depot {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.black)
                                                .font(.system(size: 22, weight: .bold))
                                                .transition(.scale)
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(selectedDepot == depot ? Color.white.opacity(0.13) : Color.clear)
                                            .shadow(color: selectedDepot == depot ? Color.blue.opacity(0.13) : Color.clear, radius: 8, x: 0, y: 4)
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
                    BlurView(style: .systemUltraThinMaterialDark)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color.purple.opacity(0.18), radius: 18, x: 0, y: 8)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 18)
            }
        }
    }
}

// BlurView для эффекта стекла
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Новая вкладка Инфо
struct InfoSheet: View {
    @Binding var showInfoSheet: Bool
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Color.white.opacity(0.1)
                .ignoresSafeArea()
                .blur(radius: 40)
            VStack(spacing: 0) {
                // УБРАН HStack с крестиком
                VStack(spacing: 0) {
                    Text("Информация о приложении")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                    Divider().background(Color.white.opacity(0.18))
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Как пользоваться:")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("1. Выберите депо (слева сверху).\n2. Введите номер вопроса (например, П1, М10) или ключевое слово.\n3. Получите ответ.\n\nМожно искать по номеру, части вопроса или ключевому слову.")
                                .font(.body)
                                .foregroundColor(.black.opacity(0.85))
                            Divider().background(Color.white.opacity(0.18))
                            Text("Наименования ключей:")
                                .font(.headline)
                                .foregroundColor(.black)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("П — ПТЭ, Пн — Пневматика, М — Механика, У — Управление, А - АТЗ, Э — Электрика, Т — ТРА, ОТ - Охрана Труда, УР")
                                    .font(.body)
                                    .foregroundColor(.black.opacity(0.85))
                                Text("Пример: П1 — ПТЭ, М10 — Механика, У5 — Управление и т.д.")
                                    .font(.body)
                                    .foregroundColor(.black.opacity(0.85))
                            }
                            Divider().background(Color.white.opacity(0.18))
                            Text("Совет: если не знаете точный номер, попробуйте ввести часть вопроса или ключевое слово.")
                                .font(.footnote)
                                .foregroundColor(.green)
                            Divider().background(Color.white.opacity(0.18))
                               HStack {
                                   Image(systemName: "lock.shield")
                                       .foregroundColor(.black)
                                   Link("Политика конфиденциальности", destination: URL(string: "https://github.com/merzopakostniy/Metrotest/issues/1")!)
                                       .font(.footnote.bold())
                                       .foregroundColor(.black)
                               }
                               .padding(.top, 8)
                           }
                        }
                        .padding(24)
                    }
                }
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color.purple.opacity(0.18), radius: 18, x: 0, y: 8)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 18)
        }
    }
}



#Preview {
    ContentView()
}

