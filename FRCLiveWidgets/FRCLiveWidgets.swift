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
        let eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Please enter a team number" : "Lütfen bir takım numarası girin")
        let nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
        let queueStatus = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Waiting for team selection" : "Takım seçimi bekleniyor")
        let updatedAt = defaults.string(forKey: "widget_updatedAt") ?? (isEnglish ? "Just now" : "Az önce")
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
    private var isEnglish: Bool { entry.languageCode == "en" }
    private var processBlue: Color { Color(red: 0/255, green: 156/255, blue: 215/255) }
    private var compactNextMatch: String {
        entry.nextMatch
            .replacingOccurrences(of: "Qualification", with: "Qual")
            .replacingOccurrences(of: "Practice", with: "Prac")
            .replacingOccurrences(of: "Playoff", with: "PO")
    }
    private var compactQueueStatus: String {
        let status = entry.queueStatus
        if status.count <= 14 { return status }
        if status.lowercased().contains("called") || status.lowercased().contains("çağr") {
            return isEnglish ? "Called" : "Çağrıldı"
        }
        if status.lowercased().contains("field") || status.lowercased().contains("saha") {
            return isEnglish ? "On Field" : "Sahada"
        }
        if status.lowercased().contains("not") || status.lowercased().contains("henüz") {
            return isEnglish ? "Not Called" : "Çağrılmadı"
        }
        return String(status.prefix(14))
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
        VStack(alignment: .leading, spacing: 6) {
            Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.92))
            Text(entry.eventName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineLimit(1)
            Text(compactNextMatch)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(compactQueueStatus)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineLimit(1)
            Spacer()
            Text(entry.updatedAt)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }

    private var mediumWidget: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                Text(entry.eventName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(entry.nextMatch)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(entry.queueStatus)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "bolt.shield")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(entry.updatedAt)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FRCLive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.88))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(entry.eventName)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineLimit(1)
            }

            Divider().overlay(Color.white.opacity(0.28))

            Text(compactNextMatch)
                .font(.system(size: 45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(compactQueueStatus)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .lineLimit(1)

            HStack {
                Text("\(isEnglish ? "Updated" : "Güncelleme"): \(entry.updatedAt)")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.78))
                Spacer()
                Image(systemName: "bolt.shield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }
}

struct FRCLiveWidgets: Widget {
    let kind: String = "FRCLiveWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FRCLiveWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                FRCLiveWidgetsEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(red: 0/255, green: 156/255, blue: 215/255)
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
