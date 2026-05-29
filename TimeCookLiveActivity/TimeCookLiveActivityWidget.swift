import ActivityKit
import WidgetKit
import SwiftUI
import TimeCookCore

@available(iOS 16.2, *)
struct TimeCookLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookingActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.orange.opacity(0.18))
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Time Cook", systemImage: "timer")
                        .font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                        .font(.caption.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(timerInterval: Date()...context.state.endsAt, countsDown: false)
                            .tint(.orange)
                        if let name = context.state.nextDishName, let date = context.state.nextDishStartAt, date > Date() {
                            Text("Prochain : \(name) à \(date, style: .time)")
                                .font(.caption)
                        } else {
                            Text("Tout est en cuisson")
                                .font(.caption)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
            }
        }
    }
}

@available(iOS 16.2, *)
private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CookingActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(context.attributes.title, systemImage: "fork.knife")
                    .font(.headline)
                Spacer()
                Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                    .font(.headline.monospacedDigit())
            }
            ProgressView(timerInterval: Date()...context.state.endsAt, countsDown: false)
                .tint(.orange)
            if let name = context.state.nextDishName, let date = context.state.nextDishStartAt, date > Date() {
                Text("Prochain ajout : \(name) à \(date, style: .time)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tous les plats sont lancés. Fin prévue à \(context.state.endsAt, style: .time).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
