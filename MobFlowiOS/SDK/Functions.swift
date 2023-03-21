//
//  Functions.swift
//  MobFlowiOS
//
//  Created by Maarouf on 7/6/22.
//

import Foundation
import AppTrackingTransparency
import FirebaseCore
import FirebaseAnalytics
import OneSignal

let USERDEFAULT_CustomUUID = "USERDEFAULT_CustomUUID"
 
func currentTimeInMilliSeconds() -> String {
    let currentDate = Date()
    let since1970 = currentDate.timeIntervalSince1970
    let intTimeStamp = Int(since1970 * 1000)
    return "\(intTimeStamp)"
}

func fetchDataWithUrl(urlString: String, completionHendler:@escaping (_ response:Dictionary<String,AnyObject>?, _ success: Bool)-> Void) {
    
    if let url = URL(string: urlString) {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 60
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error -> Void in
            do {
                if (data == nil){
                    completionHendler([:],false)
                } else {
                    if let json = try JSONSerialization.jsonObject(with: data!) as? Dictionary<String, AnyObject> {
                        completionHendler(json,true)
                    } else {
                        completionHendler([:],false)
                    }
                }
            } catch {
                completionHendler([:],false)
            }
        })
        
        task.resume()
    }
}

func requestPremission()
{
    if #available(iOS 14, *)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            
            ATTrackingManager.requestTrackingAuthorization { (authStatus) in
                switch authStatus
                {
                case .notDetermined:
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                case .denied:
                    print("Denied")
                case .authorized:
                    print("Authorized")
                @unknown default:
                    break
                }
            }
        })
    }
    
    // promptForPushNotifications will show the native iOS notification permission prompt.
    // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
    })
}

func generateUserUUID() -> String {
    
    var md5UUID = getUserUUID()
    
    if (md5UUID == "") {
        var uuid = ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let customTimeStamp = currentTimeInMilliSeconds()
        
        uuid = deviceId + customTimeStamp
        
        md5UUID = uuid.md5()
        saveUserUUID(value: md5UUID)
    }
    
    return md5UUID
}

func getUserUUID() -> String {
    return UserDefaults.standard.string(forKey: USERDEFAULT_CustomUUID) ?? ""
}

func saveUserUUID(value:String) {
    return UserDefaults.standard.set(value, forKey: USERDEFAULT_CustomUUID)
}

func logEvent(eventName : String, log : String){
    
    let parameter = [
        "parameter": log as NSObject
    ]
    
    Analytics.logEvent(eventName, parameters: parameter)
    
}

func printMobLog(description: String, value : String) {
    
#if DEBUG
    print("\(description) : \(value)")
#else
    
#endif
    
}

 
