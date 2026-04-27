//
//  FRCLiveWidgetsLiveActivity.swift
//  FRCLiveWidgets
//
//  Created by Onur Akyüz on 27.04.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FRCLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var teamNumber: String
        var eventName: String
        var nextMatch: String
        var status: String
        var currentOnField: String
        var estimatedStart: String
    }
}

struct FRCLiveWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FRCLiveActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Takım \(context.state.teamNumber)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(context.state.eventName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(context.state.nextMatch)
                    .font(.title2.weight(.bold))
                Text(context.state.status)
                    .font(.subheadline.weight(.medium))
                Text("Şu an sahada: \(context.state.currentOnField)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .activityBackgroundTint(Color.blue.opacity(0.12))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Takım")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.teamNumber)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Sıradaki")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.nextMatch)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.status)
                        Spacer()
                        Text("Saha: \(context.state.currentOnField)")
                    }
                    .font(.subheadline)
                }
            } compactLeading: {
                Text(context.state.teamNumber)
                    .font(.caption2.weight(.semibold))
            } compactTrailing: {
                Text(context.state.nextMatch)
                    .font(.caption2.weight(.semibold))
            } minimal: {
                Text("FRC")
                    .font(.caption2.weight(.bold))
            }
            .widgetURL(URL(string: "frclive://dashboard"))
            .keylineTint(Color.blue)
        }
    }
}

extension FRCLiveActivityAttributes {
    fileprivate static var preview: FRCLiveActivityAttributes {
        FRCLiveActivityAttributes()
    }
}

extension FRCLiveActivityAttributes.ContentState {
    fileprivate static var preview: FRCLiveActivityAttributes.ContentState {
        FRCLiveActivityAttributes.ContentState(
            teamNumber: "99999",
            eventName: "Demo Active Regional",
            nextMatch: "Qual 42",
            status: "Kuyruğa çağrıldı",
            currentOnField: "Qual 34",
            estimatedStart: "10 dk"
        )
    }
}

#Preview("Notification", as: .content, using: FRCLiveActivityAttributes.preview) {
   FRCLiveWidgetsLiveActivity()
} contentStates: {
    FRCLiveActivityAttributes.ContentState.preview
}
