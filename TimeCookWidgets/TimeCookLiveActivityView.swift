import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct TimeCookLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeCookAttributes.self) { context in
            // ── Lock Screen / Banner ──────────────────────────
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded ──────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    Label("TimeCook", systemImage: "flame.fill")
                        .font(.caption).foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.targetEndTime, style: .timer)
                        .font(.headline).fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomView(context: context)
                }
            } compactLeading: {
                Image(systemName: "flame.fill").foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.targetEndTime, style: .timer)
                    .monospacedDigit()
                    .font(.caption2).fontWeight(.bold)
                    .foregroundColor(.orange)
                    .frame(width: 48)
            } minimal: {
                Image(systemName: "flame.fill").foregroundColor(.orange)
            }
            .widgetURL(URL(string: "timecook://session"))
        }
    }

    // MARK: - Lock Screen view

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<TimeCookAttributes>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label("TimeCook", systemImage: "flame.fill")
                    .font(.headline).foregroundColor(.orange)
                Spacer()
                Text(context.state.targetEndTime, style: .timer)
                    .font(.title2).fontWeight(.bold).monospacedDigit()
                    .foregroundColor(.orange)
            }

            // Progress bar (approximation via visual only)
            HStack(spacing: 6) {
                Image(systemName: "fork.knife").font(.caption).foregroundColor(.secondary)
                Text(context.state.sessionTitle)
                    .font(.caption).foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("Prêt à ")
                    .font(.caption).foregroundColor(.secondary)
                + Text(context.state.targetEndTime, style: .time)
                    .font(.caption).fontWeight(.semibold)
            }

            if let nextDish = context.state.nextDishName,
               let nextTime = context.state.nextDishStartTime {
                Divider()
                HStack {
                    Image(systemName: "bell.fill").foregroundColor(.orange).font(.caption)
                    Text("Lancez **\(nextDish)** dans")
                    Text(nextTime, style: .timer)
                        .fontWeight(.bold).monospacedDigit()
                    Spacer()
                }
                .font(.caption)
            }
        }
        .padding(16)
        .background(Color(.systemBackground).opacity(0.9))
        .activityBackgroundTint(Color(.systemBackground))
    }

    // MARK: - Dynamic Island expanded bottom

    @ViewBuilder
    private func expandedBottomView(context: ActivityViewContext<TimeCookAttributes>) -> some View {
        VStack(spacing: 4) {
            Text(context.state.sessionTitle)
                .font(.caption2).foregroundColor(.secondary)
                .lineLimit(1)

            if let nextDish = context.state.nextDishName,
               let nextTime = context.state.nextDishStartTime {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.orange).font(.caption2)
                    Text("Lancez \(nextDish) dans")
                        .font(.caption2)
                    Text(nextTime, style: .timer)
                        .font(.caption2).fontWeight(.bold).monospacedDigit()
                }
            }
        }
    }
}
