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
// Spec: 408×84–160 pt (430-wide device). Content height = total − 32 (16 pt padding each side).

struct LockScreenActivityView: View {
    let context: ActivityViewContext<TimeCookAttributes>
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var now: Date { Date() }

    /// Earliest-started dish currently cooking → most elapsed progress fraction.
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

    // Always-On / StandBy: no animation, essential info only (spec §6)
    private var alwaysOnView: some View {
        HStack {
            Label("TimeCook", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Spacer()
            TimerCountdownView(date: context.state.targetEndTime)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .accessibilityLabel("TimeCook — cuisson en cours")
    }

    private var fullView: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: badge + dish name + progress
            VStack(alignment: .leading, spacing: 6) {
                statusBadge
                currentDishPanel
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: countdown + dish timeline
            VStack(alignment: .trailing, spacing: 6) {
                TimerCountdownView(date: context.state.targetEndTime)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Temps restant")
                dishTimelinePanel
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(16)
    }

    // "● EN COURS  ✦"
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(.orange).frame(width: 6, height: 6)
            Text("EN COURS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .tracking(0.5)
            Image(systemName: "rays")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.orange.opacity(0.18), in: Capsule())
    }

    // Dish name (large) + animated progress bar
    @ViewBuilder
    private var currentDishPanel: some View {
        if let dish = currentDish {
            VStack(alignment: .leading, spacing: 5) {
                Text(dish.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                // ProgressView(timerInterval:) self-animates in Live Activities — no app update needed.
                ProgressView(timerInterval: dish.startTime...dish.endTime, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(.orange)
            }
        } else {
            Label("Tous les plats prêts !", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
        }
    }

    // Vertical dish timeline aligned to the right
    @ViewBuilder
    private var dishTimelinePanel: some View {
        let dishes = context.state.dishes
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(dishes.enumerated()), id: \.element.id) { idx, dish in
                let status = renderStatus(of: dish)
                HStack(spacing: 4) {
                    Text(dish.name)
                        .font(.caption2)
                        .fontWeight(status == .cooking ? .semibold : .regular)
                        .foregroundStyle(status == .cooking ? Color.white : Color.white.opacity(0.45))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: status.iconName)
                        .font(.system(size: 11, weight: status == .cooking ? .bold : .regular))
                        .foregroundStyle(status.color)
                        .frame(width: 12)
                }
                if idx < dishes.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 5.5)
                }
            }
        }
    }

    private func renderStatus(of dish: TimeCookAttributes.ContentState.DishStatus) -> DishRenderStatus {
        if now >= dish.endTime { return .done }
        if now >= dish.startTime { return .cooking }
        return .waiting
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
        case .waiting: Color.white.opacity(0.4)
        }
    }
}

// MARK: - Dynamic Island: Compact
// Spec: 62.33×36.67 pt (430-wide) / 52.33×36.67 pt (393-wide). No manual padding.

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
// Spec: 36.67–45×36.67 pt. One meaningful symbol only.

struct MinimalView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 11))
            .foregroundStyle(.orange)
            .accessibilityLabel("TimeCook actif")
    }
}

// MARK: - Dynamic Island: Expanded
// Spec: 408×84–160 pt (430-wide). Leading/trailing: no manual horizontal padding (system provides concentric margins).

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
                    ProgressView(timerInterval: dish.startTime...dish.endTime, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                    .tint(.orange)

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

// MARK: - Previews (Xcode Canvas — all 4 presentation types)

private let previewAttributes = TimeCookAttributes(
    sessionTitle: "Steak · Frites · Œuf",
    totalDishes: 3
)

private func previewState(minutesRemaining: Double, dishesStarted: Int) -> TimeCookAttributes.ContentState {
    let end = Date().addingTimeInterval(minutesRemaining * 60)
    return TimeCookAttributes.ContentState(
        targetEndTime: end,
        dishes: [
            .init(id: UUID(), name: "Steak",
                  startTime: dishesStarted >= 1 ? Date().addingTimeInterval(-5 * 60) : end.addingTimeInterval(-10 * 60),
                  endTime: end),
            .init(id: UUID(), name: "Frites",
                  startTime: dishesStarted >= 2 ? Date().addingTimeInterval(-1 * 60) : end.addingTimeInterval(-5 * 60),
                  endTime: end),
            .init(id: UUID(), name: "Œuf à la coque",
                  startTime: dishesStarted >= 3 ? Date().addingTimeInterval(-0.5 * 60) : end.addingTimeInterval(-3 * 60),
                  endTime: end),
        ]
    )
}

#Preview("Lock Screen — 1 plat en cuisson", as: .content, using: previewAttributes) {
    TimeCookLiveActivity()
} contentStates: {
    previewState(minutesRemaining: 10, dishesStarted: 1)
    previewState(minutesRemaining: 5, dishesStarted: 2)
    previewState(minutesRemaining: 3, dishesStarted: 3)
}

#Preview("Compact", as: .dynamicIsland(.compact), using: previewAttributes) {
    TimeCookLiveActivity()
} contentStates: {
    previewState(minutesRemaining: 10, dishesStarted: 1)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: previewAttributes) {
    TimeCookLiveActivity()
} contentStates: {
    previewState(minutesRemaining: 10, dishesStarted: 1)
    previewState(minutesRemaining: 5, dishesStarted: 2)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: previewAttributes) {
    TimeCookLiveActivity()
} contentStates: {
    previewState(minutesRemaining: 10, dishesStarted: 1)
}
