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

class AppLovinManager : NSObject {
    
    static let shared = AppLovinManager()
        
    var interestialAdView : MAInterstitialAd?
    var retryInterestialAttempt = 0.0
    
    var rewardedAdView : MARewardedAd?
    var retryRewardedAttempt = 0.0
    var rewardUser = false
    
    private var onClose: ((Bool) -> Void)?
    
    private var adView: MAAdView!
    
    private var interestialId = ""
    private var bannerId = ""
    
    private var clickCount = 3
    
    override init() {
        
    }
}

extension AppLovinManager {
    
    func initializeAppLovin(appLovinKey: String, interestialId: String, bannerId: String) {
        AppLovinManager.shared.interestialId = interestialId
        AppLovinManager.shared.bannerId = bannerId
        
        let appLovin = ALSdk.shared(withKey: appLovinKey)
#if DEBUG
        debugPrint("Not App Store build")
        let gpsadid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        appLovin!.settings.testDeviceAdvertisingIdentifiers = [gpsadid]
#else
        debugPrint("App Store build")
#endif
        appLovin!.userIdentifier = Adjust.adid() ?? ""
        appLovin!.mediationProvider = ALMediationProviderMAX
        appLovin!.initializeSdk(completionHandler: { configuration in
            //         AppLovin SDK is initialized, start loading ads now or later if ad gate is reached
            debugPrint("AppLovin SDK is initialized, start loading ads now or later if ad gate is reached")
            
            if (AppLovinManager.shared.interestialId != "") {
                AppLovinManager.shared.loadInterestialAd()
            }
            
        })
    }
    
    func loadBannerAd(vc : UIViewController) {
        
        AppLovinManager.shared.adView = MAAdView(adUnitIdentifier: AppLovinManager.shared.bannerId)
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
        AppLovinManager.shared.interestialAdView = MAInterstitialAd(adUnitIdentifier: AppLovinManager.shared.interestialId)
        AppLovinManager.shared.interestialAdView?.delegate = self
        AppLovinManager.shared.interestialAdView?.load()
    }
    
    func showInterestialAd(onClose : @escaping (Bool) -> ()) {
        
        AppLovinManager.shared.clickCount += 1
        
        debugPrint("current click count: \(AppLovinManager.shared.clickCount)")
        
        if AppLovinManager.shared.clickCount > 3 {
            AppLovinManager.shared.clickCount = 1
        } else {
            onClose(false)
            return
        }
        
        if (AppLovinManager.shared.interestialAdView?.isReady ?? false) {
            AppLovinManager.shared.interestialAdView?.show()
            AppLovinManager.shared.onClose = onClose
        } else {
            debugPrint("interestial ads failed to show")
            onClose(false)
        }
    }
    
    func showInterestialAdWithoutCount(onClose : @escaping (Bool) -> ()) {
        if (AppLovinManager.shared.interestialAdView?.isReady ?? false) {
            AppLovinManager.shared.interestialAdView?.show()
            AppLovinManager.shared.onClose = onClose
        } else {
            debugPrint("interestial ads failed to show")
            onClose(false)
        }
    }
    
}

extension AppLovinManager: MAAdDelegate {
    
    func didLoad(_ ad: MAAd) {
        debugPrint("Ad didLoad")
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        debugPrint("Ad didFailToLoadAd with id:\(adUnitIdentifier)")
        if (adUnitIdentifier == interestialId) {
            // Interstitial ad failed to load
            // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
            if AppLovinManager.shared.retryInterestialAttempt < 3 {
                AppLovinManager.shared.retryInterestialAttempt += 1
                let delaySec = 3.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delaySec) {
                    AppLovinManager.shared.interestialAdView?.load()
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

