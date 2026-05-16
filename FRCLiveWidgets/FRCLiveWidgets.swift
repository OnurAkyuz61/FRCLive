//
//  FRCLiveWidgets.swift
//  FRCLiveWidgets
//

import WidgetKit
import SwiftUI

private enum WidgetSharedKeys {
    static let appGroupID = "group.onurakyuz.FRCLive"
}

// MARK: - Timeline

struct FRCLiveWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date())
            ?? Date().addingTimeInterval(5 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> SimpleEntry {
        let defaults = UserDefaults(suiteName: WidgetSharedKeys.appGroupID) ?? UserDefaults.standard
        let languageCode = defaults.string(forKey: "widget_languageCode") ?? "tr"
        let rawTeamNumber = defaults.string(forKey: "widget_teamNumber") ?? defaults.string(forKey: "teamNumber") ?? ""
        let teamNumber = rawTeamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let teamName = defaults.string(forKey: "widget_teamName") ?? ""
        let eventName = defaults.string(forKey: "widget_eventName") ?? ""
        let nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
        let currentOnField = defaults.string(forKey: "widget_currentOnField") ?? "-"
        let queueStatus = defaults.string(forKey: "widget_queueStatus") ?? ""
        let queueStatusCode = defaults.string(forKey: "widget_queueStatusCode") ?? ""
        let updatedAt = defaults.string(forKey: "widget_updatedAt") ?? ""

        return SimpleEntry(
            date: Date(),
            teamNumber: teamNumber.isEmpty ? "" : teamNumber,
            teamName: teamName,
            eventName: eventName,
            nextMatch: nextMatch,
            currentOnField: currentOnField,
            queueStatus: queueStatus,
            queueStatusCode: queueStatusCode,
            updatedAt: updatedAt.isEmpty ? (languageCode == "en" ? "Now" : "Şimdi") : updatedAt,
            languageCode: languageCode
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let teamNumber: String
    let teamName: String
    let eventName: String
    let nextMatch: String
    let currentOnField: String
    let queueStatus: String
    let queueStatusCode: String
    let updatedAt: String
    let languageCode: String

    static let preview = SimpleEntry(
        date: .now,
        teamNumber: "99999",
        teamName: "Demo Robotics",
        eventName: "Demo Active Regional",
        nextMatch: "Qual 42",
        currentOnField: "Qual 34",
        queueStatus: "Bekleme alanında",
        queueStatusCode: "On deck",
        updatedAt: "23:25",
        languageCode: "tr"
    )

    static let previewNeedsTeam = SimpleEntry(
        date: .now,
        teamNumber: "",
        teamName: "",
        eventName: "",
        nextMatch: "-",
        currentOnField: "-",
        queueStatus: "",
        queueStatusCode: "waiting_team_selection",
        updatedAt: "23:25",
        languageCode: "tr"
    )
}

// MARK: - Presentation

private enum WidgetPresentationState {
    case needsTeam
    case needsEvent
    case loading
    case noUpcomingMatch
    case live
}

struct FRCLiveWidgetsEntryView: View {
    var entry: FRCLiveWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var isEnglish: Bool { entry.languageCode == "en" }
    private var state: WidgetPresentationState { resolveState(entry) }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemLarge:
                largeWidget
            default:
                mediumWidget
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
    }

    private var contentPadding: CGFloat {
        switch family {
        case .systemSmall: return 10
        case .systemLarge: return 14
        default: return 12
        }
    }

    // MARK: Small

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            brandCaption

            switch state {
            case .needsTeam:
                setupIcon("person.crop.circle.badge.plus")
                Text(L10nWidget.needsTeamTitle(isEnglish))
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            case .needsEvent:
                teamLineSmall
                Text(L10nWidget.needsEventTitle(isEnglish))
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            case .loading:
                teamLineSmall
                ProgressView().tint(.white).scaleEffect(0.85)
                Text(L10nWidget.loading(isEnglish))
                    .font(.caption2)
                    .lineLimit(2)
            case .noUpcomingMatch:
                teamLineSmall
                Text(L10nWidget.noMatchShort(isEnglish))
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
            case .live:
                teamLineSmall
                matchHeadline(compact: true)
                Text(queueStatusLine)
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
            footerCompact
        }
    }

    // MARK: Medium

    private var mediumWidget: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                brandCaption

                switch state {
                case .needsTeam:
                    setupIcon("person.crop.circle.badge.plus", large: true)
                    Text(L10nWidget.needsTeamTitle(isEnglish))
                        .font(.subheadline.weight(.bold))
                        .lineLimit(2)
                    Text(L10nWidget.needsTeamSubtitle(isEnglish))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                case .needsEvent:
                    teamLineMedium
                    Text(L10nWidget.needsEventTitle(isEnglish))
                        .font(.subheadline.weight(.bold))
                        .lineLimit(2)
                    Text(L10nWidget.needsEventSubtitle(isEnglish))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                case .loading:
                    teamLineMedium
                    Text(L10nWidget.loading(isEnglish))
                        .font(.subheadline.weight(.semibold))
                    ProgressView().tint(.white)
                case .noUpcomingMatch:
                    teamLineMedium
                    Text(L10nWidget.noMatchTitle(isEnglish))
                        .font(.headline.weight(.bold))
                        .lineLimit(2)
                    Text(L10nWidget.noMatchSubtitle(isEnglish))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                case .live:
                    teamLineMedium
                    eventLine
                    matchHeadline(compact: false)
                    Text(queueStatusLine)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    onFieldLine
                }

                Spacer(minLength: 0)
                footerCompact
            }

            Spacer(minLength: 4)
            Image(systemName: "bolt.shield")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    // MARK: Large

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                brandCaption
                Spacer()
                Image(systemName: "bolt.shield")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.bottom, 8)

            switch state {
            case .needsTeam:
                largeSetupContent(
                    icon: "person.crop.circle.badge.plus",
                    title: L10nWidget.needsTeamTitle(isEnglish),
                    subtitle: L10nWidget.needsTeamSubtitle(isEnglish)
                )
            case .needsEvent:
                VStack(alignment: .leading, spacing: 6) {
                    teamLineLarge
                    Text(L10nWidget.needsEventTitle(isEnglish))
                        .font(.title2.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(L10nWidget.needsEventSubtitle(isEnglish))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                }
            case .loading:
                VStack(alignment: .leading, spacing: 10) {
                    teamLineLarge
                    eventLine
                    ProgressView().tint(.white).scaleEffect(1.1)
                    Text(L10nWidget.loading(isEnglish))
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                }
            case .noUpcomingMatch:
                VStack(alignment: .leading, spacing: 8) {
                    teamLineLarge
                    eventLine
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(L10nWidget.noMatchTitle(isEnglish))
                        .font(.title.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(L10nWidget.noMatchSubtitle(isEnglish))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                    onFieldLine
                }
            case .live:
                VStack(alignment: .leading, spacing: 8) {
                    teamLineLarge
                    eventLine
                    Text(L10nWidget.nextMatchLabel(isEnglish))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 2)
                    matchHeadline(compact: false)
                        .padding(.top, -4)
                    Text(queueStatusLine)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    onFieldLine
                }
            }

            Spacer(minLength: 0)
            footerLarge
                .padding(.top, 8)
        }
    }

    // MARK: Shared pieces

    private var brandCaption: some View {
        Text("FRCLive")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
    }

    private var teamLineSmall: some View {
        Text(teamDisplayShort)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var teamLineMedium: some View {
        Text(teamDisplayLong)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }

    private var teamLineLarge: some View {
        Text(teamDisplayLong)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
    }

    private var eventLine: some View {
        Text(entry.eventName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(family == .systemLarge ? 2 : 1)
            .minimumScaleFactor(0.8)
    }

    private func matchHeadline(compact: Bool) -> some View {
        Text(displayNextMatch)
            .font(.system(size: compact ? 22 : 38, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(compact ? 1 : 2)
            .minimumScaleFactor(0.55)
    }

    private var onFieldLine: some View {
        HStack(spacing: 5) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.caption2)
            Text("\(L10nWidget.onFieldPrefix(isEnglish)) \(displayOnField)")
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white.opacity(0.9))
    }

    private func setupIcon(_ name: String, large: Bool = false) -> some View {
        Image(systemName: name)
            .font(large ? .title2.weight(.semibold) : .body.weight(.semibold))
            .foregroundStyle(.white.opacity(0.95))
    }

    private func largeSetupContent(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
            Text(title)
                .font(.title.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
    }

    private var footerCompact: some View {
        HStack {
            Text("\(L10nWidget.updated(isEnglish)) \(entry.updatedAt)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
    }

    private var footerLarge: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(L10nWidget.updated(isEnglish))
                Text(entry.updatedAt)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.75))
            Spacer()
        }
    }

    // MARK: Copy & data

    private var teamDisplayShort: String {
        guard !entry.teamNumber.isEmpty, entry.teamNumber != "----" else {
            return "FRCLive"
        }
        return "\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)"
    }

    private var teamDisplayLong: String {
        guard !entry.teamNumber.isEmpty, entry.teamNumber != "----" else {
            return "FRCLive"
        }
        let name = entry.teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "\(isEnglish ? "Team" : "Takım") \(entry.teamNumber)"
        }
        return "\(isEnglish ? "Team" : "Takım") \(entry.teamNumber) · \(name)"
    }

    private var displayNextMatch: String {
        let raw = entry.nextMatch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, raw != "-" else {
            return L10nWidget.noMatchShort(isEnglish)
        }
        let lowerEN = raw.lowercased(with: Locale(identifier: "en_US_POSIX"))
        let lowerTR = raw.lowercased(with: Locale(identifier: "tr_TR"))
        if lowerEN.contains("event completed") || lowerTR.contains("etkinlik tamamlandı") {
            return L10nWidget.eventDoneShort(isEnglish)
        }
        if (lowerEN.contains("all matches") && lowerEN.contains("completed")) || lowerTR.contains("tüm maçlar") {
            return L10nWidget.allMatchesDoneShort(isEnglish)
        }
        return raw
    }

    private var displayOnField: String {
        let raw = entry.currentOnField.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty || raw == "-" {
            return "—"
        }
        return raw
    }

    private var queueStatusLine: String {
        switch entry.queueStatusCode.lowercased() {
        case "queuing soon":
            return isEnglish ? "Queuing soon" : "Yakında sıraya alınacak"
        case "now queuing":
            return isEnglish ? "Now queuing" : "Sıraya çağrıldı"
        case "on deck":
            return isEnglish ? "On deck" : "Bekleme alanında"
        case "on field":
            return isEnglish ? "On field" : "Sahada"
        case "waiting_team_selection":
            return isEnglish ? "Waiting for team" : "Takım bekleniyor"
        case "waiting_event_selection":
            return isEnglish ? "Waiting for event" : "Etkinlik bekleniyor"
        case "loading_live_data":
            return isEnglish ? "Loading live data…" : "Canlı veri yükleniyor…"
        default:
            let status = entry.queueStatus.trimmingCharacters(in: .whitespacesAndNewlines)
            return status.isEmpty ? "—" : status
        }
    }

    private func resolveState(_ entry: SimpleEntry) -> WidgetPresentationState {
        switch entry.queueStatusCode.lowercased() {
        case "waiting_team_selection":
            return .needsTeam
        case "waiting_event_selection":
            return .needsEvent
        case "loading_live_data":
            return .loading
        default:
            break
        }

        let team = entry.teamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if team.isEmpty || team == "----" {
            return .needsTeam
        }

        let next = entry.nextMatch.trimmingCharacters(in: .whitespacesAndNewlines)
        if next.isEmpty || next == "-" {
            let lower = entry.queueStatus.lowercased()
            if lower.contains("tamamland") || lower.contains("completed") || lower.contains("no upcoming") {
                return .noUpcomingMatch
            }
            if entry.queueStatusCode.isEmpty && entry.eventName.isEmpty {
                return .needsEvent
            }
            return .noUpcomingMatch
        }

        let lowerNext = next.lowercased()
        if lowerNext.contains("etkinlik tamamlandı") || lowerNext.contains("event completed")
            || lowerNext.contains("tüm maçlar") || lowerNext.contains("all matches") {
            return .noUpcomingMatch
        }

        return .live
    }
}

// MARK: - Widget-local strings (compact for small surfaces)

private enum L10nWidget {
    static func needsTeamTitle(_ en: Bool) -> String {
        en ? "Enter your team number" : "Takım numaranı gir"
    }

    static func needsTeamSubtitle(_ en: Bool) -> String {
        en ? "Open FRCLive to sign in and pick your team." : "Giriş için FRCLive uygulamasını aç."
    }

    static func needsEventTitle(_ en: Bool) -> String {
        en ? "Select an event" : "Etkinlik seç"
    }

    static func needsEventSubtitle(_ en: Bool) -> String {
        en ? "Choose your regional in Settings." : "Ayarlar'dan regionalını seç."
    }

    static func loading(_ en: Bool) -> String {
        en ? "Loading live data…" : "Canlı veri yükleniyor…"
    }

    static func noMatchTitle(_ en: Bool) -> String {
        en ? "No upcoming match" : "Sıradaki maç yok"
    }

    static func noMatchSubtitle(_ en: Bool) -> String {
        en ? "You're caught up for now." : "Şu an için bekleyen maçın yok."
    }

    static func noMatchShort(_ en: Bool) -> String {
        en ? "No match" : "Maç yok"
    }

    static func nextMatchLabel(_ en: Bool) -> String {
        en ? "NEXT MATCH" : "SIRADAKİ MAÇ"
    }

    static func onFieldPrefix(_ en: Bool) -> String {
        en ? "On field:" : "Sahada:"
    }

    static func updated(_ en: Bool) -> String {
        en ? "Updated" : "Güncellendi"
    }

    static func eventDoneShort(_ en: Bool) -> String {
        en ? "Event done" : "Etkinlik bitti"
    }

    static func allMatchesDoneShort(_ en: Bool) -> String {
        en ? "All done" : "Tamamlandı"
    }
}

// MARK: - Widget definition

struct FRCLiveWidgets: Widget {
    let kind: String = "FRCLiveWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FRCLiveWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                FRCLiveWidgetsEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(red: 0 / 255, green: 156 / 255, blue: 215 / 255)
                    }
            } else {
                FRCLiveWidgetsEntryView(entry: entry)
                    .padding()
                    .background(Color(red: 0 / 255, green: 156 / 255, blue: 215 / 255))
            }
        }
        .configurationDisplayName("FRCLive")
        .description("Takım maç sırası ve kuyruk durumunu gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemLarge) {
    FRCLiveWidgets()
} timeline: {
    SimpleEntry.previewNeedsTeam
}

#Preview(as: .systemMedium) {
    FRCLiveWidgets()
} timeline: {
    SimpleEntry.preview
}

#Preview(as: .systemSmall) {
    FRCLiveWidgets()
} timeline: {
    SimpleEntry.previewNeedsTeam
}
