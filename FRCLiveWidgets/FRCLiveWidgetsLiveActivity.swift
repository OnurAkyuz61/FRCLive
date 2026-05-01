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
        var statusCode: String
        var currentOnField: String
        var estimatedStart: String
        var languageCode: String
    }
}

struct FRCLiveWidgetsLiveActivity: Widget {
    private let islandHorizontalInset: CGFloat = 8

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FRCLiveActivityAttributes.self) { context in
            let isEnglish = context.state.languageCode == "en"
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text("\(isEnglish ? "Team" : "Takım") \(context.state.teamNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 10)
                    Text(context.state.eventName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
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
            let shortNext = compactMatchText(context.state.nextMatch)
            let shortStatus = compactStatusText(
                raw: context.state.status,
                statusCode: context.state.statusCode,
                isEnglish: isEnglish
            )
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(isEnglish ? "Team" : "Takım")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.teamNumber)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, islandHorizontalInset)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(isEnglish ? "Next" : "Sıradaki")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(shortNext)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, islandHorizontalInset)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(shortStatus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(isEnglish ? "Field" : "Saha"): \(compactMatchText(context.state.currentOnField))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, islandHorizontalInset)
                }
            } compactLeading: {
                Text(context.state.teamNumber)
                    .font(.caption2.weight(.semibold))
            } compactTrailing: {
                Text(shortNext)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            } minimal: {
                Text("FRC")
                    .font(.caption2.weight(.bold))
            }
            .widgetURL(URL(string: "frclive://dashboard"))
            .keylineTint(Color.blue)
        }
    }

    private func compactMatchText(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "-" }
        let lower = trimmed.lowercased()
        if lower.contains("qualification"), let number = trailingNumber(in: trimmed) {
            return "Q\(number)"
        }
        if lower.contains("practice"), let number = trailingNumber(in: trimmed) {
            return "P\(number)"
        }
        if (lower.contains("playoff") || lower.contains("final")), let number = trailingNumber(in: trimmed) {
            return "M\(number)"
        }
        if trimmed.count > 14 {
            return String(trimmed.prefix(14))
        }
        return trimmed
    }

    private func compactStatusText(raw: String, statusCode: String, isEnglish: Bool) -> String {
        switch statusCode.lowercased() {
        case "not called":
            return isEnglish ? "Not Called" : "Çağrılmadı"
        case "called to queue", "called":
            return isEnglish ? "Called" : "Çağrıldı"
        case "on field":
            return isEnglish ? "On Field" : "Sahada"
        case "unknown":
            return isEnglish ? "Unknown" : "Bilinmiyor"
        default:
            break
        }

        let lower = raw.lowercased()
        if lower.contains("not called") || lower.contains("henüz") || lower.contains("çağrılmadı") {
            return isEnglish ? "Not Called" : "Çağrılmadı"
        }
        if lower.contains("on field") || lower.contains("sahada") {
            return isEnglish ? "On Field" : "Sahada"
        }
        if lower.contains("called") || lower.contains("çağr") {
            return isEnglish ? "Called" : "Çağrıldı"
        }

        return raw
    }

    private func trailingNumber(in text: String) -> String? {
        let parts = text.split(separator: " ")
        guard let last = parts.last else { return nil }
        let value = String(last).trimmingCharacters(in: .punctuationCharacters)
        guard !value.isEmpty, value.allSatisfy(\.isNumber) else { return nil }
        return value
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
            statusCode: "Called to Queue",
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
