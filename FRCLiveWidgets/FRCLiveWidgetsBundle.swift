//
//  FRCLiveWidgetsBundle.swift
//  FRCLiveWidgets
//
//  Created by Onur Akyüz on 27.04.2026.
//

import WidgetKit
import SwiftUI

@main
struct FRCLiveWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FRCLiveWidgets()
        FRCLiveWidgetsLiveActivity()
    }
}
