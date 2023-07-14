import UIKit
import Adjust
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import OneSignal
import TikTokBusinessSDK

public class MobiFlowSwift: NSObject
{
     
    private let mob_sdk_version = "2.1.7"
    private var endpoint = ""
    private var adjustToken = ""
    private var adjustEventToken = ""
    private var oneSignalToken = ""
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    public var customURL = ""
    public var schemeURL = ""
    public var addressURL = ""
    private var faid = ""
    private var params = "naming=$adjust_campaign_name&gps_adid=$idfa&adid=$adjust_id&idfv=$idfv&deeplink=$deeplink&firebase_instance_id=$firebase_instance_id&package=$package_id&click_id=$click_id&adjust_attribution=$adjust_attribution"
    private var run = false
    private var hasInitialized: Bool = false
    public var hideToolbar = false
    private var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    private var backgroundColor = UIColor.white
    private var tintColor = UIColor.black
  
    //TikTok
    var rcTikTok : RCTikTok!
    
    //AppLovin
    private var appLovinManager = AppLovinManager.shared
    private var rewardedId = ""
    private var interestialId = ""
    private var bannerId = ""
    
    let nc = NotificationCenter.default
    
    @objc public init(initDelegate: MobiFlowDelegate , adjustToken : String  , adjustEventToken : String , oneSignalToken : String ,launchOptions: [UIApplication.LaunchOptionsKey: Any]?, isUnityApp: Bool) {
        super.init()
        
        self.delegate = initDelegate
        self.adjustToken = adjustToken
        self.adjustEventToken = adjustEventToken
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
 
        
        self.getFirebase()
    }
    
    public init(initDelegate: MobiFlowDelegate , adjustToken : String  , adjustEventToken : String , oneSignalToken : String, bannerId: String, interestialId: String, rewardedId: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?  ) {
        super.init()
        
        self.delegate = initDelegate
        self.adjustToken = adjustToken
        self.adjustEventToken = adjustEventToken
        self.oneSignalToken = oneSignalToken
        self.launchOptions = launchOptions
        self.bannerId = bannerId
        self.interestialId = interestialId
        self.rewardedId = rewardedId
        
        self.getFirebase()
        if (!(bannerId == "" && interestialId == "" && rewardedId == "")) {
            self.initialiseAppLovin()
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
                        self.rcTikTok = RCValues.sharedInstance.getTikTok()
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
        
        
        if(run){
            
            printMobLog(description: "Adjust initiate called with token", value:  "")
            
            let adjustConfig = ADJConfig(appToken: adjustToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.linkMeEnabled = true
              
            Adjust.appDidLaunch(adjustConfig)
            
            Adjust.addSessionCallbackParameter("m_sdk_ver", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: generateUserUUID())
           // Adjust.addSessionCallbackParameter("firebase_instance_id", value: self.faid)
            
            let adjustEvent = ADJEvent(eventToken: adjustEventToken)
            adjustEvent?.addCallbackParameter("eventValue", value: self.faid) //firebase Instance Id
            adjustEvent?.addCallbackParameter("click_id", value: generateUserUUID())
            
            Adjust.trackEvent(adjustEvent)
             
            self.onDataReceived()
            
        }else{
            self.showNativeWithPermission(dic: [String : Any]())
        }
    }
    
    private func initialiseAppLovin(){
        self.appLovinManager.initializeAppLovin(rewardedId: self.rewardedId, interestialId: self.interestialId, bannerId: self.bannerId)
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
    
    @objc public func showRewardedAd(onClose : @escaping (Bool) -> ()) {
        if (self.rewardedId != "") {
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
            self.showNativeWithPermission(dic: [:])
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
        
        printMobLog(description: "self.params before changing macro", value: self.params.description)
         
        
        let paramsQuery = self.params
                            .replacingOccurrences(of: "$adjust_campaign_name", with: Adjust.attribution()?.campaign ?? "")
                            .replacingOccurrences(of: "$idfa", with: idfa)
                            .replacingOccurrences(of: "$idfv", with: idfv)
                            .replacingOccurrences(of: "$adjust_id", with: Adjust.adid() ?? "")
                            .replacingOccurrences(of: "$deeplink", with: "")
                            .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                            .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                            .replacingOccurrences(of: "$click_id", with: generateUserUUID())
                            .replacingOccurrences(of: "$adjust_attribution", with: encodedAdjustAttributes)
                         
        printMobLog(description: "self.params after changing macro", value: self.params.description)
        
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
        self.delegate?.present(dic: dic)
        requestPremission()
    }
}
