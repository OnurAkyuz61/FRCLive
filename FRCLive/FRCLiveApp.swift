//
//  FRCLiveApp.swift
//  FRCLive
//
//  Created by Onur Akyüz on 27.04.2026.
//

import SwiftUI

@main
struct FRCLiveApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var notificationAppDelegate
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue

    var body: some Scene {
        WindowGroup {
            if teamNumber.isEmpty {
                OnboardingView()
            } else if selectedEventCode.isEmpty {
                EventSelectionView()
            } else {
                MainTabContainer()
            }
            .onAppear {
                WidgetDataStore.syncIdentity(teamNumber: teamNumber, languageCode: appLanguageRaw)
            }
            .onChange(of: teamNumber) { _, newValue in
                WidgetDataStore.syncIdentity(teamNumber: newValue, languageCode: appLanguageRaw)
            }
            .onChange(of: appLanguageRaw) { _, newValue in
                WidgetDataStore.syncIdentity(teamNumber: teamNumber, languageCode: newValue)
            }
        }
    }
}
