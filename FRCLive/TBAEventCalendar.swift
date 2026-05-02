import Foundation

/// TBA tarihleri `yyyy-MM-dd` string olarak gelir. Bunları UTC gece yarısı `Date` ile parse edip
/// yerel `startOfDay` ile kıyaslamak, son gün ve saat dilimi kaynaklı “tamamlandı” tutarsızlıklarına yol açar.
enum TBAEventCalendar {
    /// Verilen günü kullanıcının yerel takviminde o günün başlangıcına sabitler (öğlen anchor ile DST güvenli).
    static func startOfLocalCalendarDay(fromYyyyMmDd string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var dc = DateComponents()
        dc.calendar = Calendar.current
        dc.timeZone = TimeZone.current
        dc.year = parts[0]
        dc.month = parts[1]
        dc.day = parts[2]
        dc.hour = 12
        dc.minute = 0
        dc.second = 0
        guard let anchor = Calendar.current.date(from: dc) else { return nil }
        return Calendar.current.startOfDay(for: anchor)
    }

    /// Bugünün yerel takvim günü, bitiş gününden **sonra** ise etkinlik tarihsel olarak bitmiştır.
    /// (Bitiş gününün kendisi hâlâ “devam ediyor” kabul edilir.)
    static func isPastEndLocalCalendarDay(endYyyyMmDd: String, now: Date = Date()) -> Bool {
        guard let endDayStart = startOfLocalCalendarDay(fromYyyyMmDd: endYyyyMmDd) else { return false }
        let todayStart = Calendar.current.startOfDay(for: now)
        return Calendar.current.compare(todayStart, to: endDayStart, toGranularity: .day) == .orderedDescending
    }
}
