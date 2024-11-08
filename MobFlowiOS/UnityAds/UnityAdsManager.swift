//
//  UnityAdsManager.swift
//  MobFlowiOS
//
//  Created by Vishnu's Mac    on 24/10/24.
//


import Foundation
import UnityAds
import UIKit
import SwiftUI

class UnityAdsManager: NSObject {
    
    static let shared = UnityAdsManager()
    
    private var gameID: String = ""
    private var bannerPlacementID: String = "Banner_iOS"
    private var interstitialPlacementID: String = "Interstitial_iOS"
    private var rewardedVideoPlacementID: String = "Rewarded_iOS"
    
    private var onClose: ((Bool) -> Void)?
    
    // Initialize Unity Ads
    func initializeUnityAds(gameID: String, bannerPlacementID: String, interstitialPlacementID: String, rewardedVideoPlacementID: String) {
        
        self.gameID = gameID
        
        self.bannerPlacementID = bannerPlacementID
        
        self.interstitialPlacementID = interstitialPlacementID
        
        self.rewardedVideoPlacementID = rewardedVideoPlacementID
        
#if DEBUG
        debugPrint("Not App Store build")
        UnityAds.initialize(self.gameID, testMode: true, initializationDelegate: self)
#else
        UnityAds.initialize(self.gameID, initializationDelegate: self)
#endif
        
        //Load interestitial and rewarded ads
        loadInterstitialAd()
        loadRewardedAd()
        
    }
    
    // Load and show Interstitial Ad
    private func loadInterstitialAd() {
        UnityAds.load(self.interstitialPlacementID, loadDelegate: self)
    }
    
    // Load and show Rewarded Ad
    private func loadRewardedAd() {
        UnityAds.load(self.rewardedVideoPlacementID, loadDelegate: self)
    }
    
    // Load and show Banner Ad
    func showBannerAd(viewController: UIViewController) {
        let banner = UADSBannerView(placementId: self.bannerPlacementID, size: CGSize(width: 320, height: 50))
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false // Use Auto Layout

        viewController.view.addSubview(banner)
        
        // Position the banner at the bottom center
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            banner.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            banner.widthAnchor.constraint(equalToConstant: 320),
            banner.heightAnchor.constraint(equalToConstant: 50)
        ])

        banner.load()
    }
    
    // Create Banner Ad (for SwiftUI usage)
    func createBannerView() -> UADSBannerView {
        let banner = UADSBannerView(placementId: self.bannerPlacementID, size: CGSize(width: 320, height: 50))
        banner.load()
        return banner
    }
    
    func showInterstitialAds(viewController: UIViewController, onClose : @escaping (Bool) -> ()) {
        UnityAdsManager.shared.onClose = onClose
        UnityAds.show(viewController, placementId: self.interstitialPlacementID, showDelegate: self)
    }
    
    func showRewardedAds(viewController: UIViewController, onClose : @escaping (Bool) -> ()) {
        UnityAdsManager.shared.onClose = onClose
        UnityAds.show(viewController, placementId: self.rewardedVideoPlacementID, showDelegate: self)
    }
}

// UADSBannerViewDelegate Methods
extension UnityAdsManager : UADSBannerViewDelegate {
    func bannerViewDidLoad(_ bannerView: UADSBannerView!) {
        debugPrint("Banner loaded successfully")
    }
    
    func bannerViewDidError(_ bannerView: UADSBannerView!, error: UADSBannerError!) {
        debugPrint("Failed to load banner")
    }
}

extension UnityAdsManager : UnityAdsShowDelegate {
    func unityAdsShowComplete(_ placementId: String, withFinish state: UnityAdsShowCompletionState) {
        debugPrint("Unity Ads show complete for placementId: \(placementId) and with state: \(state.rawValue)")
        UnityAds.load(placementId, loadDelegate: self)
        UnityAdsManager.shared.onClose?(true)
    }
    
    func unityAdsShowFailed(_ placementId: String, withError error: UnityAdsShowError, withMessage message: String) {
        debugPrint("Unity Ads show failed for placementId: \(placementId) and with error: \(error.rawValue) and message: \(message)")
        UnityAdsManager.shared.onClose?(false)
    }
    
    func unityAdsShowStart(_ placementId: String) {
        debugPrint("Unity Ads show started for placementId: \(placementId)")
    }
    
    func unityAdsShowClick(_ placementId: String) {
        debugPrint("Unity Ads show clicked for placementId: \(placementId)")
    }
    
}

extension UnityAdsManager : UnityAdsLoadDelegate {
    func unityAdsAdLoaded(_ placementId: String) {
        debugPrint("Unity Ads ad loaded for placementId: \(placementId)")
    }
    
    func unityAdsAdFailed(toLoad placementId: String, withError error: UnityAdsLoadError, withMessage message: String) {
        debugPrint("Unity Ads ad failed to load for placementId: \(placementId) with error: \(error.rawValue) and message: \(message)")
    }
}

extension UnityAdsManager : UnityAdsInitializationDelegate {
    
    func initializationComplete() {
        debugPrint("Unity Ads initialization completed")
    }
    
    func initializationFailed(_ error: UnityAdsInitializationError, withMessage message: String) {
        debugPrint("Unity Ads initialization failed with error: \(message)")
    }
    
}

struct UnityBannerAdView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let bannerView = UnityAdsManager.shared.createBannerView()
        return bannerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the view when needed
    }
    
}

struct EmptyBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView() // Return an empty UIView when ads are disabled
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed
    }
}
