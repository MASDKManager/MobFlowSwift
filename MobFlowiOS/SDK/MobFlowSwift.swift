import UIKit
import SwiftUI
import FirebaseCrashlytics
import AdjustSdk
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import TikTokBusinessSDK
import StoreKit
import AdServices
import AppsFlyerLib
import FBSDKCoreKit
import OneSignalFramework
import Clarity

public class MobiFlowSwift: NSObject
{
    
    private let mob_sdk_version = "3.2.5"
    private var endpoint = ""
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    public var customURL = ""
    public var schemeURL = ""
    public var addressURL = ""
    public var showAdsBeforeNative = true
    private var faid = ""
    private var run = false
    var isReactNative = false
    private var hasInitialized: Bool = false
    private var hasSwitchedToApp: Bool = false
    public var hideToolbar = false
    private var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    private var backgroundColor = UIColor.white
    private var tintColor = UIColor.black
    private var showAds = true
    
    //Adjust
    var rcAdjust : RCAdjust = RCAdjust(enabled: false, appToken: "", macros: "")
    private var adid = ""
    
    //OneSignal
    var rcOneSignal : RCOneSignal = RCOneSignal(enabled: false, one_signal_key: "")
    var isOneSignalInitialised = false
    
    //TikTok
    var rcTikTok : RCTikTok = RCTikTok(enabled: false, accessToken: "", appStoreId: "", tiktokAppId: "", eventName: "")
    
    //AppFlyers
    var rcAppsFlyers : RCAppsFlyers = RCAppsFlyers(enabled: false, devKey: "", appStoreId: "", macros: "")
    
    //    //AppLovin
    //    var appLovinManager = AppLovinManager.shared
    //
    //    private var appLovinKey = ""
    //    private var appLovinInterestialId = ""
    //    private var appLovinBannerId = ""
    //    private var appLovinRewardedId = ""
    //    private var appLovinAppOpenAdId = ""
    
    //Unity Ads
    var unityAdsManager = UnityAdsManager.shared
    private var unityGameId = ""
    private var unityInterestialId = "Interstitial_iOS"
    private var unityBannerId = "Banner_iOS"
    private var unityRewardedId = "Rewarded_iOS"
    
    //Facebook
    var rcFacebook : RCFacebook = RCFacebook(enabled: false, appID: "", clientToken: "")
    
    //AppLovin
    var rcAppLovin : RCAppLovin = RCAppLovin(enabled: false, sdk_key: "", banner_id: "", interstitial_id: "", rewarded_id: "", app_open_id: "")
    
    //Clarity SDK Project ID
    var clarityProjectID : String = ""
    
    let nc = NotificationCenter.default
    
    public init(initDelegate: MobiFlowDelegate, unityGameId: String, bannerId: String = "", interstitialId: String = "", rewardedId: String = "", clarityProjectId: String = "", launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        super.init()
        
        self.delegate = initDelegate
        self.launchOptions = launchOptions
        self.unityGameId = unityGameId
        self.unityBannerId = bannerId != "" ? bannerId : self.unityBannerId
        self.unityInterestialId = interstitialId != "" ? interstitialId : self.unityInterestialId
        self.unityRewardedId = rewardedId != "" ? rewardedId : self.unityRewardedId
        self.clarityProjectID = clarityProjectId
        
        self.basicSdkSetup()
    }
    
    private func basicSdkSetup() {
        
        self.getFirebase()
        
        //        //AppLovin Ads initialisation
        //        self.initialiseAppLovin()
        
        //Unity Ads initialisation
        self.initialiseUnityAds()
        
        //Clarity by Microsoft for tracking user activity in App
        self.initialiseClarity()
        
        let oneSignalKey = getOneSignalKey()
        
        if oneSignalKey != "" {
            debugPrint("OneSignal Key from default: \(oneSignalKey)")
            self.initialiseOneSignal(oneSignalKey: oneSignalKey)
        }
        
        //app enter foreground
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public func isReactNative(value: Bool) {
        self.isReactNative = value
    }
    
    
    @objc func appMovedToForeground() {
        debugPrint("Mobibox: Will Enter Foreground")
        if self.hasSwitchedToApp && (self.endpoint == "") && self.showAds {
            self.showRewardedAd() { _ in
                debugPrint("successfully shown AppOpen Ads.")
            }
        }
    }
    
    func getFirebase() {
        
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            // If not configured, configure Firebase
            FirebaseApp.configure()
            
            // set custom User ID in Crashlytics to identify user
            Crashlytics.crashlytics().setUserID(generateUserUUID())
        } else {
            debugPrint("Firebase is already configured.")
        }
        
        let appDefaults: [String: Any?] = [
            "run": true,
        ]
        
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
        
        RemoteConfig.remoteConfig().fetch { (status, error) in
            if status == .success {
                RemoteConfig.remoteConfig().activate { _, error in
                    DispatchQueue.main.async {
                        
                        let endp = RemoteConfig.remoteConfig()["sub_endios"].stringValue ?? ""
                        self.endpoint = endp.trimmingCharacters(in: .whitespaces)
                        self.showAds = RCValues.sharedInstance.showAds()
                        self.rcAdjust = RCValues.sharedInstance.getAdjust()
                        self.rcTikTok = RCValues.sharedInstance.getTikTok()
                        self.rcAppsFlyers = RCValues.sharedInstance.getAppsFlyers()
                        self.rcFacebook = RCValues.sharedInstance.getFacebook()
                        
                        //remote config removed as by this way ads take longer loading time
                        //self.rcAppLovin = RCValues.sharedInstance.getAppLovin()
                        self.rcOneSignal = RCValues.sharedInstance.getOneSignal()
                        
                        if self.rcOneSignal.one_signal_key != "" {
                            saveOneSignalKey(value: self.rcOneSignal.one_signal_key)
                        }
                        
                        self.run = self.endpoint != ""
                        
                        Task {
                            await self.initialiseSDK()
                        }
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
                
                Task {
                    await self.initialiseSDK()
                }
            }
        }
        
    }
    
    func initialiseSDK() async {
        
        
        if hasInitialized {
            return
        }
        
        self.hasInitialized = true
        
        self.faid = Analytics.appInstanceID() ?? ""
        
        if self.rcOneSignal.enabled && self.rcOneSignal.one_signal_key != "" && !isOneSignalInitialised {
            self.initialiseOneSignal(oneSignalKey: self.rcOneSignal.one_signal_key)
        }
        
        //used for initialising AppLovin when values were fetched from remote config
        //        if self.showAds && self.rcAppLovin.enabled {
        //            self.initialiseAppLovin()
        //        }
        
        if self.rcTikTok.enabled {
            let config = TikTokConfig(accessToken: rcTikTok.accessToken, appId: rcTikTok.appStoreId, tiktokAppId: rcTikTok.tiktokAppId)
            config?.appTrackingDialogSuppressed = true
            
            do {
                try await TikTokBusiness.initializeSdk(config)
                
                let tiktokCallbackProperties: [AnyHashable: Any] = [
                    "m_sdk_ver": mob_sdk_version,
                    "user_uuid": generateUserUUID(),
                    "firebase_instance_id": self.faid
                ]
                
                printMobLog(description: "tiktokCallbackProperties:", value: tiktokCallbackProperties.description)
                
                // Track the event only after successful initialization
                if rcTikTok.eventName != "" {
                    TikTokBusiness.trackEvent(rcTikTok.eventName, withProperties: tiktokCallbackProperties)
                }
            } catch {
                debugPrint("Error initializing TikTok SDK: \(error)")
            }
        }
        
        if self.rcFacebook.enabled {
            self.initialiseFacebook()
        }
        
        if (!run) {
            if (self.showAds) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.showRewardedAd { _ in
                        self.showNativeWithPermission(dic: [String : Any]())
                    }
                })
            } else {
                self.showNativeWithPermission(dic: [String : Any]())
            }
            return
        }
        
        if (rcAppsFlyers.enabled) { //Init Apps Flyers SDK
            debugPrint("Apps Flyers SDK initiate called")
            
            AppsFlyerLib.shared().appsFlyerDevKey = rcAppsFlyers.devKey
            AppsFlyerLib.shared().appleAppID = rcAppsFlyers.appStoreId
            AppsFlyerLib.shared().delegate = self
            AppsFlyerLib.shared().deepLinkDelegate = self
            
#if DEBUG
            debugPrint("Not App Store build")
            //  Set isDebug to true to see AppsFlyer debug logs
            AppsFlyerLib.shared().isDebug = true
#else
            print("App Store build")
#endif
            
            AppsFlyerLib.shared().start(completionHandler: { (dictionary, error) in
                if (error != nil){
                    debugPrint(error ?? "")
                    return
                } else {
                    debugPrint("Apps Flyers SDK response dictionary: \(dictionary ?? [:])")
                    return
                }
            })
            
            await self.onDataReceived()
            
        } else if (rcAdjust.enabled){
            
            debugPrint("Adjust initiate called with token")
            
            let adjustConfig = ADJConfig(appToken: rcAdjust.appToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.enableSendingInBackground()
            adjustConfig?.enableLinkMe()
            adjustConfig?.delegate = self
            
            Adjust.initSdk(adjustConfig)
            
            Adjust.addGlobalCallbackParameter(mob_sdk_version, forKey: "m_sdk_ver")
            Adjust.addGlobalCallbackParameter(generateUserUUID(), forKey: "user_uuid")
            
            await self.onDataReceived()
            
        }
    }
    
    private func initialiseFacebook() {
        
        if rcFacebook.appID.isEmpty ||  rcFacebook.clientToken.isEmpty
        {
            debugPrint("Facebook sdk keys are empty")
            return
        }
        
        Settings.shared.appID = rcFacebook.appID
        Settings.shared.clientToken = rcFacebook.clientToken
        Settings.shared.enableLoggingBehavior(.appEvents)
        ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
        
        AppLinkUtility.fetchDeferredAppLink { (url, error) in
            if let _ = error {
                debugPrint("Received error while fetching deferred app link %@", error!)
            }
            if let url = url {
                debugPrint("received deffered deeplink url: \(url.absoluteString)")
                let encodedDefferedDeeplink = url.absoluteString.utf8EncodedString()
                saveFbDefferedDeeplink(encodedDefferedDeeplink)
            }
        }
        
        AppEvents.shared.logEvent(AppEvents.Name("MobFlowSDK"))
        
    }
    
    private func initialiseOneSignal(oneSignalKey key: String){
        // Remove this method to stop OneSignal Debugging
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        
        //        OneSignal.setLaunchURLsInApp(false); // before Initialize
        
        // OneSignal initialization
        OneSignal.initialize(key,withLaunchOptions: launchOptions)
        
        self.isOneSignalInitialised = true
    }
    
    private func initialiseClarity(){
        
        if !clarityProjectID.isEmpty {
            
#if DEBUG
            let clarityConfig = ClarityConfig(projectId: clarityProjectID,
                                              logLevel: .verbose,
                                              enableWebViewCapture: true)
            ClaritySDK.setCustomUserId(generateUserUUID())
            ClaritySDK.initialize(config: clarityConfig) {
                debugPrint("Clarity SDK has been initialised.")
            }
#else
            let clarityConfig = ClarityConfig(projectId: clarityProjectID,
                                              enableWebViewCapture: true)
            ClaritySDK.setCustomUserId(generateUserUUID())
            ClaritySDK.initialize(config: clarityConfig)
#endif
        }
    }
    
    public var isAdsEnabled: Bool {
        return showAds
    }
    
    private func initialiseUnityAds() {
        self.unityAdsManager.initializeUnityAds(gameID: self.unityGameId, bannerPlacementID: self.unityBannerId, interstitialPlacementID: self.unityInterestialId, rewardedVideoPlacementID: self.unityRewardedId)
    }
    
    //Banner for UIKit
    @objc public func showBannerAd(vc : UIViewController) {
        if (self.showAds){
            self.unityAdsManager.showBannerAd(viewController: vc)
        }
    }
    
    //Banner for SwiftUI
    public func createBannerView() -> AnyView {
        if self.showAds {
            return AnyView(UnityBannerAdView())
        } else {
            return AnyView(EmptyBannerView())
        }
    }
    
    //based on showAds value, Interestial Ads are shown
    @objc public func showInterestialAd(onClose : @escaping (Bool) -> ()) {
        if (self.showAds) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                self.unityAdsManager.showInterstitialAds(viewController: rootVC, onClose: onClose)
            }
        } else {
            onClose(false)
        }
    }
    
    //based on showAds value, Rewarded Ads are shown
    @objc public func showRewardedAd(onClose : @escaping (Bool) -> ()) {
        if (self.showAds) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                self.unityAdsManager.showRewardedAds(viewController: rootVC, onClose: onClose)
            }
            
        } else {
            onClose(false)
        }
    }
    
    //AppLovin Ads
    //    private func initialiseAppLovin(){
    //        self.appLovinManager.initializeAppLovin(appLovinKey: self.appLovinKey, interestialId: self.appLovinInterestialId, bannerId: self.appLovinBannerId, rewardedId: self.appLovinRewardedId, appOpenAdId: appLovinAppOpenAdId)
    //    }
    //
    //    @objc public func showBannerAd(vc : UIViewController) {
    //        if (self.appLovinBannerId != "" && self.showAds){
    //            self.appLovinManager.loadBannerAd(vc: vc)
    //        }
    //    }
    //
    //    @objc public func showInterestialAd(onClose : @escaping (Bool) -> ()) {
    //        if (self.appLovinInterestialId != "" && self.showAds) {
    //            self.appLovinManager.showInterestialAd(onClose: onClose)
    //        } else {
    //            onClose(false)
    //        }
    //    }
    //
    //    @objc public func showRewardedAd(onClose : @escaping (Bool) -> ()) {
    //        if (self.appLovinRewardedId != "" && self.showAds) {
    //            self.appLovinManager.showRewardedAd(onClose: onClose)
    //        } else {
    //            onClose(false)
    //        }
    //    }
    //
    //    @objc public func showAppOpenAd(onClose : @escaping (Bool) -> ()) {
    //        if (self.appLovinAppOpenAdId != "" && self.showAds) {
    //            self.appLovinManager.showAppOpenAds(onClose: onClose)
    //        } else {
    //            onClose(false)
    //        }
    //    }
    
    @objc private func onDataReceived() async {
        if (endpoint != "") {
            let packageName = Bundle.main.bundleIdentifier ?? ""
            let apiString = "\(endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint)?package=\(packageName)"
            
            printMobLog(description: "fetch endpoint url", value: apiString)
            await self.checkIfEndPointAvailable(endPoint: apiString)
        } else {
            if (self.showAds) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.showRewardedAd { _ in
                        self.showNativeWithPermission(dic: [String : Any]())
                    }
                })
            } else {
                self.showNativeWithPermission(dic: [String : Any]())
            }
        }
    }
    
    private func checkIfEndPointAvailable(endPoint: String) async {
        
        if (endpoint == "") {
            printMobLog(description: "check If EndPoint Available", value: "")
            self.showNativeWithPermission(dic: [:])
        } else {
            self.endpoint = endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint
            printMobLog(description: "check If EndPoint Available", value: self.endpoint)
            
            if (rcAdjust.enabled) {
                
                self.adid = await Adjust.adid() ?? ""
                
                DispatchQueue.main.async {
                    self.startApp()
                }
            } else {
                DispatchQueue.main.async {
                    self.startApp()
                }
            }
        }
        
    }
    
    func createParamsURL() async
    {
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        printMobLog(description:  "GPS_ADID", value: idfa)
        
        
        let idfv = await UIDevice.current.identifierForVendor!.uuidString
        printMobLog(description: "Device ID", value: idfv)
        
        printMobLog(description: "self.AdjustParams before changing macro", value: rcAdjust.macros.description)
        printMobLog(description: "self.AppsFlyersParams before changing macro", value: rcAppsFlyers.macros.description)
        
        var paramsQuery = ""
        if (rcAppsFlyers.enabled) {
            paramsQuery = rcAppsFlyers.macros
                .replacingOccurrences(of: "$campaign_name", with: getAppFlyersCampanName())
                .replacingOccurrences(of: "$idfa", with: idfa)
                .replacingOccurrences(of: "$idfv", with: idfv)
                .replacingOccurrences(of: "$afid", with: AppsFlyerLib.shared().getAppsFlyerUID())
                .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                .replacingOccurrences(of: "$click_id", with: generateUserUUID())
                .replacingOccurrences(of: "$deeplink", with: getDeeplink())
                .replacingOccurrences(of: "$fb_deffered_deeplink", with: getFbDefferedDeeplink())
        } else if (rcAdjust.enabled) {
            
            paramsQuery = rcAdjust.macros
                .replacingOccurrences(of: "$campaign_name", with: await Adjust.attribution()?.campaign ?? "")
                .replacingOccurrences(of: "$idfa", with: idfa)
                .replacingOccurrences(of: "$idfv", with: idfv)
                .replacingOccurrences(of: "$adjust_id", with: self.adid)
                .replacingOccurrences(of: "$deeplink", with: getDeeplink())
                .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                .replacingOccurrences(of: "$click_id", with: generateUserUUID())
                .replacingOccurrences(of: "$fb_deffered_deeplink", with: getFbDefferedDeeplink())
        }
        
        
        
        printMobLog(description: "self.adjustParams after changing macro", value: rcAdjust.macros.description)
        printMobLog(description: "self.AppsFlyersParams after changing macro", value: rcAppsFlyers.macros.description)
        
        let customString =  self.endpoint + "?"  + paramsQuery
        
        printMobLog(description: "create Params URL String", value: customString)
        
        self.customURL = customString
        
    }
    
    func initWebViewURL() -> WebViewController
    {
        let urlToOpen = URL(string: self.customURL)
        let frameworkBundle = Bundle(for: Self.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MobFlowiOS.bundle")
        let bundle = Bundle(url: bundleURL!)
        let storyBoard = UIStoryboard(name: "Main", bundle:bundle)
        let webView = storyBoard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        webView.urlToOpen = urlToOpen!
        webView.schemeURL = self.schemeURL
        webView.addressURL = self.addressURL
        webView.delegate = self
        webView.tintColor = self.tintColor
        webView.backgroundColor = self.backgroundColor
        webView.hideToolbar = self.hideToolbar
        
        return webView
    }
    
    
    func present(webView: WebViewController)
    {
        UIApplication.shared.windows.first?.rootViewController = webView
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    public func showNativeWithPermission(dic: [String : Any]) {
        printMobLog(description: "show Native With Permission", value: "")
        self.hasSwitchedToApp = true
        self.delegate?.present(dic: dic)
        requestPremission()
    }
}

extension MobiFlowSwift : AdjustDelegate {
    
    public func adjustDeferredDeeplinkReceived(_ deeplink: URL?) -> Bool {
        if let url = deeplink{
            let deeplinkStr = url.absoluteString
            let encodedDeeplink = deeplinkStr.utf8EncodedString()
            saveDeeplink(encodedDeeplink)
            
        }
        return false
    }
    
}

extension MobiFlowSwift :  AppsFlyerLibDelegate, DeepLinkDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        
        if let campaign = conversionInfo["campaign"] as? String {
            debugPrint("AppsFlyers: onConversionDataSuccess: campaign: \(campaign)")
            let encodedCampain = campaign.utf8EncodedString()
            saveAppFlyersCampanName(encodedCampain)
        }
        
        if let status = conversionInfo["af_status"] as? String {
            if (status == "Non-organic") {
                // Business logic for Non-organic install scenario is invoked
                debugPrint("AppsFlyers: onConversionDataSuccess: Non-organic install")
            }
            else {
                // Business logic for organic install scenario is invoked
                debugPrint("AppsFlyers: onConversionDataSuccess: Organic install")
            }
        }
    }
    
    public func onConversionDataFail(_ error: Error) {
        // Logic for when conversion data resolution fails
        debugPrint("AppsFlyers: onConversionDataFail: error: \(error.localizedDescription)")
    }
    
    public func didResolveDeepLink(_ result: DeepLinkResult) {
        
        if result.deepLink != nil {
            debugPrint("result.deepLink.debugDescription: \(result.deepLink?.debugDescription ?? "")")
            debugPrint("deeplink",result.deepLink?.deeplinkValue ?? "")
            let receivedDeeplink = result.deepLink?.deeplinkValue ?? ""
            let encodeDeeplink = receivedDeeplink.utf8EncodedString()
            saveDeeplink(encodeDeeplink)
        }
    }
}
