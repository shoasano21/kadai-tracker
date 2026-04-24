import WidgetKit
import SwiftUI

// MARK: - Shared data types

struct KTTask: Codable, Identifiable, Hashable {
    let id: Int
    let course: String
    let title: String
    let type: String
    let start: String // yyyy-MM-dd
    let end: String   // yyyy-MM-dd
    let done: Bool
}

struct KTSnapshot: Codable {
    let items: [KTTask]
    let updatedAt: Double
}

private let APP_GROUP = "group.com.shoasano21.kadaitracker"
private let SNAPSHOT_KEY = "kadai_tracker_widget_snapshot"

enum KTStore {
    static func load() -> KTSnapshot? {
        guard let defaults = UserDefaults(suiteName: APP_GROUP),
              let data = defaults.data(forKey: SNAPSHOT_KEY) else { return nil }
        return try? JSONDecoder().decode(KTSnapshot.self, from: data)
    }
}

// MARK: - Timeline provider

struct KadaiEntry: TimelineEntry {
    let date: Date
    let snapshot: KTSnapshot
}

struct KadaiProvider: TimelineProvider {
    static let sampleSnapshot = KTSnapshot(
        items: [
            KTTask(id: 1, course: "数学１", title: "演習問題", type: "problem",
                   start: dateString(daysFromNow: -2), end: dateString(daysFromNow: 1), done: false),
            KTTask(id: 2, course: "化学１", title: "レポート", type: "report",
                   start: dateString(daysFromNow: -3), end: dateString(daysFromNow: 3), done: false),
            KTTask(id: 3, course: "医学概論", title: "読書", type: "reading",
                   start: dateString(daysFromNow: -1), end: dateString(daysFromNow: 6), done: false)
        ],
        updatedAt: Date().timeIntervalSince1970
    )

    func placeholder(in context: Context) -> KadaiEntry {
        KadaiEntry(date: Date(), snapshot: Self.sampleSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (KadaiEntry) -> Void) {
        let snap = KTStore.load() ?? Self.sampleSnapshot
        completion(KadaiEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KadaiEntry>) -> Void) {
        let snap = KTStore.load() ?? KTSnapshot(items: [], updatedAt: Date().timeIntervalSince1970)
        let entry = KadaiEntry(date: Date(), snapshot: snap)
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

private var gregorianCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone.current
    return cal
}()

private var isoDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = Calendar(identifier: .gregorian)
    f.timeZone = TimeZone.current
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private func dateString(daysFromNow: Int) -> String {
    let d = gregorianCalendar.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    return isoDateFormatter.string(from: d)
}

// MARK: - Helpers

private func daysLeft(_ endStr: String) -> Int {
    guard let end = isoDateFormatter.date(from: endStr) else { return 0 }
    let today = gregorianCalendar.startOfDay(for: Date())
    let endDay = gregorianCalendar.startOfDay(for: end)
    return gregorianCalendar.dateComponents([.day], from: today, to: endDay).day ?? 0
}

private func statusColor(daysLeft d: Int, done: Bool) -> Color {
    if done { return Color.gray.opacity(0.6) }
    if d < 0 { return Color(red: 0.9, green: 0.22, blue: 0.22) }
    if d <= 3 { return Color(red: 0.9, green: 0.22, blue: 0.22) }
    if d <= 7 { return Color(red: 0.92, green: 0.66, blue: 0.24) }
    return Color(red: 0.26, green: 0.63, blue: 0.28)
}

private func typeEmoji(_ type: String) -> String {
    switch type {
    case "report": return "📝"
    case "problem": return "✏️"
    case "memory": return "📖"
    case "reading": return "📚"
    case "lab": return "🔬"
    case "presentation": return "🎤"
    case "quiz": return "✅"
    case "exam": return "📊"
    case "group": return "👥"
    default: return "📎"
    }
}

// MARK: - Widget Views

struct KadaiWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KadaiEntry

    var visibleTasks: [KTTask] {
        let open = entry.snapshot.items.filter { !$0.done }
        return open.sorted { $0.end < $1.end }
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        case .systemLarge: largeView
        default: mediumView
        }
    }

    private var smallView: some View {
        let next = visibleTasks.first
        return VStack(alignment: .leading, spacing: 6) {
            Text("課題トラッカー")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            if let t = next {
                let d = daysLeft(t.end)
                Text(t.course)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Text("\(typeEmoji(t.type)) \(typeLabel(t.type))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Circle().fill(statusColor(daysLeft: d, done: false)).frame(width: 8, height: 8)
                    Text(d < 0 ? "\(abs(d))日超過" : d == 0 ? "今日締切" : "残り\(d)日")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(statusColor(daysLeft: d, done: false))
                }
                Text(t.end)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                Text("課題なし")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumView: some View {
        let list = Array(visibleTasks.prefix(3))
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("課題トラッカー")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(visibleTasks.count)件")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            if list.isEmpty {
                Spacer()
                Text("締切間近の課題はありません")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(list) { t in
                    taskRow(t)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeView: some View {
        let list = Array(visibleTasks.prefix(6))
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("課題トラッカー")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(visibleTasks.count)件")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            if list.isEmpty {
                Spacer()
                Text("締切間近の課題はありません")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(list) { t in
                    taskRow(t)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func taskRow(_ t: KTTask) -> some View {
        let d = daysLeft(t.end)
        return HStack(spacing: 8) {
            Rectangle()
                .fill(statusColor(daysLeft: d, done: t.done))
                .frame(width: 3)
                .cornerRadius(2)
            VStack(alignment: .leading, spacing: 1) {
                Text(t.course)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                Text("\(typeEmoji(t.type)) \(typeLabel(t.type))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(d < 0 ? "⚠️ \(abs(d))日超過" : d == 0 ? "🔥 今日" : "残り\(d)日")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor(daysLeft: d, done: t.done))
        }
        .padding(.vertical, 2)
    }

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "report": return "レポート"
        case "problem": return "問題演習"
        case "memory": return "暗記"
        case "reading": return "予習・読書"
        case "lab": return "実習・実験"
        case "presentation": return "発表・プレゼン"
        case "quiz": return "小テスト"
        case "exam": return "試験対策"
        case "group": return "グループワーク"
        default: return "その他"
        }
    }
}

// MARK: - Widget declaration

@main
struct KadaiTrackerWidget: Widget {
    let kind: String = "KadaiTrackerWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KadaiProvider()) { entry in
            if #available(iOS 17.0, *) {
                KadaiWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                KadaiWidgetEntryView(entry: entry)
                    .padding(0)
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("課題トラッカー")
        .description("締切が近い課題をホーム画面に表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
