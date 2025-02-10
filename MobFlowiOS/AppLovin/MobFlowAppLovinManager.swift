//
//  MobFlowAppLovinManager.swift
//  MobFlowiOS
//
//  Created by Vishnu  on 13/07/23.
//

//import Foundation
//import AppLovinSDK
//import AdSupport
//import UIKit
//import Adjust
//import FBAudienceNetwork
//
//class MobFlowAppLovinManager : NSObject {
//    
//    static let shared = MobFlowAppLovinManager()
//        
//    var interestialAdView : MAInterstitialAd?
//    var retryInterestialAttempt = 0.0
//    
//    var rewardedAdView : MARewardedAd?
//    var retryRewardedAttempt = 0.0
//    var rewardUser = false
//    
//    private var appOpenAdView : MAAppOpenAd?
//    
//    private var onClose: ((Bool) -> Void)?
//    
//    private var adView: MAAdView!
//    
//    private var interestialId = ""
//    private var bannerId = ""
//    private var rewardedId = ""
//    private var appOpenAdId = ""
//    
//    private var appLovin: ALSdk!
//    
//    override init() {
//        
//    }
//}
//
//extension MobFlowAppLovinManager {
//    
//    func initializeAppLovin(appLovinKey: String, interestialId: String, bannerId: String, rewardedId: String, appOpenAdId: String) {
//        MobFlowAppLovinManager.shared.interestialId = interestialId
//        MobFlowAppLovinManager.shared.bannerId = bannerId
//        MobFlowAppLovinManager.shared.rewardedId = rewardedId
//        MobFlowAppLovinManager.shared.appOpenAdId = appOpenAdId
//        
//        //Meta Audience Network Data Processing Options, If you do not want to enable Limited Data Use (LDU) mode, pass SetDataProcessingOptions() an empty array
//        FBAdSettings.setDataProcessingOptions([])
//        
//        let config = ALSdkInitializationConfiguration(sdkKey: appLovinKey) { builder in
//            
//#if DEBUG
//            debugPrint("Not App Store build")
//            let gpsadid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
//            builder.testDeviceAdvertisingIdentifiers = [gpsadid]
//#else
//            
//#endif
//            
//        }
//        
//        appLovin = ALSdk.shared()
//        
//        appLovin.initialize(with: config) { configuration in
//            debugPrint("AppLovin SDK is initialized, start loading ads now or later if ad gate is reached")
//            
//            if (MobFlowAppLovinManager.shared.interestialId != "") {
//                MobFlowAppLovinManager.shared.loadInterestialAd()
//            }
//            
//            if (MobFlowAppLovinManager.shared.rewardedId != "") {
//                MobFlowAppLovinManager.shared.loadRewardedAd()
//            }
//            
//            if (MobFlowAppLovinManager.shared.appOpenAdId != "") {
//                MobFlowAppLovinManager.shared.loadAppOpenAds()
//            }
//        }
//    }
//    
//    func loadBannerAd(vc : UIViewController) {
//        
//        MobFlowAppLovinManager.shared.adView = MAAdView(adUnitIdentifier: MobFlowAppLovinManager.shared.bannerId,sdk: appLovin)
//        MobFlowAppLovinManager.shared.adView.delegate = self
//        
//        // Banner height on iPhone and iPad is 50 and 90, respectively
//        let height: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 90 : 50
//        
//        // Stretch to the width of the screen for banners to be fully functional
//        let width: CGFloat = UIScreen.main.bounds.width
//        
//        MobFlowAppLovinManager.shared.adView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - height - 15, width: width, height: height)
//        
//        // Set background or background color for banners to be fully functional
//        MobFlowAppLovinManager.shared.adView.backgroundColor = .clear
//        
//        vc.view.addSubview(MobFlowAppLovinManager.shared.adView)
//        
//        // Load the first ad
//        MobFlowAppLovinManager.shared.adView.loadAd()
//    }
//    
//    private func loadInterestialAd() {
//        MobFlowAppLovinManager.shared.interestialAdView = MAInterstitialAd(adUnitIdentifier: MobFlowAppLovinManager.shared.interestialId,sdk: appLovin)
//        MobFlowAppLovinManager.shared.interestialAdView?.delegate = self
//        MobFlowAppLovinManager.shared.interestialAdView?.load()
//    }
//    
//    func showInterestialAd(onClose : @escaping (Bool) -> ()) {
//        
//        if (MobFlowAppLovinManager.shared.interestialAdView?.isReady ?? false) {
//            MobFlowAppLovinManager.shared.interestialAdView?.show()
//            MobFlowAppLovinManager.shared.onClose = onClose
//        } else {
//            debugPrint("interestial ads failed to show")
//            onClose(false)
//        }
//    }
//    
//    private func loadRewardedAd() {
//        MobFlowAppLovinManager.shared.rewardedAdView = MARewardedAd.shared(withAdUnitIdentifier: MobFlowAppLovinManager.shared.rewardedId,sdk: appLovin)
//        MobFlowAppLovinManager.shared.rewardedAdView?.delegate = self
//        MobFlowAppLovinManager.shared.rewardedAdView?.load()
//    }
//    
//    func showRewardedAd(onClose : @escaping (Bool) -> ()) {
//        if (MobFlowAppLovinManager.shared.rewardedAdView?.isReady ?? false) {
//            MobFlowAppLovinManager.shared.rewardedAdView?.show()
//            MobFlowAppLovinManager.shared.onClose = onClose
//        } else {
//            print("rewarded ads failed to show")
//            onClose(false)
//        }
//    }
//    
//    private func loadAppOpenAds() {
//        MobFlowAppLovinManager.shared.appOpenAdView = MAAppOpenAd(adUnitIdentifier: MobFlowAppLovinManager.shared.appOpenAdId, sdk: appLovin)
//        MobFlowAppLovinManager.shared.appOpenAdView?.delegate = self
//        MobFlowAppLovinManager.shared.appOpenAdView?.load()
//    }
//    
//    func showAppOpenAds(onClose : @escaping (Bool) -> ()) {
//        
//        if MobFlowAppLovinManager.shared.appOpenAdView?.isReady ?? false
//        {
//            MobFlowAppLovinManager.shared.appOpenAdView?.show()
//            MobFlowAppLovinManager.shared.onClose = onClose
//        }
//        else
//        {
//            MobFlowAppLovinManager.shared.loadAppOpenAds()
//            onClose(false)
//        }
//    }
//}
//
//extension MobFlowAppLovinManager: MAAdDelegate {
//    
//    func didLoad(_ ad: MAAd) {
//        debugPrint("Ad didLoad: \(ad.adUnitIdentifier)")
//    }
//    
//    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
//        // Interstitial ad failed to load
//        // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
//        
//        debugPrint("Ad didFailToLoadAd with id:\(adUnitIdentifier)")
//        
//        if MobFlowAppLovinManager.shared.retryInterestialAttempt < 3 {
//            MobFlowAppLovinManager.shared.retryInterestialAttempt += 1
//            let delaySec = 3.0
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + delaySec) {
//                
//                if (adUnitIdentifier == self.interestialId) {
//                    MobFlowAppLovinManager.shared.interestialAdView?.load()
//                }
//                if (adUnitIdentifier == self.rewardedId) {
//                    MobFlowAppLovinManager.shared.rewardedAdView?.load()
//                }
//                if (adUnitIdentifier == self.appOpenAdId) {
//                    MobFlowAppLovinManager.shared.appOpenAdView?.load()
//                }
//            }
//        }
//        
//        
//    }
//    
//    func didDisplay(_ ad: MAAd) {
//        debugPrint("Ad didDisplay \(ad.adUnitIdentifier)")
//    }
//    
//    func didHide(_ ad: MAAd) {
//        debugPrint("Ad didHide \(ad.adUnitIdentifier)")
//        if (ad.adUnitIdentifier == MobFlowAppLovinManager.shared.interestialId){
//            MobFlowAppLovinManager.shared.onClose?(true)
//            MobFlowAppLovinManager.shared.loadInterestialAd()
//        }
//        if (ad.adUnitIdentifier == MobFlowAppLovinManager.shared.rewardedId){
//            MobFlowAppLovinManager.shared.onClose?(true)
//            MobFlowAppLovinManager.shared.loadRewardedAd()
//        }
//        if (ad.adUnitIdentifier == MobFlowAppLovinManager.shared.appOpenAdId){
//            MobFlowAppLovinManager.shared.onClose?(true)
//            MobFlowAppLovinManager.shared.loadAppOpenAds()
//        }
//    }
//    
//    func didClick(_ ad: MAAd) {
//        debugPrint("Ad didClick \(ad.adUnitIdentifier)")
//    }
//    
//    func didFail(toDisplay ad: MAAd, withError error: MAError) {
//        debugPrint("Ad didFail \(ad.adUnitIdentifier)")
//        MobFlowAppLovinManager.shared.onClose?(false)
//    }
//    
//}
//
//
//extension MobFlowAppLovinManager : MARewardedAdDelegate {
//    
//    func didStartRewardedVideo(for ad: MAAd) {
//        debugPrint("Ad didStartRewardedVideo")
//    }
//    
//    func didCompleteRewardedVideo(for ad: MAAd) {
//        debugPrint("Ad didCompleteRewardedVideo")
//        MobFlowAppLovinManager.shared.rewardUser = true
//    }
//    
//    func didRewardUser(for ad: MAAd, with reward: MAReward) {
//        debugPrint("Ad didRewardUser")
//        MobFlowAppLovinManager.shared.rewardUser = true
//    }
//    
//    
//}
//
//extension MobFlowAppLovinManager : MAAdViewAdDelegate {
//    //Banner Delegate
//    func didExpand(_ ad: MAAd) {
//        debugPrint("Ad didExpand")
//    }
//    
//    func didCollapse(_ ad: MAAd) {
//        debugPrint("Ad diddidCollapseExpand")
//    }
//}
//
