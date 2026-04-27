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
        let teamNumber = defaults.string(forKey: "widget_teamNumber") ?? "----"
        let eventName = defaults.string(forKey: "widget_eventName") ?? "Etkinlik seçilmedi"
        let nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "Qual 42"
        let queueStatus = defaults.string(forKey: "widget_queueStatus") ?? "Kuyruğa çağrıldı"
        let updatedAt = defaults.string(forKey: "widget_updatedAt") ?? "Az önce"
        return SimpleEntry(
            date: Date(),
            teamNumber: teamNumber,
            eventName: eventName,
            nextMatch: nextMatch,
            queueStatus: queueStatus,
            updatedAt: updatedAt
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

    static let preview = SimpleEntry(
        date: .now,
        teamNumber: "99999",
        eventName: "Demo Active Regional",
        nextMatch: "Qual 42",
        queueStatus: "Kuyruğa çağrıldı",
        updatedAt: "Az önce"
    )
}

struct FRCLiveWidgetsEntryView: View {
    var entry: FRCLiveWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

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
            Text("Takım \(entry.teamNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
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
    }

    private var mediumWidget: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Takım \(entry.teamNumber)")
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
                Image("FIRST_Vertical_RGB")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                Text(entry.updatedAt)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FRCLive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Takım \(entry.teamNumber)")
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
            Text("Güncelleme: \(entry.updatedAt)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

struct FRCLiveWidgets: Widget {
    let kind: String = "FRCLiveWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FRCLiveWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                FRCLiveWidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
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
