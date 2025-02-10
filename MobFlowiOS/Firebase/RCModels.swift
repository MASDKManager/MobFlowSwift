//
//  RCModels.swift
//  MobFlowiOS
//
//  Created by Vishnu  on 12/07/23.
//

import Foundation

// MARK: - RCTikTok
struct RCTikTok : Codable {
    let enabled: Bool
    let accessToken: String
    let appStoreId: String
    let tiktokAppId: String
    let eventName: String
}

// MARK: - RCAppsFlyers
struct RCAppsFlyers : Codable {
    let enabled: Bool
    let devKey: String
    let appStoreId: String
    let macros : String
}

// MARK: - RCAdjust
struct RCAdjust : Codable {
    let enabled: Bool
    let appToken: String
    let macros : String
}

// MARK: - RCOneSignal
struct RCOneSignal : Codable {
    let enabled: Bool
    let one_signal_key: String
}

// MARK: - RCFacebook
struct RCFacebook : Codable {
    let enabled: Bool
    let appID: String
    let clientToken: String
}

// MARK: - RCAppLovin
struct RCAppLovin : Codable {
    let enabled: Bool
    let sdk_key: String
    let banner_id: String
    let interstitial_id: String
    let rewarded_id: String
    let app_open_id: String
}

// MARK: - RCAppodeal
struct RCAppodeal : Codable {
    let enabled: Bool
    let sdk_key: String
}
