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
