//
//  MobFlowAppoDealManager.swift
//  MobFlowiOS
//
//  Created by Vishnu's Mac    on 07/02/25.
//


import Foundation
import Appodeal
import UIKit
import SwiftUI

class MobFlowAppoDealManager: NSObject {
    
    static let shared = MobFlowAppoDealManager()
    
    private override init() {}

    // MARK: - Properties
    private let supportedAdTypes: AppodealAdType = [.banner, .interstitial, .rewardedVideo]

    private var onAdsClose: ((Bool) -> Void)?
    
    // MARK: - Banner Ad View Singleton for SwiftUI
    private var bannerAdView: BannerAdSwiftUIView?

    var isRewardedVideoReady: Bool {
        return Appodeal.isReadyForShow(with: .rewardedVideo)
    }
    
    var isInterstitialReady: Bool {
        return Appodeal.isReadyForShow(with: .interstitial)
    }

    private var rcAppodeal : RCAppodeal = RCAppodeal(enabled: false, sdk_key: "")
    
    // MARK: - Initialization
    func initializeAppoDeal(rcAppodeal: RCAppodeal) {
        #if DEBUG
        Appodeal.setTestingEnabled(true) // Enable testing in development
        Appodeal.setLogLevel(.debug)    // Debug log level for Appodeal
        #endif
        
        Appodeal.setInterstitialDelegate(self)
        Appodeal.setRewardedVideoDelegate(self)
        Appodeal.initialize(withApiKey: rcAppodeal.sdk_key, types: supportedAdTypes)
        Appodeal.isPrecacheAd([.rewardedVideo, .interstitial])
        debugPrint("Appodeal initialized successfully!")
    }

    // MARK: - Show Interstitial & Rewarded Ads
    func showAds(withAdType adType: AppodealShowStyle, onClose: @escaping (Bool) -> Void) {
        if Appodeal.isReadyForShow(with: adType) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                Appodeal.showAd(adType, rootViewController: window.rootViewController)
                self.onAdsClose = onClose
            } else {
                onClose(false)
            }
        } else {
            debugPrint("\(adType == .rewardedVideo ? "Rewarded" : "Interstitial") " + "ad is not ready.")
            onClose(false)
        }
    }
    
    // MARK: - Banner Ads for SwiftUI
    func showBannerView(position: MBAppodealBannerShowStyle) -> some View {
        if bannerAdView == nil {
            bannerAdView = BannerAdSwiftUIView(position: position)
        }
        return bannerAdView
    }
    
    private struct BannerAdSwiftUIView: UIViewControllerRepresentable {
        let position: MBAppodealBannerShowStyle

        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            DispatchQueue.main.async {
                Appodeal.showAd(.bannerBottom, rootViewController: viewController)
            }
            return viewController
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            DispatchQueue.main.async {
                Appodeal.showAd(.bannerBottom, rootViewController: uiViewController)
            }
        }
    }
    
    func showBannerInUIKit(in viewController: UIViewController, position: MBAppodealBannerShowStyle) {
        let bannerPosition: AppodealShowStyle = (position == .top) ? .bannerTop : .bannerBottom
        DispatchQueue.main.async {
            Appodeal.showAd(bannerPosition, rootViewController: viewController)
        }
    }
    
}

// MARK: - Appodeal Ad Delegate
extension MobFlowAppoDealManager: AppodealInterstitialDelegate, AppodealRewardedVideoDelegate {
    
    // MARK: Interstitial Delegate Methods
    func interstitialDidLoadAdIsPrecache(_ precache: Bool) {
        debugPrint("Interstitial ad loaded. Precache: \(precache)")
    }
    
    func interstitialDidFailToLoadAd() {
        debugPrint("Interstitial ad failed to load.")
    }
    
    func interstitialDidFailToPresent() {
        debugPrint("Interstitial ad failed to present.")
        onAdsClose?(false)
    }
    
    func interstitialDidDismiss() {
        debugPrint("Interstitial ad dismissed.")
        onAdsClose?(true)
    }
    
    func interstitialDidClick() {
        debugPrint("Interstitial ad clicked.")
    }
    
    // MARK: Rewarded Video Delegate Methods
    func rewardedVideoDidLoadAdIsPrecache(_ precache: Bool) {
        debugPrint("Rewarded video ad loaded. Precache: \(precache)")
    }
    
    func rewardedVideoDidFailToLoadAd() {
        debugPrint("Rewarded video ad failed to load.")
    }
    
    func rewardedVideoDidFailToPresentWithError(_ error: Error) {
        debugPrint("Rewarded video ad failed to present with error: \(error.localizedDescription)")
        onAdsClose?(false)
    }
    
    func rewardedVideoDidPresent() {
        debugPrint("Rewarded video ad presented.")
    }
    
    func rewardedVideoDidFinish(_ rewardAmount: Float, name rewardName: String?) {
        debugPrint("Rewarded video completed. Reward: \(rewardAmount) \(rewardName ?? "")")
        onAdsClose?(true)
    }
    
    func rewardedVideoDidClick() {
        debugPrint("Rewarded video ad clicked.")
    }
}

// MARK: - Banner Position Enum
enum MBAppodealBannerShowStyle {
    case top
    case bottom
}

struct MobFlowEmptyBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView() // Return an empty UIView when ads are disabled
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed
    }
}
