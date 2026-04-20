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

    private var now: Date { Date() }

    /// Earliest-started dish currently cooking — has the most elapsed progress.
    private var currentDish: TimeCookAttributes.ContentState.DishStatus? {
        context.state.dishes
            .filter { $0.startTime <= now && now < $0.endTime }
            .min(by: { $0.startTime < $1.startTime })
    }

    var body: some View {
        if isLuminanceReduced {
            alwaysOnView
        } else {
            fullView
        }
    }

    // Always-On / StandBy: essential info only
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
            topBar
            HStack(alignment: .center, spacing: 14) {
                currentDishPanel
                Color.white.opacity(0.15)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                dishTimelinePanel
            }
        }
        .padding(16)
    }

    // "● EN COURS" badge  |  countdown timer
    private var topBar: some View {
        HStack {
            HStack(spacing: 5) {
                Circle().fill(.orange).frame(width: 7, height: 7)
                Text("EN COURS")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .tracking(0.5)
                Image(systemName: "rays")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange.opacity(0.18), in: Capsule())

            Spacer()

            TimerCountdownView(date: context.state.targetEndTime)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .accessibilityLabel("Temps restant")
        }
    }

    // Left column: current dish name + orange progress bar
    @ViewBuilder
    private var currentDishPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let dish = currentDish {
                Text(dish.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                DishProgressBar(dish: dish)
            } else {
                Text("Prêt !")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Right column: vertical timeline of all dishes
    private var dishTimelinePanel: some View {
        let dishes = context.state.dishes
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(dishes.enumerated()), id: \.element.id) { idx, dish in
                DishTimelineRow(name: dish.name, status: renderStatus(of: dish))
                if idx < dishes.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1.5, height: 5)
                        .padding(.leading, 6.5)
                }
            }
        }
        .frame(width: 130, alignment: .leading)
    }

    private func renderStatus(of dish: TimeCookAttributes.ContentState.DishStatus) -> DishRenderStatus {
        if now >= dish.endTime { return .done }
        if now >= dish.startTime { return .cooking }
        return .waiting
    }
}

// MARK: - Progress bar for current dish
// Uses ProgressView(timerInterval:) — the only API that self-animates inside Live Activities.

struct DishProgressBar: View {
    let dish: TimeCookAttributes.ContentState.DishStatus

    var body: some View {
        ProgressView(timerInterval: dish.startTime...dish.endTime, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(.orange)
    }
}

// MARK: - Timeline row status

enum DishRenderStatus: Equatable {
    case done, cooking, waiting

    var iconName: String {
        switch self {
        case .done:    "checkmark.circle.fill"
        case .cooking: "hourglass.fill"
        case .waiting: "timer"
        }
    }

    var color: Color {
        switch self {
        case .done:    .green
        case .cooking: .orange
        case .waiting: Color.white.opacity(0.45)
        }
    }
}

struct DishTimelineRow: View {
    let name: String
    let status: DishRenderStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .font(.system(size: 12, weight: status == .cooking ? .bold : .regular))
                .foregroundStyle(status.color)
                .frame(width: 14)

            Text(name)
                .font(.caption2)
                .fontWeight(status == .cooking ? .bold : .regular)
                .foregroundStyle(status == .cooking ? Color.white : Color.white.opacity(0.5))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Dynamic Island: Compact

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

    private var now: Date { Date() }

    private var currentDish: TimeCookAttributes.ContentState.DishStatus? {
        context.state.dishes
            .filter { $0.startTime <= now && now < $0.endTime }
            .min(by: { $0.startTime < $1.startTime })
    }

    private var nextDish: TimeCookAttributes.ContentState.DishStatus? {
        context.state.dishes
            .filter { $0.startTime > now }
            .min(by: { $0.startTime < $1.startTime })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let dish = currentDish {
                HStack(spacing: 8) {
                    DishProgressBar(dish: dish)
                    Text(dish.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let next = nextDish {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Lancez \(next.name) dans")
                        .font(.caption2)
                        .lineLimit(1)
                    TimerCountdownView(date: next.startTime)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15), in: Capsule())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lancez \(next.name) bientôt")
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

// MARK: - Color

private extension Color {
    static let tcBackground = Color(red: 0.10, green: 0.07, blue: 0.04)
}
