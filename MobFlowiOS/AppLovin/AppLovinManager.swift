//
//  AppLovinManager.swift
//  MobFlowiOS
//
//  Created by Vishnu  on 13/07/23.
//

import Foundation
import AppLovinSDK
import AdSupport
import UIKit
import Adjust
import FBAudienceNetwork

class AppLovinManager : NSObject {
    
    static let shared = AppLovinManager()
        
    var interestialAdView : MAInterstitialAd?
    var retryInterestialAttempt = 0.0
    
    var rewardedAdView : MARewardedAd?
    var retryRewardedAttempt = 0.0
    var rewardUser = false
    
    private var appOpenAdView : MAAppOpenAd?
    
    private var onClose: ((Bool) -> Void)?
    
    private var adView: MAAdView!
    
    private var interestialId = ""
    private var bannerId = ""
    private var rewardedId = ""
    private var appOpenAdId = ""
    
    private var appLovin: ALSdk!
    
    override init() {
        
    }
}

extension AppLovinManager {
    
    func initializeAppLovin(appLovinKey: String, interestialId: String, bannerId: String, rewardedId: String, appOpenAdId: String) {
        AppLovinManager.shared.interestialId = interestialId
        AppLovinManager.shared.bannerId = bannerId
        AppLovinManager.shared.rewardedId = rewardedId
        AppLovinManager.shared.appOpenAdId = appOpenAdId
        
        //Meta Audience Network Data Processing Options, If you do not want to enable Limited Data Use (LDU) mode, pass SetDataProcessingOptions() an empty array
        FBAdSettings.setDataProcessingOptions([])
        
        let settings = ALSdkSettings()
        
        
#if DEBUG
        debugPrint("Not App Store build")
        let gpsadid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        settings.testDeviceAdvertisingIdentifiers = [gpsadid]
#else
        debugPrint("App Store build")
#endif
        appLovin = ALSdk.shared(withKey: appLovinKey, settings: settings)
        appLovin!.userIdentifier = Adjust.adid() ?? ""
        appLovin!.mediationProvider = ALMediationProviderMAX
        appLovin!.initializeSdk(completionHandler: { configuration in
            //         AppLovin SDK is initialized, start loading ads now or later if ad gate is reached
            debugPrint("AppLovin SDK is initialized, start loading ads now or later if ad gate is reached")
            
            if (AppLovinManager.shared.interestialId != "") {
                AppLovinManager.shared.loadInterestialAd()
            }
            
            if (AppLovinManager.shared.rewardedId != "") {
                AppLovinManager.shared.loadRewardedAd()
            }
            
            if (AppLovinManager.shared.appOpenAdId != "") {
                AppLovinManager.shared.loadAppOpenAds()
            }
        })
    }
    
    func loadBannerAd(vc : UIViewController) {
        
        AppLovinManager.shared.adView = MAAdView(adUnitIdentifier: AppLovinManager.shared.bannerId,sdk: appLovin)
        AppLovinManager.shared.adView.delegate = self
        
        // Banner height on iPhone and iPad is 50 and 90, respectively
        let height: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 90 : 50
        
        // Stretch to the width of the screen for banners to be fully functional
        let width: CGFloat = UIScreen.main.bounds.width
        
        AppLovinManager.shared.adView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - height - 15, width: width, height: height)
        
        // Set background or background color for banners to be fully functional
        AppLovinManager.shared.adView.backgroundColor = .clear
        
        vc.view.addSubview(AppLovinManager.shared.adView)
        
        // Load the first ad
        AppLovinManager.shared.adView.loadAd()
    }
    
    private func loadInterestialAd() {
        AppLovinManager.shared.interestialAdView = MAInterstitialAd(adUnitIdentifier: AppLovinManager.shared.interestialId,sdk: appLovin)
        AppLovinManager.shared.interestialAdView?.delegate = self
        AppLovinManager.shared.interestialAdView?.load()
    }
    
    func showInterestialAd(onClose : @escaping (Bool) -> ()) {
        
        if (AppLovinManager.shared.interestialAdView?.isReady ?? false) {
            AppLovinManager.shared.interestialAdView?.show()
            AppLovinManager.shared.onClose = onClose
        } else {
            debugPrint("interestial ads failed to show")
            onClose(false)
        }
    }
    
    private func loadRewardedAd() {
        AppLovinManager.shared.rewardedAdView = MARewardedAd.shared(withAdUnitIdentifier: AppLovinManager.shared.rewardedId,sdk: appLovin)
        AppLovinManager.shared.rewardedAdView?.delegate = self
        AppLovinManager.shared.rewardedAdView?.load()
    }
    
    func showRewardedAd(onClose : @escaping (Bool) -> ()) {
        if (AppLovinManager.shared.rewardedAdView?.isReady ?? false) {
            AppLovinManager.shared.rewardedAdView?.show()
            AppLovinManager.shared.onClose = onClose
        } else {
            print("rewarded ads failed to show")
            onClose(false)
        }
    }
    
    private func loadAppOpenAds() {
        AppLovinManager.shared.appOpenAdView = MAAppOpenAd(adUnitIdentifier: AppLovinManager.shared.appOpenAdId, sdk: appLovin)
        AppLovinManager.shared.appOpenAdView?.delegate = self
        AppLovinManager.shared.appOpenAdView?.load()
    }
    
    func showAppOpenAds(onClose : @escaping (Bool) -> ()) {
        
        if AppLovinManager.shared.appOpenAdView?.isReady ?? false
        {
            AppLovinManager.shared.appOpenAdView?.show()
            AppLovinManager.shared.onClose = onClose
        }
        else
        {
            AppLovinManager.shared.loadAppOpenAds()
            onClose(false)
        }
    }
}

extension AppLovinManager: MAAdDelegate {
    
    func didLoad(_ ad: MAAd) {
        debugPrint("Ad didLoad: \(ad.adUnitIdentifier)")
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        // Interstitial ad failed to load
        // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
        
        debugPrint("Ad didFailToLoadAd with id:\(adUnitIdentifier)")
        
        if AppLovinManager.shared.retryInterestialAttempt < 3 {
            AppLovinManager.shared.retryInterestialAttempt += 1
            let delaySec = 3.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySec) {
                
                if (adUnitIdentifier == self.interestialId) {
                    AppLovinManager.shared.interestialAdView?.load()
                }
                if (adUnitIdentifier == self.rewardedId) {
                    AppLovinManager.shared.rewardedAdView?.load()
                }
                if (adUnitIdentifier == self.appOpenAdId) {
                    AppLovinManager.shared.appOpenAdView?.load()
                }
            }
        }
        
        
    }
    
    func didDisplay(_ ad: MAAd) {
        debugPrint("Ad didDisplay \(ad.adUnitIdentifier)")
    }
    
    func didHide(_ ad: MAAd) {
        debugPrint("Ad didHide \(ad.adUnitIdentifier)")
        if (ad.adUnitIdentifier == AppLovinManager.shared.interestialId){
            AppLovinManager.shared.onClose?(true)
            AppLovinManager.shared.loadInterestialAd()
        }
        if (ad.adUnitIdentifier == AppLovinManager.shared.rewardedId){
            AppLovinManager.shared.onClose?(true)
            AppLovinManager.shared.loadRewardedAd()
        }
        if (ad.adUnitIdentifier == AppLovinManager.shared.appOpenAdId){
            AppLovinManager.shared.onClose?(true)
            AppLovinManager.shared.loadAppOpenAds()
        }
    }
    
    func didClick(_ ad: MAAd) {
        debugPrint("Ad didClick \(ad.adUnitIdentifier)")
    }
    
    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        debugPrint("Ad didFail \(ad.adUnitIdentifier)")
        AppLovinManager.shared.onClose?(false)
    }
    
}


extension AppLovinManager : MARewardedAdDelegate {
    
    func didStartRewardedVideo(for ad: MAAd) {
        debugPrint("Ad didStartRewardedVideo")
    }
    
    func didCompleteRewardedVideo(for ad: MAAd) {
        debugPrint("Ad didCompleteRewardedVideo")
        AppLovinManager.shared.rewardUser = true
    }
    
    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        debugPrint("Ad didRewardUser")
        AppLovinManager.shared.rewardUser = true
    }
    
    
}

extension AppLovinManager : MAAdViewAdDelegate {
    //Banner Delegate
    func didExpand(_ ad: MAAd) {
        debugPrint("Ad didExpand")
    }
    
    func didCollapse(_ ad: MAAd) {
        debugPrint("Ad diddidCollapseExpand")
    }
}

