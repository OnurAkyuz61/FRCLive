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
        var languageCode: String
    }
}

struct FRCLiveWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FRCLiveActivityAttributes.self) { context in
            let isEnglish = context.state.languageCode == "en"
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(isEnglish ? "Team" : "Takım") \(context.state.teamNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 10)
                    Text(context.state.eventName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(context.state.nextMatch)
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(context.state.status)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(isEnglish ? "On field" : "Şu an sahada"): \(context.state.currentOnField)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.blue.opacity(0.12))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            let isEnglish = context.state.languageCode == "en"
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(isEnglish ? "Team" : "Takım")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.teamNumber)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(isEnglish ? "Next" : "Sıradaki")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.nextMatch)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.status)
                            .lineLimit(1)
                        Spacer()
                        Text("\(isEnglish ? "Field" : "Saha"): \(context.state.currentOnField)")
                            .lineLimit(1)
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
            estimatedStart: "10 dk",
            languageCode: "tr"
        )
    }
}

#Preview("Notification", as: .content, using: FRCLiveActivityAttributes.preview) {
   FRCLiveWidgetsLiveActivity()
} contentStates: {
    FRCLiveActivityAttributes.ContentState.preview
}
