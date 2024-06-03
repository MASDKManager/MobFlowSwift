//
//  RCFirebase.swift
//  MobFlowiOS
//
//  Created by Vishnu  on 12/07/23.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

enum ValueKey: String {
    case sub_endu
    case adjst
    case appmetrica
    case deeplink
    case params
    case delay
    case run
    case use_only_deeplink
    case tiktok
    case appsflyers
    case show_ads
    case facebook
    case applovin
    case onesignal
}

class RCValues {
    static let sharedInstance = RCValues()
    var loadingDoneCallback: (() -> Void)?
    var fetchComplete = false
    
    var sub_endu = "";
    var rCTikTok : RCTikTok!
    var params = "";
    var delay = 0;
    var run = true;
    var use_only_deeplink = false;
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            ValueKey.sub_endu.rawValue: "",
            ValueKey.adjst.rawValue: "",
            ValueKey.appmetrica.rawValue: "",
            ValueKey.deeplink.rawValue: "",
            ValueKey.params.rawValue: "",
            ValueKey.delay.rawValue: 0.0,
            ValueKey.run.rawValue: true,
            ValueKey.use_only_deeplink.rawValue: false,
            ValueKey.tiktok.rawValue: "",
            ValueKey.appsflyers.rawValue: "",
            ValueKey.show_ads.rawValue: true,
            ValueKey.facebook.rawValue: ""
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    func fetchCloudValues() {
//        activateDebugMode()
          
        RemoteConfig.remoteConfig().fetch { [weak self] (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                
                RemoteConfig.remoteConfig().activate { [weak self] changed, error in
                  
                    
                    DispatchQueue.main.async {
                        self?.fetchComplete = true
                        self?.loadingDoneCallback?()
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
            
        }
        
    }
    
    func activateDebugMode() {
        let settings = RemoteConfigSettings()
        // WARNING: Don't actually do this in production!
        settings.minimumFetchInterval = 0
        RemoteConfig.remoteConfig().configSettings = settings
    }
     
    func getAdjust() -> RCAdjust {
        let rCAdjustJson = RCValues.sharedInstance.string(forKey: .adjst)
        let rCAdjustData = Data(rCAdjustJson.utf8)
        do{
            let rCAdjust = try JSONDecoder().decode(RCAdjust.self, from: rCAdjustData)
            return rCAdjust
        }
        catch(_) {
            let rCAdjust = RCAdjust(enabled: false, appToken: "", macros: "")
            return rCAdjust
        }
    }
    
    func getOneSignal() -> RCOneSignal {
        let rCOneSignalJson = RCValues.sharedInstance.string(forKey: .onesignal)
        let rCOneSignalData = Data(rCOneSignalJson.utf8)
        do{
            let rCOneSignal = try JSONDecoder().decode(RCOneSignal.self, from: rCOneSignalData)
            return rCOneSignal
        }
        catch(_) {
            let rCOneSignal = RCOneSignal(enabled: false, one_signal_key: "")
            return rCOneSignal
        }
    }
    
    func getTikTok() -> RCTikTok {
        let rCTikTokJson = RCValues.sharedInstance.string(forKey: .tiktok)
        let rCTikTokData = Data(rCTikTokJson.utf8)
        do{
            let rCTikTok = try JSONDecoder().decode(RCTikTok.self, from: rCTikTokData)
            return rCTikTok
        }
        catch(_) {
            let rCTikTok = RCTikTok(enabled: false, accessToken: "", appStoreId: "", tiktokAppId: "", eventName: "")
            return rCTikTok
        }
    }
    
    func getAppsFlyers() -> RCAppsFlyers {
        let rCAppsFlyersJson = RCValues.sharedInstance.string(forKey: .appsflyers)
        let rCAppsFlyersData = Data(rCAppsFlyersJson.utf8)
        do{
            let rCAppsFlyers = try JSONDecoder().decode(RCAppsFlyers.self, from: rCAppsFlyersData)
            return rCAppsFlyers
        }
        catch(_) {
            let rCAppsFlyers = RCAppsFlyers(enabled: false, devKey: "", appStoreId: "", macros: "")
            return rCAppsFlyers
        }
    }
    
    func getFacebook() -> RCFacebook {
        let rCFacebookJson = RCValues.sharedInstance.string(forKey: .facebook)
        let rCFacebookData = Data(rCFacebookJson.utf8)
        do{
            let rCFacebook = try JSONDecoder().decode(RCFacebook.self, from: rCFacebookData)
            return rCFacebook
        }
        catch(_) {
            let rCFacebook = RCFacebook(enabled: false, appID: "", clientToken: "")
            return rCFacebook
        }
    }
    
    func getAppLovin() -> RCAppLovin {
        let rCAppLovinJson = RCValues.sharedInstance.string(forKey: .applovin)
        let rCAppLovinData = Data(rCAppLovinJson.utf8)
        do{
            let rCAppLovin = try JSONDecoder().decode(RCAppLovin.self, from: rCAppLovinData)
            return rCAppLovin
        }
        catch(_) {
            let rCAppLovin = RCAppLovin(enabled: false, sdk_key: "", banner_id: "", interstitial_id: "", rewarded_id: "", app_open_id: "")
            return rCAppLovin
        }
    }
    
    func showAds() -> Bool {
        let rCShowAds = RCValues.sharedInstance.bool(forKey: .show_ads)
        return rCShowAds
    }
    
    func bool(forKey key: ValueKey) -> Bool {
        RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
    
    func string(forKey key: ValueKey) -> String {
        RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
    }
    
    func double(forKey key: ValueKey) -> Double {
        RemoteConfig.remoteConfig()[key.rawValue].numberValue.doubleValue
    }
}
