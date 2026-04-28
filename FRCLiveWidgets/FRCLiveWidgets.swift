//
//  FRCLiveWidgets.swift
//  FRCLiveWidgets
//
//  Created by Onur Akyüz on 27.04.2026.
//

import WidgetKit
import SwiftUI

private enum WidgetSharedKeys {
    static let appGroupID = "group.onurakyuz.FRCLive"
}

struct FRCLiveWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: WidgetSharedKeys.appGroupID) ?? UserDefaults.standard
        let languageCode = defaults.string(forKey: "widget_languageCode") ?? "tr"
        let isEnglish = languageCode == "en"
        let rawTeamNumber = defaults.string(forKey: "widget_teamNumber") ?? defaults.string(forKey: "teamNumber") ?? ""
        let teamNumber = rawTeamNumber.isEmpty ? "----" : rawTeamNumber
        let eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Please enter a team number" : "Lutfen bir takim numarasi girin")
        let nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
        let queueStatus = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Waiting for team selection" : "Takim secimi bekleniyor")
        let updatedAt = defaults.string(forKey: "widget_updatedAt") ?? (isEnglish ? "Just now" : "Az once")
        return SimpleEntry(
            date: Date(),
            teamNumber: teamNumber,
            eventName: eventName,
            nextMatch: nextMatch,
            queueStatus: queueStatus,
            updatedAt: updatedAt,
            languageCode: languageCode
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date

    let teamNumber: String
    let eventName: String
    let nextMatch: String
    let queueStatus: String
    let updatedAt: String
    let languageCode: String

    static let preview = SimpleEntry(
        date: .now,
        teamNumber: "99999",
        eventName: "Demo Active Regional",
        nextMatch: "Qual 42",
        queueStatus: "Kuyruğa çağrıldı",
        updatedAt: "Az önce",
        languageCode: "tr"
    )
}

struct FRCLiveWidgetsEntryView: View {
    var entry: FRCLiveWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    private var isEnglish: Bool { entry.languageCode == "en" }
    private var processBlue: Color { Color(red: 0/255, green: 156/255, blue: 215/255) }
    private var cardBackground: Color {
        colorScheme == .dark ? processBlue.opacity(0.45) : processBlue.opacity(0.28)
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(entry.eventName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(entry.nextMatch)
                .font(.title3.weight(.bold))
                .lineLimit(1)
            Text(entry.queueStatus)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(entry.updatedAt)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
        )
    }

    private var mediumWidget: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.eventName)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.nextMatch)
                    .font(.title3.weight(.bold))
                Text(entry.queueStatus)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "bolt.shield")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(processBlue)
                Text(entry.updatedAt)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
        )
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FRCLive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                .font(.headline)
            Text(entry.eventName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Text(entry.nextMatch)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .lineLimit(1)
            Text(entry.queueStatus)
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
            Text("\(isEnglish ? "Updated" : "Güncelleme"): \(entry.updatedAt)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }
}

struct FRCLiveWidgets: Widget {
    let kind: String = "FRCLiveWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FRCLiveWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                FRCLiveWidgetsEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                FRCLiveWidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("FRCLive")
        .description("Takım maç sırası ve kuyruk durumunu gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    FRCLiveWidgets()
} timeline: {
    SimpleEntry.preview
}
