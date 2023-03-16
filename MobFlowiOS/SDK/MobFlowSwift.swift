import UIKit
import Adjust
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import FirebaseRemoteConfig
import OneSignal


public class MobiFlowSwift: NSObject
{
     
    
    private let mob_sdk_version = "2.0.3"
    private var endpoint = ""
    private var adjustToken = ""
    private var adjustEventToken = ""
    public var customURL = ""
    public var schemeURL = ""
    public var addressURL = ""
    private var faid = ""
    private var params = "naming=$adjust_campaign_name&gps_adid=$idfa&adid=$adjust_id&idfv=$idfv&deeplink=$deeplink&firebase_instance_id=$firebase_instance_id&package=$package_id&click_id=$click_id&adjust_attribution=$adjust_attribution&appmetrica_device_id=$appmetrica_device_id"
    private var run = true
    private var hasInitialized: Bool = false
    public var hideToolbar = false
    private var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    private var backgroundColor = UIColor.white
    private var tintColor = UIColor.black
 
    let nc = NotificationCenter.default
    
    public init(initDelegate: MobiFlowDelegate, endpoint : String , adjustToken : String  , adjustEventToken : String , oneSignalToken : String ,launchOptions: [UIApplication.LaunchOptionsKey: Any]?  ) {
        super.init()
        
        self.delegate = initDelegate
        self.endpoint = endpoint
        self.adjustToken = adjustToken
        self.adjustEventToken = adjustEventToken
 
        
        FirebaseApp.configure()
         
        let appDefaults: [String: Any?] = [
            "run": true,
        ]
        
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])

        RemoteConfig.remoteConfig().fetch { (status, error) in
            if status == .success {
                RemoteConfig.remoteConfig().activate { _, error in
                    DispatchQueue.main.async {
                        self.run = RemoteConfig.remoteConfig().configValue(forKey: "run").boolValue
                        self.initialiseSDK()
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.run = true
            self.initialiseSDK()
        }
        
        // Remove this method to stop OneSignal Debugging
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        
        OneSignal.setLaunchURLsInApp(false); // before Initialize
        
        // OneSignal initialization
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId(oneSignalToken)
        
        // promptForPushNotifications will show the native iOS notification permission prompt.
        // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
        OneSignal.promptForPushNotifications(userResponse: { accepted in
          print("User accepted notifications: \(accepted)")
        })
          
    }

    func initialiseSDK() {
        
        if hasInitialized {
            return
        }
        
        self.hasInitialized = true
        
        if(run){
            
            printMobLog(description: "Adjust initiate called with token", value:  "")
            
            let adjustConfig = ADJConfig(appToken: adjustToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.delegate = self
            adjustConfig?.linkMeEnabled = true
              
            Adjust.appDidLaunch(adjustConfig)
            
            Adjust.addSessionCallbackParameter("m_sdk_ver", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: generateUserUUID())
           // Adjust.addSessionCallbackParameter("firebase_instance_id", value: self.faid)
            
            self.faid = Analytics.appInstanceID() ?? ""
            let adjustEvent = ADJEvent(eventToken: adjustEventToken)
            adjustEvent?.addCallbackParameter("eventValue", value: self.faid) //firebase Instance Id
            adjustEvent?.addCallbackParameter("click_id", value: generateUserUUID())
            
            Adjust.trackEvent(adjustEvent)
             
            self.onDataReceived()
            
        }else{
            self.showNativeWithPermission(dic: [String : Any]())
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
