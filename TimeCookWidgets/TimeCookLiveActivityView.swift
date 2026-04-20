import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Widget entry point

@available(iOS 16.1, *)
struct TimeCookLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeCookAttributes.self) { context in
            LockScreenActivityView(context: context)
                .activityBackgroundTint(Color.tcBackground)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(endTime: context.state.targetEndTime)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                CompactLeadingView()
            } compactTrailing: {
                CompactTrailingView(endTime: context.state.targetEndTime)
            } minimal: {
                MinimalView()
            }
            .widgetURL(URL(string: "timecook://session"))
            .keylineTint(.orange)
        }
    }
}

// MARK: - Lock Screen / Notification Banner

struct LockScreenActivityView: View {
    let context: ActivityViewContext<TimeCookAttributes>
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        if isLuminanceReduced {
            alwaysOnView
        } else {
            fullView
        }
    }

    // Always-On / StandBy: essential info only, no animations, no secondary content
    private var alwaysOnView: some View {
        HStack {
            Label("TimeCook", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Spacer()
            TimerCountdownView(date: context.state.targetEndTime)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .accessibilityLabel("TimeCook — cuisson en cours")
    }

    private var fullView: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            SessionProgressBar(
                completed: context.state.completedDishes,
                total: context.attributes.totalDishes
            )
            subtitleRow
            if let name = context.state.nextDishName,
               let time = context.state.nextDishStartTime {
                // Inset container per HIG — don't use a thin Divider + flush content
                nextDishRow(name: name, time: time)
            }
        }
        .padding(16)
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("TimeCook", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Spacer()
            TimerCountdownView(date: context.state.targetEndTime)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .accessibilityLabel("Temps restant")
        }
    }

    private var subtitleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(context.attributes.sessionTitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            Spacer()
            Group {
                Text("Prêt à ") +
                Text(context.state.targetEndTime, style: .time).bold()
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
    }

    // Wrapped in a rounded inset container — HIG: separate blocks with inset shape or thick line
    @ViewBuilder
    private func nextDishRow(name: String, time: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("Lancez **\(name)** dans")
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)
            TimerCountdownView(date: time)
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lancez \(name) bientôt")
    }
}

// MARK: - Dynamic Island: Compact
// No manual padding — system positions content snug against the TrueDepth camera (HIG)

struct CompactLeadingView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.orange)
            .accessibilityHidden(true)
    }
}

struct CompactTrailingView: View {
    let endTime: Date

    var body: some View {
        // Single concise value — HIG: compact trailing must never wrap or show multiple lines
        TimerCountdownView(date: endTime)
            .font(.caption.weight(.bold))
            .foregroundStyle(.orange)
            .accessibilityLabel("Fin de cuisson")
    }
}

// MARK: - Dynamic Island: Minimal

struct MinimalView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 12))
            .foregroundStyle(.orange)
            .accessibilityLabel("TimeCook actif")
    }
}

// MARK: - Dynamic Island: Expanded
// No manual padding on leading/trailing — system applies concentric margins (HIG image 2 & 4)
// Coherent enlargement of compact: 🔥 left / countdown right mirrors compact layout (HIG image 1)

struct ExpandedLeadingView: View {
    var body: some View {
        Label("TimeCook", systemImage: "flame.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("TimeCook")
    }
}

struct ExpandedTrailingView: View {
    let endTime: Date

    var body: some View {
        TimerCountdownView(date: endTime)
            .font(.headline.weight(.bold))
            .foregroundStyle(.orange)
            .accessibilityLabel("Temps restant")
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<TimeCookAttributes>

    var body: some View {
        // System manages bottom region outer margins — no manual horizontal padding on VStack
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                SessionProgressBar(
                    completed: context.state.completedDishes,
                    total: context.attributes.totalDishes
                )
                Text("\(context.state.completedDishes)/\(context.attributes.totalDishes)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(context.attributes.sessionTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let name = context.state.nextDishName,
               let time = context.state.nextDishStartTime {
                // Inset capsule container — HIG image 3: when separating blocks in expanded,
                // use an inset shape (not flush-to-edge content)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Lancez \(name) dans")
                        .font(.caption2)
                        .lineLimit(1)
                    TimerCountdownView(date: time)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15), in: Capsule())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lancez \(name) bientôt")
            }
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Reusable components

struct TimerCountdownView: View {
    let date: Date

    var body: some View {
        Text(date, style: .timer)
            .monospacedDigit()
    }
}

struct SessionProgressBar: View {
    let completed: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1.0, Double(completed) / Double(total))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.2)).frame(height: 4)
                Capsule()
                    .fill(Color.orange)
                    .frame(width: geo.size.width * fraction, height: 4)
                    .animation(.easeInOut(duration: 0.4), value: fraction)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("\(completed) sur \(total) plats en cuisson")
    }
}

// MARK: - Color

private extension Color {
    static let tcBackground = Color(red: 0.10, green: 0.07, blue: 0.04)
}
