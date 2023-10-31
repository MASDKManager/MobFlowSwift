import UIKit
import Adjust
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import OneSignalFramework
import TikTokBusinessSDK
import StoreKit
import AdServices
import AppsFlyerLib
import FBSDKCoreKit

public class MobiFlowSwift: NSObject
{
    
    private let mob_sdk_version = "3.0.3"
    private var endpoint = ""
    private var oneSignalToken = ""
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    public var customURL = ""
    public var schemeURL = ""
    public var addressURL = ""
    public var showAdsBeforeNative = true
    private var faid = ""
    private var run = false
    private var hasInitialized: Bool = false
    private var hasSwitchedToApp: Bool = false
    public var hideToolbar = false
    private var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    private var backgroundColor = UIColor.white
    private var tintColor = UIColor.black
    private var showAds = true
    //Adjust
    var rcAdjust : RCAdjust!
    private var adid = ""
    //TikTok
    var rcTikTok : RCTikTok!
    
    //AppFlyers
    var rcAppsFlyers : RCAppsFlyers!
    
    //AppLovin
    var appLovinManager = AppLovinManager.shared
    private var appLovinKey = ""
    private var interestialId = ""
    private var bannerId = ""
    private var rewardedId = ""
    private var appOpenAdId = ""
    
    //Facebook
    var rcFacebook : RCFacebook!
    
    let nc = NotificationCenter.default
    
    @objc public init(initDelegate: MobiFlowDelegate , oneSignalToken : String, appLovinKey: String, bannerId: String, interestialId: String, rewardedId: String, appOpenAdId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, isUnityApp: Bool) {
        super.init()
        
        self.delegate = initDelegate
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
        self.bannerId = bannerId
        self.interestialId = interestialId
        self.rewardedId = rewardedId
        self.appLovinKey = appLovinKey
        self.appOpenAdId = appOpenAdId
        
        self.getFirebase()
        self.initialiseAppLovin()
        
        //app enter foreground
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public init(initDelegate: MobiFlowDelegate , oneSignalToken : String, appLovinKey: String, bannerId: String, interestialId: String, rewardedId: String, appOpenAdId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?  ) {
        super.init()
        
        self.delegate = initDelegate
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
        self.bannerId = bannerId
        self.interestialId = interestialId
        self.rewardedId = rewardedId
        self.appLovinKey = appLovinKey
        self.appOpenAdId = appOpenAdId
        
        self.getFirebase()
        self.initialiseAppLovin()
        
        //app enter foreground
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appMovedToForeground() {
        debugPrint("Mobibox: Will Enter Foreground")
        if self.hasSwitchedToApp && (self.endpoint == "") && self.showAds {
            self.appLovinManager.showAppOpenAds { _ in
                debugPrint("successfully shown AppOpen Ads.")
            }
        }
    }
    
    func getFirebase() {
        
        FirebaseApp.configure()
        
        let appDefaults: [String: Any?] = [
            "run": true,
        ]
        
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
        
        RemoteConfig.remoteConfig().fetch { (status, error) in
            if status == .success {
                RemoteConfig.remoteConfig().activate { _, error in
                    DispatchQueue.main.async {
                        
                        self.endpoint = RemoteConfig.remoteConfig()["sub_endios"].stringValue ?? ""
                        self.showAds = RCValues.sharedInstance.showAds()
                        self.rcAdjust = RCValues.sharedInstance.getAdjust()
                        self.rcTikTok = RCValues.sharedInstance.getTikTok()
                        self.rcAppsFlyers = RCValues.sharedInstance.getAppsFlyers()
                        self.rcFacebook = RCValues.sharedInstance.getFacebook()
                        self.run = self.endpoint != ""
                        self.initialiseSDK()
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
        
    }
    
    func initialiseSDK() {
        
        
        if hasInitialized {
            return
        }
        
        self.hasInitialized = true
        
        // Remove this method to stop OneSignal Debugging
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        
//        OneSignal.setLaunchURLsInApp(false); // before Initialize
        
        // OneSignal initialization
        OneSignal.initialize(oneSignalToken,withLaunchOptions: launchOptions)
        
        self.faid = Analytics.appInstanceID() ?? ""
        
        if self.rcTikTok.enabled {
            
            let tiktokID = NSNumber(value:Int(rcTikTok.tiktokAppId) ?? 0)
            let config = TikTokConfig.init(accessToken: rcTikTok.accessToken, appId: rcTikTok.appStoreId, tiktokAppId: tiktokID)
            config?.appTrackingDialogSuppressed = true
            TikTokBusiness.initializeSdk(config)
            
            let tiktokCallbackProperties : [AnyHashable : Any] = [
                "m_sdk_ver" : mob_sdk_version,
                "user_uuid" : generateUserUUID(),
                "firebase_instance_id" : self.faid
            ]
            printMobLog(description: "tiktokCallbackProperties:", value: tiktokCallbackProperties.description)
            
            if (rcTikTok.eventName != "") {
                TikTokBusiness.trackEvent(rcTikTok.eventName, withProperties:tiktokCallbackProperties)
            }
        }
        
        if self.rcFacebook.enabled {
            self.initialiseFacebook()
        }
        
        if (!run) {
            if (self.showAds) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.appLovinManager.showRewardedAd { _ in
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
            debugPrint("App Store build")
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
            
            self.onDataReceived()
            
        } else if (rcAdjust.enabled){
            
            debugPrint("Adjust initiate called with token")
            
            let adjustConfig = ADJConfig(appToken: rcAdjust.appToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.linkMeEnabled = true
            adjustConfig?.delegate = self
            
            Adjust.appDidLaunch(adjustConfig)
            
            Adjust.addSessionCallbackParameter("m_sdk_ver", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: generateUserUUID())
            
            self.onDataReceived()
            
        }
    }
    
    private func initialiseFacebook() {
        
        if rcFacebook.appID.isEmpty ||  rcFacebook.clientToken.isEmpty
        {
            print( "Facebook sdk keys are empty")
            return
        }
        
        Settings.appID = rcFacebook.appID
        Settings.clientToken = rcFacebook.clientToken
        Settings.enableLoggingBehavior(.appEvents)
        ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)

        AppEvents.logEvent(AppEvents.Name("MobFlowSDK"))
        
    }
    
    private func initialiseAppLovin(){
        self.appLovinManager.initializeAppLovin(appLovinKey: self.appLovinKey, interestialId: self.interestialId, bannerId: self.bannerId, rewardedId: self.rewardedId, appOpenAdId: appOpenAdId)
    }
    
    @objc public func showBannerAd(vc : UIViewController) {
        if (self.bannerId != "" && self.showAds){
            self.appLovinManager.loadBannerAd(vc: vc)
        }
    }
    
    @objc public func showInterestialAd(onClose : @escaping (Bool) -> ()) {
        if (self.interestialId != "" && self.showAds) {
            self.appLovinManager.showInterestialAd(onClose: onClose)
        } else {
            onClose(false)
        }
    }
    
    @objc public func showRewardedAd(onClose : @escaping (Bool) -> ()) {
        if (self.rewardedId != "" && self.showAds) {
            self.appLovinManager.showRewardedAd(onClose: onClose)
        } else {
            onClose(false)
        }
    }
    
    @objc private func onDataReceived(){
        if (endpoint != "") {
            let packageName = Bundle.main.bundleIdentifier ?? ""
            let apiString = "\(endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint)?package=\(packageName)"
            
            printMobLog(description: "fetch endpoint url", value: apiString)
            self.checkIfEndPointAvailable(endPoint: apiString)
        } else {
            if (self.showAds) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.appLovinManager.showRewardedAd { _ in
                        self.showNativeWithPermission(dic: [String : Any]())
                    }
                })
            } else {
                self.showNativeWithPermission(dic: [String : Any]())
            }
        }
    }
    
    private func checkIfEndPointAvailable(endPoint: String) {
        
        if (endpoint == "") {
            printMobLog(description: "check If EndPoint Available", value: "")
            self.showNativeWithPermission(dic: [:])
        } else {
            self.endpoint = endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint
            printMobLog(description: "check If EndPoint Available", value: self.endpoint)
            
            if (rcAdjust.enabled) {
                var count = 0
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { callbacktimer in
                    count += 1
                    
                    debugPrint("callbacktimer count: \(count)")
                    self.adid = Adjust.adid() ?? ""
                    
                    if count >= 6 || self.adid != "" {
                        debugPrint("fetching Adjust adid in timer, recived adid: \(self.adid)")
                        self.timer.invalidate()
                        DispatchQueue.main.async {
                            self.startApp()
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    self.startApp()
                }
            }
        }
        
    }
    
    func createParamsURL()
    {

        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        printMobLog(description:  "GPS_ADID", value: idfa)
        
        
        let idfv = UIDevice.current.identifierForVendor!.uuidString
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
        } else if (rcAdjust.enabled) {
            
            paramsQuery = rcAdjust.macros
                .replacingOccurrences(of: "$campaign_name", with: Adjust.attribution()?.campaign ?? "")
                .replacingOccurrences(of: "$idfa", with: idfa)
                .replacingOccurrences(of: "$idfv", with: idfv)
                .replacingOccurrences(of: "$adjust_id", with: self.adid)
                .replacingOccurrences(of: "$deeplink", with: getDeeplink())
                .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                .replacingOccurrences(of: "$click_id", with: generateUserUUID())
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
    
    public func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
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
