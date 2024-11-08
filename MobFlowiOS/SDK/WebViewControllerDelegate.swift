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
    
    func startApp() {
        DispatchQueue.main.async {
            // Check if `schemeURL` is empty
            if self.schemeURL.isEmpty {
                Task {
                    // Ensure `createParamsURL` completes before moving forward
                    if self.customURL.isEmpty {
                        await self.createParamsURL()
                    }
                    
                    let webView = self.initWebViewURL()
                    
                    // Present web view based on `isReactNative` flag
                    if self.isReactNative {
                        self.delegate?.present(dic: ["url" : webView.urlToOpen!])
                    } else {
                        self.present(webView: webView)
                    }
                }
            } else {
                // Handle when `schemeURL` is not empty and `showAdsBeforeNative` is true
                if self.showAdsBeforeNative {
                    self.showRewardedAd { _ in
                        self.showNativeWithPermission(dic: [String : Any]())
                        if let url = URL(string: self.schemeURL), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else {
                    // Handle when `schemeURL` is not empty and `showAdsBeforeNative` is false
                    self.showNativeWithPermission(dic: [String : Any]())
                    if let url = URL(string: self.schemeURL), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

