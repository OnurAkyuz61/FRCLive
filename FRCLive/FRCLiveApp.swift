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
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            rootView
            .onAppear {
                WidgetDataStore.syncAppState(
                    teamNumber: teamNumber,
                    selectedEventCode: selectedEventCode,
                    languageCode: appLanguageRaw
                )
            }
            .onChange(of: teamNumber) { _, newValue in
                WidgetDataStore.syncAppState(
                    teamNumber: newValue,
                    selectedEventCode: selectedEventCode,
                    languageCode: appLanguageRaw
                )
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { await LiveActivityManager.shared.end() }
                }
            }
            .onChange(of: selectedEventCode) { _, newValue in
                WidgetDataStore.syncAppState(
                    teamNumber: teamNumber,
                    selectedEventCode: newValue,
                    languageCode: appLanguageRaw
                )
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { await LiveActivityManager.shared.end() }
                }
            }
            .onChange(of: appLanguageRaw) { _, newValue in
                WidgetDataStore.syncAppState(
                    teamNumber: teamNumber,
                    selectedEventCode: selectedEventCode,
                    languageCode: newValue
                )
            }
            .preferredColorScheme(appTheme.colorScheme)
        }
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    @ViewBuilder
    private var rootView: some View {
        if teamNumber.isEmpty {
            OnboardingView()
        } else if selectedEventCode.isEmpty {
            EventSelectionView()
        } else {
            MainTabContainer()
        }
    }
}
