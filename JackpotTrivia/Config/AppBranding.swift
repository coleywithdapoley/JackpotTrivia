//
//  AppBranding.swift
//  JackpotTrivia
//
//  Single reference for names shown on device vs. in-app copy.
//  - Home screen / App Store label: Info.plist CFBundleDisplayName + build setting INFOPLIST_KEY_CFBundleDisplayName
//  - In-app strings: AppConfig.appDisplayName
//

import Foundation

enum AppBranding {
    /// Must match CFBundleDisplayName in Info.plist for a consistent handoff.
    static let bundleDisplayName = "If You Know, You Win"
}
