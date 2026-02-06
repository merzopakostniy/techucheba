import SwiftUI
import YandexMobileAds

struct SplashView: View {
    @State private var showAd = true
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if showAd {
                YandexInterstitialAdView(adUnitID: "R-M-15742337-3", isPresented: $showAd)
            }
            if showContent == false && showAd == false {
                // Переход к основному экрану после рекламы
                Color.clear.onAppear {
                    showContent = true
                }
            }
        }
        .fullScreenCover(isPresented: $showContent) {
            ContentView()
        }
    }
}

struct YandexInterstitialAdView: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && !context.coordinator.isLoading && context.coordinator.interstitialAd == nil {
            context.coordinator.isLoading = true
            let loader = InterstitialAdLoader()
            loader.delegate = context.coordinator
            loader.loadAd(with: AdRequestConfiguration(adUnitID: adUnitID))
            context.coordinator.loader = loader
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, InterstitialAdLoaderDelegate, InterstitialAdDelegate {
        var parent: YandexInterstitialAdView
        var loader: InterstitialAdLoader?
        var interstitialAd: InterstitialAd?
        var isLoading = false

        init(_ parent: YandexInterstitialAdView) {
            self.parent = parent
        }

        func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didLoad interstitialAd: InterstitialAd) {
            self.interstitialAd = interstitialAd
            interstitialAd.delegate = self
            if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })?.rootViewController {
                interstitialAd.show(from: rootVC)
            }
        }

        func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didFailToLoadWithError error: AdRequestError) {
            parent.isPresented = false
            isLoading = false
        }

        func interstitialAdDidDismiss(_ interstitialAd: InterstitialAd) {
            parent.isPresented = false
            isLoading = false
        }

        func interstitialAd(_ interstitialAd: InterstitialAd, didFailToShowWithError error: Error) {
            parent.isPresented = false
            isLoading = false
        }
    }
} 
