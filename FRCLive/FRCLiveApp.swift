//
//  FRCLiveApp.swift
//  FRCLive
//
//  Created by Onur Akyüz on 27.04.2026.
//

import SwiftUI

@main
struct FRCLiveApp: App {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""

    var body: some Scene {
        WindowGroup {
            if teamNumber.isEmpty {
                OnboardingView()
            } else if selectedEventCode.isEmpty {
                EventSelectionView()
            } else {
                MainTabContainer()
            }
        }
    }
}
