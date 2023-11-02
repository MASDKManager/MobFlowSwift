//
//  WebViewControllerDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation
import UIKit


extension MobiFlowSwift: WebViewControllerDelegate
{
   func present(dic: [String : Any])
   {
       self.delegate?.present(dic: dic)
       requestPremission() 
   }
   
    func set(schemeURL: String, addressURL: String, showAds: Bool)
   {
       self.schemeURL = schemeURL
       self.addressURL = addressURL
       self.showAdsBeforeNative = showAds
   }
   
   func startApp()
   {
 
       DispatchQueue.main.async {
          
           if self.schemeURL.isEmpty
           {
               if self.customURL.isEmpty
               {
                   self.createParamsURL()
               }
               let webView = self.initWebViewURL()
               
               if(isReactNative){
                   self.delegate!.present(dic: ["url" : webView.urlToOpen!])
               }else{
                   self.present(webView: webView)
               }
               
           }
           else
           {
               if self.showAdsBeforeNative {
                   self.appLovinManager.showRewardedAd { _ in
                       self.showNativeWithPermission(dic: [String : Any]())
                       let url = URL(string: self.schemeURL)
                       if UIApplication.shared.canOpenURL(url!)
                       {
                           UIApplication.shared.open(url!)
                       }
                   }
               }
               else {
                   self.showNativeWithPermission(dic: [String : Any]())
                   let url = URL(string: self.schemeURL)
                   if UIApplication.shared.canOpenURL(url!)
                   {
                       UIApplication.shared.open(url!)
                   }
               }
           }
          
       }
   }
}

