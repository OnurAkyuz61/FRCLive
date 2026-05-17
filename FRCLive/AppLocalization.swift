import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case tr
    case en

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum L10nKey {
    case teamNumberTitle
    case teamNumberPlaceholder
    case continueButton
    case tbaApiKey
    case enterTbaKey
    case confirm
    case remove
    case tbaKeyConfirmed
    case mustConfirmTba
    case nexusApiKey
    case enterNexusKey
    case nexusKeyConfirmed
    case mustConfirmNexus
    case teamValidationFailed
    case poweredBy
    case appVersionFormat
    case eventSelection
    case teamSelection
    case loadingEvents
    case retry
    case invalidTeamOrEvents
    case noEventsForYear
    case teamPrefix
    case dashboard
    case schedule
    case settings
    case nextMatch
    case nextMatchPlaceholder
    case liveActivityReady
    case eventNotSelected
    case liveActivitiesToggle
    case notificationsToggle
    case notificationsBackgroundNote
    case notificationBackgroundTipTitle
    case notificationBackgroundTipMessage
    case testNotification
    case logout
    case language
    case notificationPermissionGranted
    case notificationPermissionDenied
    case testNotificationSent
    case testNotificationFailed
    case allMatchesCompleted
    case noUpcomingMatch
    case currentlyOnField
    case queueStatusNotCalled
    case queueStatusCalled
    case queueStatusOnField
    case queueStatusUnknown
    case nexusStatusQueuingSoon
    case nexusStatusNowQueuing
    case nexusStatusOnDeck
    case nexusStatusOnField
    case estimatedStart
    case liveDataError
    case loadingMatches
    case noMatchesForTeam
    case matchScheduleNotCreated
    case matchLabel
    case redAlliance
    case blueAlliance
    case alertWarningTitle
    case alertOk
    case tbaKeyInvalid
    case dataSource
    case dataSourceLive
    case dataSourceDemo
    case dataSourceOffline
    case rankings
    case noRankings
    case rank
    case teamName
    case wins
    case losses
    case ties
    case practice
    case qualification
    case playoff
    case alliances
    case allianceNameFormat
    case noAlliances
    case allianceWinner
    case allianceCaptain
    case playoffStarted
    case playoffNotStarted
    case eventPhase
    case eventPhasePractice
    case eventPhaseQualification
    case eventPhasePlayoff
    case eventPhaseUnknown
    case theme
    case themeSystem
    case themeLight
    case themeDark
    case eventCompletedBanner
    case awards
    case noAwards
    case wltHeader
    case noTeamAwards
    case showAllAwardWinners
    case showOnlyTeamAwards
    case announcements
    case loadingAnnouncements
    case noAnnouncements
    case announcementsLoadError
    case announcementFromEvent
    case announcementDetailTitle
    case announcementNotificationTitle
    case announcementReplayCategory
    case announcementReplayDetailTitle
    case announcementReplayNotificationTitle
    case announcementAllianceCategory
    case announcementAllianceDetailTitle
    case announcementAllianceNotificationTitle
    case allianceSelectionAfterMatch
    case allianceSelectionMessage
    case markAllRead
    case partsRequestCategory
    case partsRequestCategoryWithTeam
    case partsRequestCategoryWithTeamAndPit
    case partsRequestDetailTitle
    case partsRequestNotificationTitle
}

enum L10n {
    /// Bildirim başlığı: `FRCLive • [tür]`
    static func notificationHeader(type: String) -> String {
        "FRCLive • \(type)"
    }

    static func notificationHeader(_ key: L10nKey, language: AppLanguage) -> String {
        notificationHeader(type: text(key, language: language))
    }

    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        switch language {
        case .tr:
            switch key {
            case .teamNumberTitle: return "FRC Takım Numaranız"
            case .teamNumberPlaceholder: return "örn. 6232"
            case .continueButton: return "Devam Et"
            case .tbaApiKey: return "TBA API Key"
            case .enterTbaKey: return "TBA key girin"
            case .confirm: return "Onayla"
            case .remove: return "Kaldır"
            case .tbaKeyConfirmed: return "TBA Key Onaylandı"
            case .mustConfirmTba: return "Devam etmek için önce TBA API Key onaylanmalı."
            case .nexusApiKey: return "Nexus API Key"
            case .enterNexusKey: return "Nexus key girin"
            case .nexusKeyConfirmed: return "Nexus Key Onaylandı"
            case .mustConfirmNexus: return "Devam etmek için önce Nexus API Key onaylanmalı."
            case .teamValidationFailed: return "Takım doğrulanamadı. Lütfen bilgileri kontrol edin."
            case .poweredBy: return "Powered by Onur Akyüz"
            case .appVersionFormat: return "FRCLive Versiyon %@"
            case .eventSelection: return "Etkinlik Seçimi"
            case .teamSelection: return "Takım Seçimi"
            case .loadingEvents: return "Etkinlikler yükleniyor..."
            case .retry: return "Tekrar Dene"
            case .invalidTeamOrEvents: return "Etkinlikler yüklenemedi veya geçersiz takım."
            case .noEventsForYear: return "Bu takım için 2026 etkinliği bulunamadı."
            case .teamPrefix: return "Takım"
            case .dashboard: return "Ana Sayfa"
            case .schedule: return "Takvim"
            case .settings: return "Ayarlar"
            case .nextMatch: return "Sıradaki Maç"
            case .nextMatchPlaceholder: return "Veri yakında Nexus ile güncellenecek"
            case .liveActivityReady: return "Live Activity: Hazır"
            case .eventNotSelected: return "Etkinlik seçilmedi"
            case .liveActivitiesToggle: return "Canlı Etkinlikleri (Live Activities) Aç"
            case .notificationsToggle: return "Bildirimleri İzin Ver"
            case .notificationsBackgroundNote: return "Uygulama kapalıyken Nexus tahmin saatlerine göre bildirim planlanır. Sıra aniden değişirse uygulamayı bir kez açmak veya interneti açmak güncellemeyi hızlandırır."
            case .notificationBackgroundTipTitle: return "⚠️ Dikkat"
            case .notificationBackgroundTipMessage: return "Sıra ve duyuru bildirimlerinin zamanında gelmesi için FRCLive'ı etkinlik boyunca arka planda açık tutmanızı öneririz. Uygulamayı kaydırıp bırakabilirsiniz; üstten tamamen kapatırsanız uyarılar gecikebilir veya kaçırılabilir."
            case .testNotification: return "Bildirimi Test Et"
            case .logout: return "Çıkış Yap"
            case .language: return "Dil"
            case .notificationPermissionGranted: return "Bildirim izni verildi."
            case .notificationPermissionDenied: return "Bildirim izni verilmedi."
            case .testNotificationSent: return "2 saniye içinde test bildirimi gönderilecek."
            case .testNotificationFailed: return "Bildirim gönderilemedi:"
            case .allMatchesCompleted: return "Tüm maçlar tamamlandı"
            case .noUpcomingMatch: return "Sıradaki maç bulunamadı"
            case .currentlyOnField: return "Şu an sahada:"
            case .queueStatusNotCalled: return "Henüz çağrılmadı"
            case .queueStatusCalled: return "Kuyruğa çağrıldı"
            case .queueStatusOnField: return "Sahada"
            case .queueStatusUnknown: return "Durum bilinmiyor"
            case .nexusStatusQueuingSoon: return "Yakında sıraya alınacak"
            case .nexusStatusNowQueuing: return "Sıraya çağrıldı"
            case .nexusStatusOnDeck: return "Bekleme alanında"
            case .nexusStatusOnField: return "Sahada"
            case .estimatedStart: return "Tahmini Başlangıç"
            case .liveDataError: return "Canlı veri alınamadı."
            case .loadingMatches: return "Maçlar yükleniyor..."
            case .noMatchesForTeam: return "Bu etkinlikte takım için maç bulunamadı."
            case .matchScheduleNotCreated: return "Maç Takvimi Daha Oluşturulmadı"
            case .matchLabel: return "Maç"
            case .redAlliance: return "Kırmızı"
            case .blueAlliance: return "Mavi"
            case .alertWarningTitle: return "Uyarı"
            case .alertOk: return "Tamam"
            case .tbaKeyInvalid: return "TBA API anahtarı geçersiz."
            case .dataSource: return "Veri Kaynağı"
            case .dataSourceLive: return "CANLI • Nexus"
            case .dataSourceDemo: return "DEMO • Takım 99999"
            case .dataSourceOffline: return "ÇEVRİMDIŞI • Yedek"
            case .rankings: return "Sıralama"
            case .noRankings: return "Sıralama verisi henüz yayınlanmadı."
            case .rank: return "Sıra"
            case .teamName: return "Takım Adı"
            case .wins: return "G"
            case .losses: return "M"
            case .ties: return "B"
            case .practice: return "Pratik"
            case .qualification: return "Sıralama"
            case .playoff: return "Playoff"
            case .alliances: return "İttifak"
            case .allianceNameFormat: return "İttifak %d"
            case .noAlliances: return "İttifak listesi henüz yayınlanmadı."
            case .allianceWinner: return "Kazanan"
            case .allianceCaptain: return "Kaptan"
            case .playoffStarted: return "Playoff: Başladı"
            case .playoffNotStarted: return "Playoff: Henüz başlamadı"
            case .eventPhase: return "Etkinlik Aşaması"
            case .eventPhasePractice: return "Pratik"
            case .eventPhaseQualification: return "Sıralama"
            case .eventPhasePlayoff: return "Playoff"
            case .eventPhaseUnknown: return "Bilinmiyor"
            case .theme: return "Tema"
            case .themeSystem: return "Sistem"
            case .themeLight: return "Açık"
            case .themeDark: return "Koyu"
            case .eventCompletedBanner: return "Etkinlik Tamamlandı"
            case .awards: return "Ödüller"
            case .noAwards: return "Bu etkinlik için ödül verisi bulunamadı."
            case .wltHeader: return "W / L / T"
            case .noTeamAwards: return "Takımınıza ait ödül bulunamadı."
            case .showAllAwardWinners: return "Tüm ödül alanları göster"
            case .showOnlyTeamAwards: return "Takıma dön"
            case .announcements: return "Duyurular"
            case .loadingAnnouncements: return "Duyurular yükleniyor..."
            case .noAnnouncements: return "Şu an yayında duyuru veya parça talebi yok."
            case .announcementsLoadError: return "Duyurular yüklenemedi."
            case .announcementFromEvent: return "Etkinlik Duyurusu"
            case .announcementDetailTitle: return "Duyuru"
            case .announcementNotificationTitle: return "Etkinlik Duyurusu"
            case .announcementReplayCategory: return "Maç tekrarı"
            case .announcementReplayDetailTitle: return "Maç Tekrarı"
            case .announcementReplayNotificationTitle: return "Maç Tekrarı"
            case .announcementAllianceCategory: return "İttifak seçimi"
            case .announcementAllianceDetailTitle: return "İttifak Seçimi"
            case .announcementAllianceNotificationTitle: return "İttifak Seçimi"
            case .allianceSelectionAfterMatch: return "%@ sonrasında"
            case .allianceSelectionMessage: return "İttifak seçimi %@ skorları yayınlandıktan 8 dakika sonra başlayacaktır.\n\nTakım temsilcilerinizi %@ öncesinde sahaya gönderin."
            case .markAllRead: return "Tümünü okundu say"
            case .partsRequestCategory: return "Parça talebi"
            case .partsRequestCategoryWithTeam: return "Parça talebi | Takım %@"
            case .partsRequestCategoryWithTeamAndPit: return "Parça talebi | Takım %@ [%@]"
            case .partsRequestDetailTitle: return "Parça Talebi"
            case .partsRequestNotificationTitle: return "Parça Talebi"
            }
        case .en:
            switch key {
            case .teamNumberTitle: return "Your FRC Team Number"
            case .teamNumberPlaceholder: return "e.g., 6232"
            case .continueButton: return "Continue"
            case .tbaApiKey: return "TBA API Key"
            case .enterTbaKey: return "Enter TBA key"
            case .confirm: return "Confirm"
            case .remove: return "Remove"
            case .tbaKeyConfirmed: return "TBA Key Confirmed"
            case .mustConfirmTba: return "Please confirm TBA API Key before continuing."
            case .nexusApiKey: return "Nexus API Key"
            case .enterNexusKey: return "Enter Nexus key"
            case .nexusKeyConfirmed: return "Nexus Key Confirmed"
            case .mustConfirmNexus: return "Please confirm Nexus API Key before continuing."
            case .teamValidationFailed: return "Team validation failed. Please check your details."
            case .poweredBy: return "Powered by Onur Akyüz"
            case .appVersionFormat: return "FRCLive Version %@"
            case .eventSelection: return "Event Selection"
            case .teamSelection: return "Team Selection"
            case .loadingEvents: return "Loading events..."
            case .retry: return "Retry"
            case .invalidTeamOrEvents: return "Could not load events or invalid team."
            case .noEventsForYear: return "No 2026 events were found for this team."
            case .teamPrefix: return "Team"
            case .dashboard: return "Dashboard"
            case .schedule: return "Schedule"
            case .settings: return "Settings"
            case .nextMatch: return "Next Match"
            case .nextMatchPlaceholder: return "Data will be updated from Nexus soon"
            case .liveActivityReady: return "Live Activity: Ready"
            case .eventNotSelected: return "No event selected"
            case .liveActivitiesToggle: return "Enable Live Activities"
            case .notificationsToggle: return "Allow Notifications"
            case .notificationsBackgroundNote: return "When the app is closed, alerts are scheduled from Nexus time estimates. Open the app once or reconnect to refresh if the queue changes suddenly."
            case .notificationBackgroundTipTitle: return "⚠️ Attention"
            case .notificationBackgroundTipMessage: return "For queue and announcement alerts to arrive on time, keep FRCLive open in the background during the event. You can switch to other apps—just avoid force-quitting FRCLive from the app switcher, or alerts may be delayed or missed."
            case .testNotification: return "Send Test Notification"
            case .logout: return "Log Out"
            case .language: return "Language"
            case .notificationPermissionGranted: return "Notification permission granted."
            case .notificationPermissionDenied: return "Notification permission denied."
            case .testNotificationSent: return "Test notification will arrive in 2 seconds."
            case .testNotificationFailed: return "Could not send notification:"
            case .allMatchesCompleted: return "All matches are completed"
            case .noUpcomingMatch: return "No upcoming match found"
            case .currentlyOnField: return "Currently on field:"
            case .queueStatusNotCalled: return "Not Called"
            case .queueStatusCalled: return "Called to Queue"
            case .queueStatusOnField: return "On Field"
            case .queueStatusUnknown: return "Unknown Status"
            case .nexusStatusQueuingSoon: return "Queuing soon"
            case .nexusStatusNowQueuing: return "Now queuing"
            case .nexusStatusOnDeck: return "On deck"
            case .nexusStatusOnField: return "On field"
            case .estimatedStart: return "Estimated Start"
            case .liveDataError: return "Could not fetch live data."
            case .loadingMatches: return "Loading matches..."
            case .noMatchesForTeam: return "No matches found for this team in this event."
            case .matchScheduleNotCreated: return "Match schedule has not been published yet"
            case .matchLabel: return "Match"
            case .redAlliance: return "Red"
            case .blueAlliance: return "Blue"
            case .alertWarningTitle: return "Warning"
            case .alertOk: return "OK"
            case .tbaKeyInvalid: return "TBA API key is invalid."
            case .dataSource: return "Data Source"
            case .dataSourceLive: return "LIVE • Nexus"
            case .dataSourceDemo: return "DEMO • Team 99999"
            case .dataSourceOffline: return "OFFLINE • Fallback"
            case .rankings: return "Rankings"
            case .noRankings: return "Rankings are not published yet."
            case .rank: return "Rank"
            case .teamName: return "Team Name"
            case .wins: return "W"
            case .losses: return "L"
            case .ties: return "T"
            case .practice: return "Practice"
            case .qualification: return "Qualification"
            case .playoff: return "Playoff"
            case .alliances: return "Alliance"
            case .allianceNameFormat: return "Alliance %d"
            case .noAlliances: return "Alliance list is not published yet."
            case .allianceWinner: return "Winner"
            case .allianceCaptain: return "Captain"
            case .playoffStarted: return "Playoff: Started"
            case .playoffNotStarted: return "Playoff: Not started yet"
            case .eventPhase: return "Event Phase"
            case .eventPhasePractice: return "Practice"
            case .eventPhaseQualification: return "Qualification"
            case .eventPhasePlayoff: return "Playoff"
            case .eventPhaseUnknown: return "Unknown"
            case .theme: return "Theme"
            case .themeSystem: return "System"
            case .themeLight: return "Light"
            case .themeDark: return "Dark"
            case .eventCompletedBanner: return "Event Completed"
            case .awards: return "Awards"
            case .noAwards: return "No awards data found for this event."
            case .wltHeader: return "W / L / T"
            case .noTeamAwards: return "No awards found for your team."
            case .showAllAwardWinners: return "Show all award winners"
            case .showOnlyTeamAwards: return "Back to team"
            case .announcements: return "Announcements"
            case .loadingAnnouncements: return "Loading announcements..."
            case .noAnnouncements: return "There are no active announcements or parts requests."
            case .announcementsLoadError: return "Could not load announcements."
            case .announcementFromEvent: return "Event Announcement"
            case .announcementDetailTitle: return "Announcement"
            case .announcementNotificationTitle: return "Event Announcement"
            case .announcementReplayCategory: return "Match replay"
            case .announcementReplayDetailTitle: return "Match Replay"
            case .announcementReplayNotificationTitle: return "Match Replay"
            case .announcementAllianceCategory: return "Alliance selection"
            case .announcementAllianceDetailTitle: return "Alliance Selection"
            case .announcementAllianceNotificationTitle: return "Alliance Selection"
            case .allianceSelectionAfterMatch: return "After %@"
            case .allianceSelectionMessage: return "Alliance selection will begin 8 minutes after %@ scores are posted.\n\nSend your team representatives to the field before %@."
            case .markAllRead: return "Mark all read"
            case .partsRequestCategory: return "Parts request"
            case .partsRequestCategoryWithTeam: return "Parts request | Team %@"
            case .partsRequestCategoryWithTeamAndPit: return "Parts request | Team %@ [%@]"
            case .partsRequestDetailTitle: return "Parts Request"
            case .partsRequestNotificationTitle: return "Parts Request"
            }
        }
    }
}
