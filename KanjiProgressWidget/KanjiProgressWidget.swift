import WidgetKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ProgressEntry: TimelineEntry {
    let date: Date
    let progress: WidgetProgress?
}

struct ProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: .now, progress: .example)
    }
    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(ProgressEntry(date: .now, progress: context.isPreview ? .example : .read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let entry = ProgressEntry(date: .now, progress: .read())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct ProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProgressEntry
    private let green = Color(red: 0.22, green: 0.39, blue: 0.33)
    private let gold = Color(red: 0.50, green: 0.34, blue: 0.10)
    private let blue = Color(red: 0.16, green: 0.36, blue: 0.55)
    private var small: Bool { family == .systemSmall }

    var body: some View {
        VStack(alignment: .leading, spacing: small ? 6 : 8) {
            HStack(spacing: 6) {
                if !small {
                    Text(entry.progress == nil ? "アプリを開いてはじめよう" : "ひとつずつ、できたを増やそう。")
                        .font(.system(size: 12)).foregroundStyle(green.opacity(0.85))
                        .lineLimit(1).minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
                artwork("CompanionSeaLion").resizable().scaledToFit()
                    .frame(width: small ? 36 : 60, height: small ? 22 : 32)
                    .accessibilityHidden(true)
            }
            if small {
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        count("すべて", entry.progress?.total, tint: green, total: true)
                        count("がんばるぞ", entry.progress?.starting, tint: gold)
                    }
                    GridRow {
                        count("あとすこし", entry.progress?.learning, tint: blue)
                        count("かんぺき", entry.progress?.mastered, tint: green)
                    }
                }
            } else {
                HStack(spacing: 7) {
                    count("すべて", entry.progress?.total, tint: green, total: true)
                    count("がんばるぞ", entry.progress?.starting, tint: gold)
                    count("あとすこし", entry.progress?.learning, tint: blue)
                    count("かんぺき", entry.progress?.mastered, tint: green)
                }
                HStack(spacing: 5) {
                    artwork("CompanionStarfish").resizable().scaledToFit().frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                    Text(entry.progress == nil ? "アプリを開くと件数が表示されます" : "今日もちょっと、漢字時間。")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1).minimumScaleFactor(0.85)
                }.foregroundStyle(green)
            }
        }
        .foregroundStyle(green)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.918, green: 0.953, blue: 0.910), Color(red: 0.99, green: 0.985, blue: 0.955)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // WidgetKit archives the actual image pixels, even when the view is small.
    // Keep the existing artwork, but supply a thumbnail within the widget's image budget.
    private func artwork(_ name: String) -> Image {
        #if canImport(UIKit)
        if let thumbnail = UIImage(named: name)?.preparingThumbnail(of: CGSize(width: 180, height: 180)) {
            return Image(uiImage: thumbnail)
        }
        #endif
        return Image(name)
    }

    private func count(_ title: String, _ value: Int?, tint: Color, total: Bool = false) -> some View {
        VStack(spacing: small ? 2 : 5) {
            Text(title).font(.system(size: small ? 11 : 12, weight: .semibold, design: .rounded))
            Text(value.map { $0.formatted(.number.locale(Locale(identifier: "ja_JP"))) } ?? "—")
                .font(.system(size: small ? 22 : 25, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .lineLimit(1).minimumScaleFactor(0.65)
        .padding(.horizontal, small ? 4 : 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, small ? 6 : 10)
        .foregroundStyle(total ? .white : tint)
        .background(total ? green : tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)、\(value.map { "\($0)件" } ?? "アプリを開いて確認")")
    }

}

struct KanjiProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetProgress.kind, provider: ProgressProvider()) { entry in
            ProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("漢字の件数")
        .description("すべて・がんばるぞ・あとすこし・かんぺきの件数を、動物たちと確認。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("小", as: .systemSmall) {
    KanjiProgressWidget()
} timeline: {
    ProgressEntry(date: .now, progress: .example)
    ProgressEntry(date: .now, progress: .empty)
    ProgressEntry(date: .now, progress: nil)
}

#Preview("中", as: .systemMedium) {
    KanjiProgressWidget()
} timeline: {
    ProgressEntry(date: .now, progress: .example)
}
